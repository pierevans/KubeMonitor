
# ==========================================
# 1. EKS CLUSTER IAM ROLE
# ==========================================

resource "aws_iam_role" "eks_cluster" {
  count = local.enable_eks ? 1 : 0

  name = "kubemonitor-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach AWS-managed EKS Cluster Policy
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  count = local.enable_eks ? 1 : 0

  role = aws_iam_role.eks_cluster[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# ==========================================
# 2. EKS WORKER NODE IAM ROLE
# ==========================================

resource "aws_iam_role" "eks_nodes" {
  count = local.enable_eks ? 1 : 0

  name = "kubemonitor-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Allow worker nodes to communicate with EKS
resource "aws_iam_role_policy_attachment" "eks_worker_policy" {
  count = local.enable_eks ? 1 : 0

  role = aws_iam_role.eks_nodes[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# Allow worker nodes to pull Docker images from ECR
resource "aws_iam_role_policy_attachment" "eks_ecr_policy" {
  count = local.enable_eks ? 1 : 0

  role = aws_iam_role.eks_nodes[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
}

# Temporary simplified networking permissions for VPC CNI.
# Later, move these permissions to a dedicated VPC CNI role.
resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  count = local.enable_eks ? 1 : 0

  role = aws_iam_role.eks_nodes[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}