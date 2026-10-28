# Create Amazon EKS Cluster

resource "aws_eks_cluster" "kube-monitor-eks" {

  name = "kube-monitor-eks"
  # IAM role for EKS cluster permissions
  role_arn = aws_iam_role.cluster_role.arn

  # Use private VPC subnets
  vpc_config {
    subnet_ids = [
      aws_subnet.private_sub_1.id,
      aws_subnet.private_sub_2.id
    ]
  }

  version = "1.37"
  # Wait for IAM policy attachment
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]

  tags = {
    Name = "kube-monitor-eks"
  }
}


resource "aws_iam_role" "cluster_role" {
  name = "kube-monitor-cluster-role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : [
            "eks.amazonaws.com"
          ]
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# EKS Managed Node Group

resource "aws_eks_node_group" "kube-monitor-workers" {

  cluster_name    = aws_eks_cluster.kube-monitor-eks.name
  node_group_name = "kube-monitor-workers"
  node_role_arn   = aws_iam_role.eks_nodes_role.arn

  # Deploy nodes into both private subnets
  subnet_ids =  [
      aws_subnet.private_sub_1.id,
      aws_subnet.private_sub_2.id
    ]

  # EC2 instance configuration
  instance_types = ["t3.small"]
  capacity_type  = "ON_DEMAND"

  # Worker node scaling configuration
  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
      aws_iam_role_policy_attachment.eks_worker_node_policy,
      aws_iam_role_policy_attachment.eks_ecr_policy,
      aws_iam_role_policy_attachment.eks_cni_policy,
      aws_route_table_association.private_1,
      aws_route_table_association.private_2
  ]

  tags = {
    Name = "kube-monitor-workers"
  }
}

resource "aws_iam_role" "eks_nodes_role" {
  name = "kube-monitor-eks-nodes-role"

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

# Worker nodes communicate with EKS and EC2
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_nodes_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}


# Worker nodes pull images from Amazon ECR
resource "aws_iam_role_policy_attachment" "eks_ecr_policy" {
  role       = aws_iam_role.eks_nodes_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
}


# VPC CNI manages Pod networking
resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_nodes_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}


resource "aws_eks_addon" "metrics_server" {
  cluster_name = aws_eks_cluster.kube-monitor-eks.name
  addon_name   = "metrics-server"

  depends_on = [
    aws_eks_node_group.kube-monitor-workers
  ]

  tags = {
    Name = "kube-monitor-metrics-server"
  }
}

/*

# Update kubeconfig for the EKS cluster
aws eks update-kubeconfig \
  --region us-east-1 \
  --name kube-monitor-eks

# Apply Kubernetes manifests to the EKS cluster
  kubectl apply -f kubernetes/


# Install the AWS Load Balancer Controller

  Step 1 — Download the controller IAM policy
  curl -o iam_policy.json \
https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v3.6.2/docs/install/iam_policy.json

Step 2 — Configure Helm in providers.tf
Step 3 — Add the controller IAM resources in controller.tf
Step 4 — Create the Kubernetes ServiceAccount
Step 5 — Install the Helm release
*/


