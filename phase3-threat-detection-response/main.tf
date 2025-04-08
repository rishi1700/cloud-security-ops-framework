# Phase 3: Threat Detection and Auto-Response with EventBridge + Lambda

provider "aws" {
  region = "us-east-1"
}

# -----------------------------
# SNS Topic for Security Alerts
# -----------------------------
resource "aws_sns_topic" "security_alerts" {
  name = "security-alerts-topic"
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = "prasadrishi170@gmail.com"
}

# -----------------------------
# CloudWatch Log Group for Lambda
# -----------------------------
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/security-response"
  retention_in_days = 7
}

# -----------------------------
# IAM Role for Lambda Function
# -----------------------------
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda-security-response-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "inline_lambda_logging" {
  name = "inline-lambda-cloudwatch-logging"
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logging" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_sns" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
}

# -----------------------------
# Lambda Function for Response
# -----------------------------
resource "aws_lambda_function" "auto_remediate" {
  function_name = "auto-remediate-v2"
  role          = aws_iam_role.lambda_exec_role.arn
  runtime       = "python3.9"
  handler       = "index.lambda_handler"
  timeout       = 10
  filename      = "lambda/auto_remediate.zip"
  source_code_hash = filebase64sha256("lambda/auto_remediate.zip")
  depends_on    = [
    aws_iam_role_policy_attachment.lambda_logging,
    aws_iam_role_policy_attachment.lambda_sns
  ]

  environment {
    variables = {
      ENV             = "production"
      SNS_TOPIC_ARN   = aws_sns_topic.security_alerts.arn
    }
  }
}

# -----------------------------
# EventBridge Rules for CloudTrail Events
# -----------------------------
resource "aws_cloudwatch_event_rule" "iam_policy_change" {
  name        = "detect-iam-policy-change"
  description = "Trigger on IAM policy changes"
  event_pattern = jsonencode({
    source = ["aws.iam"],
    "detail-type" = ["AWS API Call via CloudTrail"],
    detail = {
      eventName = [
        "PutUserPolicy",
        "PutGroupPolicy",
        "PutRolePolicy",
        "AttachRolePolicy",
        "AttachUserPolicy",
        "DetachRolePolicy",
        "DetachRolePolicy"
      ]
    }
  })
}

resource "aws_cloudwatch_event_rule" "s3_public_access" {
  name        = "detect-public-s3"
  description = "Trigger on S3 public access configurations"
  event_pattern = jsonencode({
    source = ["aws.s3"],
    "detail-type" = ["AWS API Call via CloudTrail"],
    detail = {
      eventName = [
        "PutBucketAcl",
        "PutBucketPolicy"
      ]
    }
  })
}

resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  name        = "detect-guardduty-findings"
  description = "Trigger on GuardDuty findings"
  event_pattern = jsonencode({
    source = ["aws.guardduty"],
    "detail-type" = ["GuardDuty Finding"]
  })
}

# -----------------------------
# Event Targets
# -----------------------------
resource "aws_cloudwatch_event_target" "send_to_lambda_iam" {
  rule      = aws_cloudwatch_event_rule.iam_policy_change.name
  target_id = "SendToLambdaIAM"
  arn       = aws_lambda_function.auto_remediate.arn
}

resource "aws_cloudwatch_event_target" "send_to_lambda_s3" {
  rule      = aws_cloudwatch_event_rule.s3_public_access.name
  target_id = "SendToLambdaS3"
  arn       = aws_lambda_function.auto_remediate.arn
}

resource "aws_cloudwatch_event_target" "send_to_lambda_guardduty" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "SendToLambdaGuardDuty"
  arn       = aws_lambda_function.auto_remediate.arn
}

# -----------------------------
# Lambda Permissions
# -----------------------------
resource "aws_lambda_permission" "allow_eventbridge_iam" {
  statement_id  = "AllowExecutionFromEventBridgeIAM"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auto_remediate.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.iam_policy_change.arn
}

resource "aws_lambda_permission" "allow_eventbridge_s3" {
  statement_id  = "AllowExecutionFromEventBridgeS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auto_remediate.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.s3_public_access.arn
}

resource "aws_lambda_permission" "allow_eventbridge_guardduty" {
  statement_id  = "AllowExecutionFromEventBridgeGuardDuty"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auto_remediate.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.guardduty_findings.arn
}

# -----------------------------
# Outputs
# -----------------------------
output "lambda_function_name" {
  value       = aws_lambda_function.auto_remediate.function_name
  description = "Lambda function used for automatic security response"
}

output "eventbridge_rule_name_iam" {
  value       = aws_cloudwatch_event_rule.iam_policy_change.name
  description = "EventBridge rule for detecting IAM policy changes"
}

output "eventbridge_rule_name_s3" {
  value       = aws_cloudwatch_event_rule.s3_public_access.name
  description = "EventBridge rule for detecting public S3 access"
}

output "eventbridge_rule_name_guardduty" {
  value       = aws_cloudwatch_event_rule.guardduty_findings.name
  description = "EventBridge rule for detecting GuardDuty findings"
}

output "sns_topic_arn" {
  value       = aws_sns_topic.security_alerts.arn
  description = "SNS topic used to send security alert notifications"
}

output "sns_email_subscription" {
  value       = aws_sns_topic_subscription.email_alert.endpoint
  description = "Email address subscribed to receive SNS alerts"
}
