# ==========================================
# 1. FRONTEND ECR REPOSITORY
# ==========================================

resource "aws_ecr_repository" "frontend" {
  count = local.enable_ecr ? 1 : 0

  name = "kubemonitor-frontend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "kubemonitor-frontend"
  }
}

# ==========================================
# 2. BACKEND ECR REPOSITORY
# ==========================================

resource "aws_ecr_repository" "backend" {
  count = local.enable_ecr ? 1 : 0

  name = "kubemonitor-backend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "kubemonitor-backend"
  }
}

# ==========================================
# 3. ECR LIFECYCLE POLICIES
# ==========================================

# Automatically delete untagged images
# older than 14 days.

resource "aws_ecr_lifecycle_policy" "cleanup" {

  for_each = local.enable_ecr ? {
    frontend = aws_ecr_repository.frontend[0].name
    backend = aws_ecr_repository.backend[0].name
  } : {}

  repository = each.value

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description = "Remove untagged images older than 14 days"

        selection = {
          tagStatus = "untagged"
          countType = "sinceImagePushed"
          countUnit= "days"
          countNumber = 14
        }

        action = {
          type = "expire"
        }
      }
    ]
  })
}
