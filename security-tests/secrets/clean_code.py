# security-tests/secrets/clean_code.py
# REMEDIATED CODE: SECURE RUNTIME RETRIEVAL FROM AWS SECRETS MANAGER
# ZERO HARDCODED CREDENTIALS OR TOKENS

import os
import json
import boto3

def get_database_credentials(secret_name="sathvik_payment_db_credentials", region_name="us-east-1"): # pragma: allowlist secret
    """
    Retrieves database credentials securely at runtime from AWS Secrets Manager.
    No credentials, passwords, or tokens are embedded in code or configuration.
    """
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )
    
    response = client.get_secret_value(SecretId=secret_name)
    if 'SecretString' in response:
        secret_data = json.loads(response['SecretString'])
        return secret_data
    return None

if __name__ == "__main__":
    print("[INFO] Production-ready runtime secrets retrieval initialized.")
