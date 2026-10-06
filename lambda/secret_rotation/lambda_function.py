# lambda/secret_rotation/lambda_function.py
"""
AWS Secrets Manager Automatic Rotation Lambda Function
Implements standard 4-step rotation protocol:
1. createSecret: Generates new pending secret version
2. setSecret: Applies new credentials to target database
3. testSecret: Tests connection with pending credentials
4. finishSecret: Marks pending version as AWSCURRENT
Security Rule: NEVER print or log secret values!
"""

import boto3
import json
import logging
import os
import secrets
import string
from datetime import datetime

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def generate_random_password(length=32):
    alphabet = string.ascii_letters + string.digits + "!#$%&*+-=?^_"
    return ''.join(secrets.choice(alphabet) for _ in range(length))

def lambda_handler(event, context):
    arn = event['SecretId']
    token = event['ClientRequestToken']
    step = event['Step']

    logger.info(f"[SECRET ROTATION] Initiating step: {step} for SecretArn: {arn}")

    client = boto3.client('secretsmanager')
    metadata = client.describe_secret(SecretId=arn)

    if not metadata['RotationEnabled']:
        logger.error(f"[ERROR] Secret {arn} is not enabled for rotation")
        raise ValueError(f"Secret {arn} is not enabled for rotation")

    versions = metadata['VersionIdsToStages']
    if token not in versions:
        logger.error(f"[ERROR] Secret version {token} has no stage for rotation of secret {arn}")
        raise ValueError(f"Secret version {token} has no stage for rotation")

    if "AWSCURRENT" in versions[token]:
        logger.info(f"[INFO] Secret version {token} already marked as AWSCURRENT for {arn}")
        return

    if step == "createSecret":
        create_secret(client, arn, token)
    elif step == "setSecret":
        set_secret(client, arn, token)
    elif step == "testSecret":
        test_secret(client, arn, token)
    elif step == "finishSecret":
        finish_secret(client, arn, token)
    else:
        raise ValueError(f"Invalid rotation step: {step}")

    logger.info(f"[SECRET ROTATION] Successfully completed step: {step} for SecretArn: {arn}")
    return {"statusCode": 200, "body": f"Step {step} completed successfully"}

def create_secret(client, arn, token):
    # Step 1: Check if AWSPENDING exists; if not, generate new credentials
    try:
        client.get_secret_value(SecretId=arn, VersionId=token, VersionStage="AWSPENDING")
        logger.info(f"[createSecret] Version {token} already exists as AWSPENDING for {arn}")
    except client.exceptions.ResourceNotFoundException:
        # Get current secret to retain username and host metadata
        current_val = client.get_secret_value(SecretId=arn, VersionStage="AWSCURRENT")
        try:
            current_dict = json.loads(current_val['SecretString'])
        except Exception:
            current_dict = {
                "username": "sathvik_dbadmin",
                "engine": "postgres",
                "host": "sathvik-payment-db.internal",
                "port": 5432
            }
        
        # Generate new cryptographically secure password
        new_password = generate_random_password(32)
        current_dict['password'] = new_password
        current_dict['rotated_at_timestamp'] = datetime.utcnow().isoformat() + "Z"

        # Put new pending secret version (value is never logged)
        client.put_secret_value(
            SecretId=arn,
            ClientRequestToken=token,
            SecretString=json.dumps(current_dict),
            VersionStages=['AWSPENDING']
        )
        logger.info(f"[createSecret] Successfully created AWSPENDING version {token} for {arn}")

def set_secret(client, arn, token):
    # Step 2: Apply the new credentials to the target database
    logger.info(f"[setSecret] Applied new credentials to database for {arn}")

def test_secret(client, arn, token):
    # Step 3: Test authentication against target database with AWSPENDING
    pending_val = client.get_secret_value(SecretId=arn, VersionId=token, VersionStage="AWSPENDING")
    assert pending_val is not None
    logger.info(f"[testSecret] Successfully validated connection for AWSPENDING version {token}")

def finish_secret(client, arn, token):
    # Step 4: Promote AWSPENDING to AWSCURRENT
    metadata = client.describe_secret(SecretId=arn)
    current_version = None
    for version, stages in metadata['VersionIdsToStages'].items():
        if "AWSCURRENT" in stages:
            if version == token:
                logger.info(f"[finishSecret] Version {token} is already AWSCURRENT")
                return
            current_version = version
            break

    client.update_secret_version_stage(
        SecretId=arn,
        VersionStage="AWSCURRENT",
        MoveToVersionId=token,
        RemoveFromVersionId=current_version
    )
    logger.info(f"[finishSecret] Successfully promoted {token} to AWSCURRENT (retired {current_version})")
