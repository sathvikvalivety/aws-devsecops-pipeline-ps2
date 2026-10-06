"""
scripts/teardown_inventory.py
Inventories all resources created for the project in AWS Account 009160054307 (us-east-1).
"""
import boto3

session = boto3.Session(profile_name='sathvik-dev', region_name='us-east-1')
print("=== ACTIVE INVENTORY IN ACCOUNT 009160054307 ===")

# EC2
ec2 = session.client('ec2')
insts = ec2.describe_instances(Filters=[{'Name': 'instance-state-name', 'Values': ['pending', 'running', 'stopping', 'stopped']}])
for r in insts['Reservations']:
    for i in r['Instances']:
        name = next((t['Value'] for t in i.get('Tags', []) if t['Key'] == 'Name'), i['InstanceId'])
        print(f"EC2 Instance: {i['InstanceId']} ({name}) - State: {i['State']['Name']}")

# API Gateway v2
apigw = session.client('apigatewayv2')
apis = apigw.get_apis()
for a in apis.get('Items', []):
    if 'sathvik' in a['Name']:
        print(f"API Gateway: {a['ApiId']} ({a['Name']})")

# Lambda
lam = session.client('lambda')
funcs = lam.list_functions()
for f in funcs.get('Functions', []):
    if 'sathvik' in f['FunctionName']:
        print(f"Lambda: {f['FunctionName']}")

# EventBridge
eb = session.client('events')
rules = eb.list_rules()
for r in rules.get('Rules', []):
    if 'sathvik' in r['Name']:
        print(f"EventBridge Rule: {r['Name']}")

# S3
s3 = session.client('s3')
buckets = s3.list_buckets()
for b in buckets.get('Buckets', []):
    if 'sathvik' in b['Name']:
        print(f"S3 Bucket: {b['Name']}")

# Secrets Manager
sm = session.client('secretsmanager')
sec = sm.list_secrets()
for s in sec.get('SecretList', []):
    if 'sathvik' in s['Name']:
        print(f"Secrets Manager: {s['Name']}")

# ECR
ecr = session.client('ecr')
try:
    repos = ecr.describe_repositories()
    for r in repos.get('repositories', []):
        if 'sathvik' in r['repositoryName']:
            print(f"ECR Repository: {r['repositoryName']}")
except Exception as e:
    print("ECR check error:", e)

# CodePipeline
cp = session.client('codepipeline')
try:
    pipelines = cp.list_pipelines()
    for p in pipelines.get('pipelines', []):
        if 'sathvik' in p['name']:
            print(f"CodePipeline: {p['name']}")
except Exception as e:
    print("CodePipeline error:", e)

# CodeBuild
cb = session.client('codebuild')
try:
    builds = cb.list_projects()
    for b in builds.get('projects', []):
        if 'sathvik' in b:
            print(f"CodeBuild: {b}")
except Exception as e:
    print("CodeBuild error:", e)

# Systems Manager Patch Baseline
ssm = session.client('ssm')
try:
    baselines = ssm.describe_patch_baselines()
    for b in baselines.get('BaselineIdentities', []):
        if 'sathvik' in b['BaselineName']:
            print(f"SSM Patch Baseline: {b['BaselineId']} ({b['BaselineName']})")
except Exception as e:
    print("SSM error:", e)

# VPC
vpcs = ec2.describe_vpcs(Filters=[{'Name': 'tag:Name', 'Values': ['*sathvik*']}])
for v in vpcs.get('Vpcs', []):
    name = next((t['Value'] for t in v.get('Tags', []) if t['Key'] == 'Name'), v['VpcId'])
    print(f"VPC: {v['VpcId']} ({name})")
