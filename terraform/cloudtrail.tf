
# ==========================================
# 1. AWS ACCOUNT INFORMATION
# ==========================================

# Terraform plan fetches AWS ID and partition to build CloudTrail ARN
data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  cloudtrail_name = "kubemonitor-trail"

  # Use AWS ID and partition to build trail ARN
  # Only this trail can write to the S3 bucket
  cloudtrail_arn = "arn:${data.aws_partition.current.partition}:cloudtrail:${var.aws_region}:${data.aws_caller_identity.current.account_id}:trail/${local.cloudtrail_name}"
}

# ==========================================
# 2. CLOUDTRAIL S3 BUCKET POLICY
# ==========================================

data "aws_iam_policy_document" "cloudtrail" {
  count = local.enable_cloudtrail ? 1 : 0

  statement {
    sid = "AWSCloudTrailAclCheck"
    effect = "Allow"

    # Who wants to access bucket
    principals {
      type = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    # Can check bucket
    actions = ["s3:GetBucketAcl"]

    # Which resources are allowed to be accessed
    resources = [
      aws_s3_bucket.cloudtrail[0].arn
    ]

    # Verify only the specific trail
    condition {
      test = "StringEquals"
      variable = "aws:SourceArn"
      values = [local.cloudtrail_arn]
    }
  }

  statement {
    sid = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    # Can write to bucket
    actions = ["s3:PutObject"]

    # Where the trail can write to in the bucket
    resources = [
      "${aws_s3_bucket.cloudtrail[0].arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    ]

    # Bucket needs full control of uploaded logs by trail
    condition {
      test = "StringEquals"
      variable = "s3:x-amz-acl"
      values = ["bucket-owner-full-control"]
    }

    # Allow only the specific trail to write to the bucket
    condition {
      test = "StringEquals"
      variable = "aws:SourceArn"
      values = [local.cloudtrail_arn]
    }
  }
}

# Attach policy to S3 bucket
resource "aws_s3_bucket_policy" "cloudtrail" {
  count = local.enable_cloudtrail ? 1 : 0

  # Bucket that gets policy attached
  bucket = aws_s3_bucket.cloudtrail[0].id

  # Policy attached to bucket
  policy = data.aws_iam_policy_document.cloudtrail[0].json
}

# ==========================================
# 3. CREATE CLOUDTRAIL
# ==========================================

resource "aws_cloudtrail" "main" {
  count = local.enable_cloudtrail ? 1 : 0

  name = local.cloudtrail_name

  s3_bucket_name = aws_s3_bucket.cloudtrail[0].id

  enable_logging = true

  is_multi_region_trail = false

  include_global_service_events = true

  enable_log_file_validation = true

  depends_on = [
    aws_s3_bucket_policy.cloudtrail
  ]

  tags = {
    Name = "kubemonitor-cloudtrail"
  }
}
