# demos/10-vpc-segmentation.ps1
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " DEMO 10: MULTI-TIER VPC ISOLATION & SECURITY BOUNDARIES     " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
aws ec2 describe-vpcs --filters Name=tag:Name,Values=sathvik_vpc --region us-east-1 --profile sathvik-dev
aws ec2 describe-subnets --filters Name=tag:Project,Values=sathvik-devsecops --query "Subnets[*].[SubnetId,CidrBlock,AvailabilityZone,Tags[?Key=='Name'].Value|[0]]" --output table --region us-east-1 --profile sathvik-dev
aws ec2 describe-security-groups --filters Name=tag:Project,Values=sathvik-devsecops --query "SecurityGroups[*].[GroupId,GroupName,Description]" --output table --region us-east-1 --profile sathvik-dev
