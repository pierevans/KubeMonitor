# Create:
# - kubmonitor-cluster
# - Managed node group
# - Desired nodes: 2
# - Minimum nodes: 2
# - Maximum nodes: 2
# - Nodes located in the two private subnets

# ==========================================
# 1. AMAZON EKS CLUSTER
# ==========================================

resource "aws_eks_cluster" "main" {
  count = local.enable_eks ? 1 : 0

  # IAM role for EKS cluster permissions
  name = "kubemonitor-eks"
  role_arn = aws_iam_role.eks_cluster[0].arn

  # Use private VPC subnets
  vpc_config {
    subnet_ids = aws_subnet.private[*].id
  }

  # Wait for IAM policy attachment
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]

  tags = {
    Name = "kubemonitor-eks"
  }
}

# ==========================================
# 2. EKS MANAGED NODE GROUP
# ==========================================

resource "aws_eks_node_group" "main" {
  count = local.enable_eks ? 1 : 0

  cluster_name = aws_eks_cluster.main[0].name
  node_group_name = "kubemonitor-workers"
  node_role_arn = aws_iam_role.eks_nodes[0].arn

  # Deploy nodes into both private subnets
  subnet_ids = aws_subnet.private[*].id

  # EC2 instance configuration
  instance_types = ["t3.medium"]
  capacity_type = "ON_DEMAND"

  # Worker node scaling configuration
  scaling_config {
    desired_size = 2
    min_size = 2
    max_size = 2
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_policy,
    aws_iam_role_policy_attachment.eks_ecr_policy,
    aws_iam_role_policy_attachment.eks_cni_policy
  ]

  tags = {
    Name = "kubemonitor-workers"
  }
}
