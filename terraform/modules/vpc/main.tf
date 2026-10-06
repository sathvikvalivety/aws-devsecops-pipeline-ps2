# sathvik-devsecops/terraform/modules/vpc/main.tf

# 1. Dedicated VPC
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "${var.project_prefix}_vpc"
    Purpose = "Dedicated Isolated VPC for Fintech Workloads"
  }
}

# 2. Internet Gateway
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name    = "${var.project_prefix}_igw"
    Purpose = "Public Ingress/Egress Gateway"
  }
}

# 3. Public Subnets (2 AZs)
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name                     = "${var.project_prefix}_public_subnet_${count.index + 1}"
    Type                     = "Public"
    "kubernetes.io/role/elb" = "1"
  }
}

# 4. Private Application Subnets (2 AZs)
resource "aws_subnet" "private_app" {
  count             = length(var.private_app_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_app_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name    = "${var.project_prefix}_private_app_subnet_${count.index + 1}"
    Type    = "PrivateApp"
    Purpose = "Backend Application Microservices"
  }
}

# 5. EKS Private Worker Subnets (2 AZs)
resource "aws_subnet" "eks_worker" {
  count             = length(var.eks_worker_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.eks_worker_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name                              = "${var.project_prefix}_eks_worker_subnet_${count.index + 1}"
    Type                              = "PrivateEKS"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# 6. Network Firewall Inspection Subnets (2 AZs)
resource "aws_subnet" "firewall" {
  count             = length(var.firewall_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.firewall_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name    = "${var.project_prefix}_firewall_subnet_${count.index + 1}"
    Type    = "Inspection"
    Purpose = "Perimeter Firewall Endpoints"
  }
}

# 7. Elastic IP & Single NAT Gateway (Cost Optimized)
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.project_prefix}_nat_eip"
  }
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.project_prefix}_nat_gw"
  }

  depends_on = [aws_internet_gateway.this]
}

# 8. Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.project_prefix}_public_rt"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name = "${var.project_prefix}_private_rt"
  }
}

# 9. Route Table Associations
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_app" {
  count          = length(aws_subnet.private_app)
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "eks_worker" {
  count          = length(aws_subnet.eks_worker)
  subnet_id      = aws_subnet.eks_worker[count.index].id
  route_table_id = aws_route_table.private.id
}

# 10. Quarantine Security Group (Phase 4 requirement)
# Blocks all inbound application traffic, allows ONLY outbound HTTPS (443) for SSM and management
resource "aws_security_group" "quarantine" {
  name        = "${var.project_prefix}_quarantine_sg"
  description = "Quarantine Security Group: Isolate compromised workloads while retaining SSM management"
  vpc_id      = aws_vpc.this.id

  # Deny all inbound by having NO ingress rules
  ingress = []

  # Controlled egress for SSM agent to reach AWS endpoints
  egress {
    description = "Allow outbound HTTPS for AWS Systems Manager agent connectivity"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_prefix}_quarantine_sg"
    Purpose = "Incident Response Isolation"
  }
}

# 11. Workload Security Group for EKS / Microservices
resource "aws_security_group" "workload" {
  name        = "${var.project_prefix}_workload_sg"
  description = "Security group for private container microservice workloads"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "Allow inbound HTTP within VPC"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow outbound HTTPS for dependencies and AWS APIs"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_prefix}_workload_sg"
    Purpose = "Workload Network Security Boundary"
  }
}

# 12. VPC Flow Logs
resource "aws_flow_log" "this" {
  vpc_id                   = aws_vpc.this.id
  traffic_type             = "ALL"
  log_destination_type     = "cloud-watch-logs"
  log_destination          = var.flow_log_destination_arn
  iam_role_arn             = var.flow_log_iam_role_arn
  max_aggregation_interval = 60

  tags = {
    Name    = "${var.project_prefix}_vpc_flow_logs"
    Purpose = "Network Traffic Auditing & Threat Detection"
  }
}
