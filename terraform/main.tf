# main.tf: Core AWS Infrastructure for EKS Cluster

# --- Provider Configuration ---
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# --- VPC and Networking ---
resource "aws_vpc" "innovatemart_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "${var.cluster_name}-vpc"
  }
}

# Public Subnets (for Load Balancers)
resource "aws_subnet" "public_subnets" {
  count = 2
  vpc_id = aws_vpc.innovatemart_vpc.id
  cidr_block = "10.0.${10 + count.index}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.cluster_name}-public-subnet-${count.index}"
    "kubernetes.io/role/elb" = "1" # Required for ALB Ingress Controller
  }
}

# Private Subnets (for EKS Nodes)
resource "aws_subnet" "private_subnets" {
  count = 2
  vpc_id = aws_vpc.innovatemart_vpc.id
  cidr_block = "10.0.${20 + count.index}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.cluster_name}-private-subnet-${count.index}"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

data "aws_availability_zones" "available" {}

# Internet Gateway for public subnets
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.innovatemart_vpc.id
  tags = {
    Name = "${var.cluster_name}-igw"
  }
}

# Route table for public subnets
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.innovatemart_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_rt_assoc" {
  count = 2
  subnet_id = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# Create an EIP for the NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = {
    Name = "${var.cluster_name}-nat-eip"
  }
}

# Create a NAT Gateway in the public subnet
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnets[0].id
  tags = {
    Name = "${var.cluster_name}-nat-gw"
  }
}

# Create a Private Route Table for the private subnets
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.innovatemart_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }
  tags = {
    Name = "${var.cluster_name}-private-rt"
  }
}

# Associate private subnets with the private route table
resource "aws_route_table_association" "private_rt_assoc" {
  count          = 2
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_rt.id
}

# --- EKS Cluster ---
resource "aws_eks_cluster" "innovatemart_eks" {
  name = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  vpc_config {
    subnet_ids = concat(aws_subnet.public_subnets[*].id, aws_subnet.private_subnets[*].id)
    public_access_cidrs = ["0.0.0.0/0"]
  }
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy_attachment_1,
    aws_iam_role_policy_attachment.eks_cluster_policy_attachment_2,
  ]
}

# Tag the private subnets after the cluster is created to break the cycle
resource "aws_ec2_tag" "private_subnet_tags" {
  count       = length(aws_subnet.private_subnets)
  resource_id = aws_subnet.private_subnets[count.index].id
  key         = "kubernetes.io/cluster/${var.cluster_name}"
  value       = "owned"
  depends_on = [aws_eks_cluster.innovatemart_eks]
}

# --- EKS Managed Node Group ---
resource "aws_eks_node_group" "innovatemart_node_group" {
  cluster_name    = aws_eks_cluster.innovatemart_eks.name
  node_group_name = "innovatemart-nodegroup"
  node_role_arn   = aws_iam_role.eks_nodegroup_role.arn
  subnet_ids      = aws_subnet.private_subnets[*].id
  instance_types  = ["t3.medium"]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_nodegroup_policy_attachment_1,
    aws_iam_role_policy_attachment.eks_nodegroup_policy_attachment_2,
    aws_iam_role_policy_attachment.eks_nodegroup_policy_attachment_3,
    aws_ec2_tag.private_subnet_tags,
  ]
}
