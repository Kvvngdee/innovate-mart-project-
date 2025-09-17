# EKS Cluster Role
resource "aws_iam_role" "eks_cluster_role" {
  name = "innovatemart-eks-cluster-eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attachment_1" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attachment_2" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

# EKS Node Group Role
resource "aws_iam_role" "eks_nodegroup_role" {
  name = "innovatemart-eks-cluster-eks-nodegroup-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_nodegroup_policy_attachment_1" {
  role       = aws_iam_role.eks_nodegroup_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_nodegroup_policy_attachment_2" {
  role       = aws_iam_role.eks_nodegroup_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_nodegroup_policy_attachment_3" {
  role       = aws_iam_role.eks_nodegroup_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# IAM User and Policy
resource "aws_iam_user" "developer_user" {
  name = "innovatemart-dev-user-2" # Changed the name to fix the error
  tags = {
    Project = "Project Bedrock"
  }
}

resource "aws_iam_policy" "developer_read_only_policy" {
  name = "innovatemart-dev-read-only-policy"
  description = "Provides read-only access to EKS cluster resources for developers."
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = ["eks:DescribeCluster", "ssm:GetParameter"],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action   = "eks:ListClusters",
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action   = ["sts:AssumeRole", "sts:GetCallerIdentity"],
        Effect   = "Allow",
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_user_policy_attachment" "developer_policy_attachment" {
  user       = aws_iam_user.developer_user.name
  policy_arn = aws_iam_policy.developer_read_only_policy.arn
}
