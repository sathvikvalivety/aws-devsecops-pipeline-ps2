"""
scripts/teardown_final_cleanup.py
Cleans up remaining SSM patch group baseline, VPC security groups, and VPC.
"""
import time
import boto3

session = boto3.Session(profile_name='sathvik-dev', region_name='us-east-1')
ec2 = session.client('ec2')
ssm = session.client('ssm')

print("Starting final cleanup for SSM & VPC...")

# 1. Deregister SSM Patch Group & Delete Baseline
try:
    print("Deregistering patch group sathvik-production-nodes...")
    ssm.deregister_patch_baseline_for_patch_group(
        BaselineId='pb-0ff7e6df7ee92f06d',
        PatchGroup='sathvik-production-nodes'
    )
    print("Deleting patch baseline pb-0ff7e6df7ee92f06d...")
    ssm.delete_patch_baseline(BaselineId='pb-0ff7e6df7ee92f06d')
    print("[SUCCESS] SSM Patch Baseline deleted.")
except Exception as e:
    print(f"SSM cleanup error: {e}")

# 2. Check and delete ENIs in vpc-0eeb82d10ba282c2d
vpc_id = "vpc-0eeb82d10ba282c2d"
try:
    enis = ec2.describe_network_interfaces(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}])
    for eni in enis.get('NetworkInterfaces', []):
        eni_id = eni['NetworkInterfaceId']
        print(f"Found ENI: {eni_id} ({eni['Status']})")
        if eni['Status'] == 'available':
            try:
                ec2.delete_network_interface(NetworkInterfaceId=eni_id)
                print(f"[SUCCESS] Deleted ENI {eni_id}")
            except Exception as err:
                print(f"Could not delete ENI {eni_id}: {err}")
except Exception as e:
    print(f"ENI error: {e}")

# 3. Revoke rules and delete Security Group sg-0401849589b4d299e
try:
    sgs = ec2.describe_security_groups(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}])
    for sg in sgs.get('SecurityGroups', []):
        if sg['GroupName'] != 'default':
            sg_id = sg['GroupId']
            print(f"Revoking rules on SG: {sg_id}")
            if sg.get('IpPermissions'):
                ec2.revoke_security_group_ingress(GroupId=sg_id, IpPermissions=sg['IpPermissions'])
            if sg.get('IpPermissionsEgress'):
                ec2.revoke_security_group_egress(GroupId=sg_id, IpPermissions=sg['IpPermissionsEgress'])
            print(f"Deleting SG: {sg_id}")
            try:
                ec2.delete_security_group(GroupId=sg_id)
                print(f"[SUCCESS] Deleted SG {sg_id}")
            except Exception as err:
                print(f"Could not delete SG {sg_id}: {err}")
except Exception as e:
    print(f"SG cleanup error: {e}")

# 4. Delete remaining subnets if any
try:
    subs = ec2.describe_subnets(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}])
    for sub in subs.get('Subnets', []):
        sid = sub['SubnetId']
        print(f"Deleting Subnet: {sid}")
        try:
            ec2.delete_subnet(SubnetId=sid)
            print(f"[SUCCESS] Deleted Subnet {sid}")
        except Exception as err:
            print(f"Subnet error: {err}")
except Exception as e:
    print(f"Subnet check error: {e}")

# 5. Delete VPC
try:
    print(f"Deleting VPC: {vpc_id}")
    time.sleep(5)
    ec2.delete_vpc(VpcId=vpc_id)
    print(f"[SUCCESS] Deleted VPC {vpc_id}")
except Exception as err:
    print(f"[WARN] VPC deletion: {err}")

print("Final cleanup complete.")
