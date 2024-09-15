
provider "aws" {
  region = var.aws_region
}

# Reuse an existing VPC instead of creating a new one
data "aws_vpc" "eks-vpc" {
  filter {
    name   = "tag:Name"
    values = ["your-existing-vpc-name"]  # Replace with your actual VPC name
  }
}

resource "aws_subnet" "eks_subnet" {
  count = 2
  vpc_id            = data.aws_vpc.existing_vpc.id
  cidr_block        = cidrsubnet(data.aws_vpc.existing_vpc.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "eks-subnet-${count.index}"
  }
}

resource "aws_eks_cluster" "karpenter_cluster" {
  name     = var.cluster_name
  role_arn = data.aws_iam_role.eks_cluster_role.arn
  vpc_config {
    subnet_ids = aws_subnet.eks_subnet[*].id
  }
}

resource "aws_eks_node_group" "karpenter_node_group" {
  cluster_name    = aws_eks_cluster.karpenter_cluster.name
  node_group_name = "karpenter-ng"
  node_role_arn   = data.aws_iam_role.eks_node_role.arn
  subnet_ids      = aws_subnet.eks_subnet[*].id
  scaling_config {
    desired_size = 3
    max_size     = 5
    min_size     = 1
  }
  instance_types = ["t3.medium"]
}

# Reuse existing IAM roles
data "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"  # Reuse existing role
}

data "aws_iam_role" "eks_node_role" {
  name = "eks-node-role"  # Reuse existing role
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = data.aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = data.aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = data.aws_iam_role.eks_cluster_role.name
}

data "aws_availability_zones" "available" {}

output "cluster_endpoint" {
  value = aws_eks_cluster.karpenter_cluster.endpoint
}
