"""
scripts/teardown_all_resources.py
Safely terminates and deletes all AWS cloud resources deployed for the DevSecOps project
in AWS Account 009160054307 (Region: us-east-1).

Order of deletion:
1. EC2 instances
2. API Gateway v2
3. EventBridge rules & targets
4. Lambda functions
5. CodePipeline & CodeBuild
6. ECR repositories
7. Secrets Manager secrets
8. S3 buckets (versioned & unversioned objects purged)
9. Systems Manager Patch Baselines
10. CloudWatch Log Groups
11. VPC resources (Flow logs, NAT gateways, EIPs, endpoints, IGW, SGs, subnets, route tables, VPC)
12. IAM roles & instance profiles
13. KMS Key (disabled & scheduled for deletion)
"""
import time
import boto3

PROFILE = "sathvik-dev"
REGION = "us-east-1"

session = boto3.Session(profile_name=PROFILE, region_name=REGION)
ec2 = session.client("ec2")
s3 = session.client("s3")
lam = session.client("lambda")
apigw = session.client("apigatewayv2")
eb = session.client("events")
sm = session.client("secretsmanager")
ecr = session.client("ecr")
cp = session.client("codepipeline")
cb = session.client("codebuild")
ssm = session.client("ssm")
logs = session.client("logs")
iam = session.client("iam")
kms = session.client("kms")

print(f"============================================================")
print(f"STARTING COMPREHENSIVE AWS TEARDOWN (Account: 009160054307)")
print(f"============================================================")

# 1. EC2 INSTANCES
print("\n[1/13] Terminating EC2 Workload Instances...")
try:
    insts = ec2.describe_instances(
        Filters=[
            {'Name': 'tag:Name', 'Values': ['*sathvik*']},
            {'Name': 'instance-state-name', 'Values': ['pending', 'running', 'stopping', 'stopped']}
        ]
    )
    instance_ids = []
    for r in insts.get('Reservations', []):
        for i in r.get('Instances', []):
            instance_ids.append(i['InstanceId'])
    
    if instance_ids:
        print(f"Terminating instances: {instance_ids}")
        ec2.terminate_instances(InstanceIds=instance_ids)
        print("Waiting for EC2 instances to terminate...")
        waiter = ec2.get_waiter('instance_terminated')
        waiter.wait(InstanceIds=instance_ids)
        print("[SUCCESS] All EC2 instances terminated.")
    else:
        print("No active EC2 instances found.")
except Exception as e:
    print(f"[WARN] EC2 error: {e}")

# 2. API GATEWAY
print("\n[2/13] Deleting API Gateway...")
try:
    apis = apigw.get_apis()
    for a in apis.get('Items', []):
        if 'sathvik' in a.get('Name', ''):
            api_id = a['ApiId']
            print(f"Deleting API Gateway: {api_id} ({a['Name']})")
            apigw.delete_api(ApiId=api_id)
            print(f"[SUCCESS] Deleted API Gateway {api_id}")
except Exception as e:
    print(f"[WARN] API Gateway error: {e}")

# 3. EVENTBRIDGE RULES
print("\n[3/13] Deleting EventBridge Rules...")
try:
    rules = eb.list_rules()
    for r in rules.get('Rules', []):
        if 'sathvik' in r['Name']:
            rule_name = r['Name']
            print(f"Processing EventBridge rule: {rule_name}")
            targets = eb.list_targets_by_rule(Rule=rule_name)
            target_ids = [t['Id'] for t in targets.get('Targets', [])]
            if target_ids:
                print(f"Removing targets: {target_ids}")
                eb.remove_targets(Rule=rule_name, Ids=target_ids)
            eb.delete_rule(Name=rule_name)
            print(f"[SUCCESS] Deleted EventBridge rule {rule_name}")
except Exception as e:
    print(f"[WARN] EventBridge error: {e}")

# 4. LAMBDA FUNCTIONS
print("\n[4/13] Deleting Lambda Functions...")
try:
    funcs = lam.list_functions()
    for f in funcs.get('Functions', []):
        fn_name = f['FunctionName']
        if 'sathvik' in fn_name:
            print(f"Deleting Lambda function: {fn_name}")
            lam.delete_function(FunctionName=fn_name)
            print(f"[SUCCESS] Deleted Lambda {fn_name}")
except Exception as e:
    print(f"[WARN] Lambda error: {e}")

# 5. CODEPIPELINE & CODEBUILD
print("\n[5/13] Deleting CodePipeline & CodeBuild...")
try:
    pipelines = cp.list_pipelines()
    for p in pipelines.get('pipelines', []):
        if 'sathvik' in p['name']:
            pname = p['name']
            print(f"Deleting CodePipeline: {pname}")
            cp.delete_pipeline(name=pname)
            print(f"[SUCCESS] Deleted CodePipeline {pname}")
except Exception as e:
    print(f"[WARN] CodePipeline error: {e}")

try:
    projects = cb.list_projects()
    for proj in projects.get('projects', []):
        if 'sathvik' in proj:
            print(f"Deleting CodeBuild project: {proj}")
            cb.delete_project(name=proj)
            print(f"[SUCCESS] Deleted CodeBuild {proj}")
except Exception as e:
    print(f"[WARN] CodeBuild error: {e}")

# 6. ECR REPOSITORIES
print("\n[6/13] Deleting ECR Repositories...")
try:
    repos = ecr.describe_repositories()
    for r in repos.get('repositories', []):
        rname = r['repositoryName']
        if 'sathvik' in rname:
            print(f"Deleting ECR repository: {rname}")
            ecr.delete_repository(repositoryName=rname, force=True)
            print(f"[SUCCESS] Deleted ECR repository {rname}")
except Exception as e:
    print(f"[WARN] ECR error: {e}")

# 7. SECRETS MANAGER
print("\n[7/13] Deleting Secrets Manager Secrets...")
try:
    sec = sm.list_secrets()
    for s in sec.get('SecretList', []):
        sname = s['Name']
        if 'sathvik' in sname:
            print(f"Force-deleting Secret: {sname}")
            sm.delete_secret(SecretId=sname, ForceDeleteWithoutRecovery=True)
            print(f"[SUCCESS] Deleted secret {sname}")
except Exception as e:
    print(f"[WARN] Secrets Manager error: {e}")

# 8. S3 BUCKETS
print("\n[8/13] Purging and Deleting S3 Buckets...")
try:
    buckets = s3.list_buckets()
    for b in buckets.get('Buckets', []):
        bname = b['Name']
        if 'sathvik' in bname:
            print(f"Purging S3 bucket: {bname}")
            # Purge versioned and unversioned objects
            s3_res = session.resource('s3')
            bucket = s3_res.Bucket(bname)
            try:
                bucket.object_versions.delete()
            except Exception as e:
                pass
            try:
                bucket.objects.all().delete()
            except Exception as e:
                pass
            s3.delete_bucket(Bucket=bname)
            print(f"[SUCCESS] Deleted bucket {bname}")
except Exception as e:
    print(f"[WARN] S3 bucket error: {e}")

# 9. SSM PATCH BASELINE
print("\n[9/13] Deleting SSM Patch Baselines...")
try:
    baselines = ssm.describe_patch_baselines()
    for b in baselines.get('BaselineIdentities', []):
        if 'sathvik' in b.get('BaselineName', ''):
            bid = b['BaselineId']
            print(f"Deleting SSM Patch Baseline: {bid} ({b['BaselineName']})")
            ssm.delete_patch_baseline(BaselineId=bid)
            print(f"[SUCCESS] Deleted Patch Baseline {bid}")
except Exception as e:
    print(f"[WARN] SSM error: {e}")

# 10. CLOUDWATCH LOG GROUPS
print("\n[10/13] Deleting CloudWatch Log Groups...")
try:
    lgs = logs.describe_log_groups(logGroupNamePrefix='/aws/')
    for lg in lgs.get('logGroups', []):
        lg_name = lg['logGroupName']
        if 'sathvik' in lg_name:
            print(f"Deleting Log Group: {lg_name}")
            logs.delete_log_group(logGroupName=lg_name)
            print(f"[SUCCESS] Deleted Log Group {lg_name}")
except Exception as e:
    print(f"[WARN] CloudWatch Logs error: {e}")

# 11. VPC INFRASTRUCTURE
print("\n[11/13] Deleting VPC Infrastructure (sathvik_vpc)...")
try:
    vpcs = ec2.describe_vpcs(Filters=[{'Name': 'tag:Name', 'Values': ['*sathvik*']}])
    for v in vpcs.get('Vpcs', []):
        vpc_id = v['VpcId']
        print(f"Tearing down VPC: {vpc_id}")

        # Delete VPC Flow Logs
        try:
            fls = ec2.describe_flow_logs(Filters=[{'Name': 'resource-id', 'Values': [vpc_id]}])
            fl_ids = [fl['FlowLogId'] for fl in fls.get('FlowLogs', [])]
            if fl_ids:
                print(f"Deleting Flow Logs: {fl_ids}")
                ec2.delete_flow_logs(FlowLogIds=fl_ids)
        except Exception as e:
            print(f"Flow log error: {e}")

        # NAT Gateways
        try:
            nats = ec2.describe_nat_gateways(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}, {'Name': 'state', 'Values': ['available']}])
            nat_ids = [n['NatGatewayId'] for n in nats.get('NatGateways', [])]
            for nat_id in nat_ids:
                print(f"Deleting NAT Gateway: {nat_id}")
                ec2.delete_nat_gateway(NatGatewayId=nat_id)
            if nat_ids:
                print("Waiting for NAT Gateways to delete...")
                time.sleep(30)
        except Exception as e:
            print(f"NAT error: {e}")

        # Release EIPs associated with sathvik
        try:
            eips = ec2.describe_addresses(Filters=[{'Name': 'tag:Name', 'Values': ['*sathvik*']}])
            for a in eips.get('Addresses', []):
                alloc_id = a.get('AllocationId')
                if alloc_id:
                    print(f"Releasing Elastic IP: {alloc_id} ({a.get('PublicIp')})")
                    ec2.release_address(AllocationId=alloc_id)
        except Exception as e:
            print(f"EIP error: {e}")

        # Internet Gateways
        try:
            igws = ec2.describe_internet_gateways(Filters=[{'Name': 'attachment.vpc-id', 'Values': [vpc_id]}])
            for igw in igws.get('InternetGateways', []):
                igw_id = igw['InternetGatewayId']
                print(f"Detaching and deleting Internet Gateway: {igw_id}")
                ec2.detach_internet_gateway(InternetGatewayId=igw_id, VpcId=vpc_id)
                ec2.delete_internet_gateway(InternetGatewayId=igw_id)
        except Exception as e:
            print(f"IGW error: {e}")

        # Endpoints
        try:
            eps = ec2.describe_vpc_endpoints(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}])
            ep_ids = [ep['VpcEndpointId'] for ep in eps.get('VpcEndpoints', [])]
            if ep_ids:
                print(f"Deleting VPC Endpoints: {ep_ids}")
                ec2.delete_vpc_endpoints(VpcEndpointIds=ep_ids)
        except Exception as e:
            print(f"Endpoint error: {e}")

        # Security Groups
        try:
            sgs = ec2.describe_security_groups(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}])
            for sg in sgs.get('SecurityGroups', []):
                if sg['GroupName'] != 'default':
                    sg_id = sg['GroupId']
                    print(f"Deleting Security Group: {sg_id} ({sg['GroupName']})")
                    try:
                        ec2.delete_security_group(GroupId=sg_id)
                    except Exception as err:
                        print(f"Could not delete SG {sg_id} yet: {err}")
        except Exception as e:
            print(f"SG error: {e}")

        # Subnets
        try:
            subs = ec2.describe_subnets(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}])
            for sub in subs.get('Subnets', []):
                sub_id = sub['SubnetId']
                print(f"Deleting Subnet: {sub_id}")
                try:
                    ec2.delete_subnet(SubnetId=sub_id)
                except Exception as err:
                    print(f"Subnet delete error: {err}")
        except Exception as e:
            print(f"Subnets error: {e}")

        # Route Tables
        try:
            rts = ec2.describe_route_tables(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}])
            for rt in rts.get('RouteTables', []):
                is_main = any(assoc.get('Main', False) for assoc in rt.get('Associations', []))
                if not is_main:
                    rt_id = rt['RouteTableId']
                    print(f"Deleting Route Table: {rt_id}")
                    try:
                        ec2.delete_route_table(RouteTableId=rt_id)
                    except Exception as err:
                        print(f"Route table delete error: {err}")
        except Exception as e:
            print(f"Route table error: {e}")

        # Delete VPC
        print(f"Deleting VPC: {vpc_id}")
        time.sleep(5)
        try:
            ec2.delete_vpc(VpcId=vpc_id)
            print(f"[SUCCESS] Deleted VPC {vpc_id}")
        except Exception as err:
            print(f"[WARN] Could not delete VPC yet (will retry): {err}")
except Exception as e:
    print(f"[WARN] VPC teardown error: {e}")

# 12. IAM ROLES & INSTANCE PROFILES
print("\n[12/13] Deleting IAM Roles & Instance Profiles...")
try:
    # Instance profile
    try:
        ip_name = "sathvik_ec2_instance_profile"
        print(f"Removing roles from instance profile: {ip_name}")
        ip_desc = iam.get_instance_profile(InstanceProfileName=ip_name)
        for r in ip_desc.get('InstanceProfile', {}).get('Roles', []):
            iam.remove_role_from_instance_profile(InstanceProfileName=ip_name, RoleName=r['RoleName'])
        iam.delete_instance_profile(InstanceProfileName=ip_name)
        print(f"[SUCCESS] Deleted instance profile {ip_name}")
    except Exception as e:
        pass

    roles = iam.list_roles()
    for r in roles.get('Roles', []):
        rname = r['RoleName']
        if 'sathvik' in rname:
            print(f"Cleaning IAM role: {rname}")
            # Detach managed policies
            attached = iam.list_attached_role_policies(RoleName=rname)
            for p in attached.get('AttachedPolicies', []):
                iam.detach_role_policy(RoleName=rname, PolicyArn=p['PolicyArn'])
            # Delete inline policies
            inline = iam.list_role_policies(RoleName=rname)
            for pol in inline.get('PolicyNames', []):
                iam.delete_role_policy(RoleName=rname, PolicyName=pol)
            # Delete role
            iam.delete_role(RoleName=rname)
            print(f"[SUCCESS] Deleted IAM role {rname}")
except Exception as e:
    print(f"[WARN] IAM error: {e}")

# 13. KMS KEY
print("\n[13/13] Scheduling KMS Key Deletion...")
try:
    aliases = kms.list_aliases()
    for a in aliases.get('Aliases', []):
        if 'sathvik' in a.get('AliasName', ''):
            key_id = a.get('TargetKeyId')
            if key_id:
                print(f"Disabling and scheduling deletion for KMS Key: {key_id} ({a['AliasName']})")
                try:
                    kms.disable_key(KeyId=key_id)
                except Exception as e:
                    pass
                kms.schedule_key_deletion(KeyId=key_id, PendingWindowInDays=7)
                print(f"[SUCCESS] KMS Key {key_id} scheduled for deletion (7 days).")
except Exception as e:
    print(f"[WARN] KMS error: {e}")

print(f"\n============================================================")
print(f"TEARDOWN EXECUTION COMPLETED")
print(f"============================================================")
