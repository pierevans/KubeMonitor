# ==========================================
# 1. FRONTEND ECR REPOSITORY
# ==========================================

resource "aws_ecr_repository" "web" {

  name = "kube-monitor-web-ecr-repo"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "kube-monitor"
  }
}

# ==========================================
# 2. BACKEND ECR REPOSITORY
# ==========================================

resource "aws_ecr_repository" "api" {

  name = "kube-monitor-api-ecr-repo"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "kube-monitor-api-ecr-repo"
  }
}


# Push images to these ECR repositories, you can use the following commands:

# Step 1: Verify your ECR repositories

/*

aws ecr describe-repositories \
  --query 'repositories[*].[repositoryName,repositoryUri]' \
  --output table

Replace image in the compose.yaml with the ECR repository URI if using Docker Compose.
Example:
image: <ECR_REPOSITORY_URI>:latest
*/


# Step 2: Authenticate Docker with ECR


/*
To avoid manually entering your AWS account ID, run:
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region)


Authenticate Docker with ECR

aws ecr get-login-password --region "$AWS_REGION" | \
docker login --username AWS --password-stdin \
"$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

*/

# Step 3: Push images to ECR

/*

if not using compose.yaml for each ECR repository and image:

docker build -t <image_name> .

docker tag <image_name>:latest \
"$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/<ecr_repository_name>:latest"
docker push "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/<ecr_repository_name>:latest"

if you are using Docker Compose, you can skip the manual tagging and pushing steps.:
docker compose build
docker compose push

Important: Both ECR repositories must already exist in AWS.
*/

