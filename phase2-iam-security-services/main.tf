# Phase 2: IAM Hardening and Security Services Activation

provider "aws" {
  region = "us-east-1"
}

variable "logs_s3_bucket_name" {
  description = "S3 bucket name for AWS Config delivery channel"
  type        = string
}

# -----------------------------------
# IAM Role with Least Privilege Policy
# -----------------------------------
resource "aws_iam_role" "read_only" {
  name = "read-only-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "read_only_policy" {
  name        = "ReadOnlyAccessCustom"
  description = "Read-only access to most AWS services"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["ec2:Describe*", "s3:Get*", "s3:List*"],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_read_only" {
  role       = aws_iam_role.read_only.name
  policy_arn = aws_iam_policy.read_only_policy.arn
}

# -----------------------------
# Enable AWS GuardDuty
# -----------------------------
resource "aws_guardduty_detector" "main" {
  enable = true
}

# -----------------------------
# Enable AWS Security Hub
# -----------------------------
resource "aws_securityhub_account" "main" {}

# -----------------------------
# Enable AWS Config with Rules
# -----------------------------
resource "aws_iam_role" "config_role" {
  name = "aws-config-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "config.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "config_policy" {
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRoleForOrganizations"
}

resource "aws_s3_bucket_policy" "config_logs_policy" {
  bucket = var.logs_s3_bucket_name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AWSConfigBucketPermissionsCheck",
        Effect    = "Allow",
        Principal = {
          Service = "config.amazonaws.com"
        },
        Action    = "s3:GetBucketAcl",
        Resource  = "arn:aws:s3:::${var.logs_s3_bucket_name}"
      },
      {
        Sid       = "AWSConfigBucketDelivery",
        Effect    = "Allow",
        Principal = {
          Service = "config.amazonaws.com"
        },
        Action    = "s3:PutObject",
        Resource  = "arn:aws:s3:::${var.logs_s3_bucket_name}/AWSLogs/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

resource "aws_config_configuration_recorder" "main" {
  name     = "config-recorder"
  role_arn = aws_iam_role.config_role.arn
  recording_group {
    all_supported = true
    include_global_resource_types = true
  }
  depends_on = [aws_iam_role_policy_attachment.config_policy]
}

resource "aws_config_delivery_channel" "main" {
  name           = "config-channel"
  s3_bucket_name = var.logs_s3_bucket_name
  depends_on     = [aws_config_configuration_recorder.main, aws_s3_bucket_policy.config_logs_policy]
}

resource "aws_config_config_rule" "s3_public_read" {
  name = "s3-bucket-public-read-prohibited"
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }
  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "iam_password_policy" {
  name = "iam-password-policy"
  source {
    owner             = "AWS"
    source_identifier = "IAM_PASSWORD_POLICY"
  }
  depends_on = [aws_config_configuration_recorder.main]
}

# -----------------------------
# IAM Access Analyzer
# -----------------------------
resource "aws_accessanalyzer_analyzer" "main" {
  analyzer_name = "org-access-analyzer"
  type          = "ACCOUNT"
}

# -----------------------------
# Outputs
# -----------------------------
output "guardduty_detector_id" {
  value       = aws_guardduty_detector.main.id
  description = "ID of the GuardDuty detector"
}

output "read_only_role_arn" {
  value       = aws_iam_role.read_only.arn
  description = "ARN of the custom read-only IAM role"
}

output "aws_config_recorder_status" {
  value       = aws_config_configuration_recorder.main.name
  description = "Name of the AWS Config configuration recorder"
}

output "access_analyzer_name" {
  value       = aws_accessanalyzer_analyzer.main.analyzer_name
  description = "Name of the IAM Access Analyzer"
}
