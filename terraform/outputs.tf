
// Outputs for ECR repository URLs
output "web_ecr_url" {
  value = aws_ecr_repository.web.repository_url
}

output "api_ecr_url" {
  value = aws_ecr_repository.api.repository_url
}