# sathvik-devsecops/terraform/modules/vpc/outputs.tf

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_app_subnet_ids" {
  description = "IDs of the private application subnets"
  value       = aws_subnet.private_app[*].id
}

output "eks_worker_subnet_ids" {
  description = "IDs of the EKS worker subnets"
  value       = aws_subnet.eks_worker[*].id
}

output "firewall_subnet_ids" {
  description = "IDs of the firewall inspection subnets"
  value       = aws_subnet.firewall[*].id
}

output "nat_gateway_id" {
  description = "The ID of the NAT Gateway"
  value       = aws_nat_gateway.this.id
}

output "quarantine_sg_id" {
  description = "ID of the Quarantine Security Group"
  value       = aws_security_group.quarantine.id
}

output "workload_sg_id" {
  description = "ID of the Workload Security Group"
  value       = aws_security_group.workload.id
}
