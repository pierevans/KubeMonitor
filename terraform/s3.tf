
# ==========================================
# 1. CLOUDTRAIL LOGS BUCKET
# ==========================================

resource "aws_s3_bucket" "cloudtrail" {
  count = local.enable_cloudtrail ? 1 : 0

  bucket_prefix = "kubemonitor-cloudtrail-"

  tags = {
    Name = "kubemonitor-cloudtrail"
  }
}

# ==========================================
# 2. INCIDENT REPORTS BUCKET
# ==========================================

resource "aws_s3_bucket" "reports" {
  count = local.enable_s3_reports ? 1 : 0

  bucket_prefix = "kubemonitor-reports-"

  tags = {
    Name = "kubemonitor-reports"
  }
}

# ==========================================
# 3. BLOCK PUBLIC ACCESS
# ==========================================

resource "aws_s3_bucket_public_access_block" "private" {
  for_each = merge(
    local.enable_cloudtrail ? {
      cloudtrail = aws_s3_bucket.cloudtrail[0].id
    } : {},
    local.enable_s3_reports ? {
      reports = aws_s3_bucket.reports[0].id
    } : {}
  )

  bucket = each.value

  # Blocking public access to the S3 buckets to ensure that
  # logs and reports are not publicly accessible.
  block_public_acls = true
  ignore_public_acls = true
  block_public_policy = true
  restrict_public_buckets = true
}

# ==========================================
# 4. ENABLE S3 ENCRYPTION
# ==========================================

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  for_each = merge(
    local.enable_cloudtrail ? {
      cloudtrail = aws_s3_bucket.cloudtrail[0].id
    } : {},
    local.enable_s3_reports ? {
      reports = aws_s3_bucket.reports[0].id
    } : {}
  )

  bucket = each.value

  # Encrypting new objects with AES-256 encryption
  # by default for privacy protection
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}