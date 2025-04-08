# Phase 3: Threat Detection and Auto-Response

## 🎯 Goal
Enable real-time detection and automated response to cloud threats using AWS EventBridge, Lambda, SNS, and GuardDuty.

---

## ✅ Key Features

### 🔔 Event Sources Monitored:
- **IAM Policy Changes** via CloudTrail (e.g., AttachRolePolicy, PutUserPolicy)
- **S3 Bucket Public Access Changes** (e.g., PutBucketAcl, PutBucketPolicy)
- **GuardDuty Findings** for real-time threat intelligence

### ⚙️ Automation:
- **EventBridge rules** trigger on specific API events or findings
- **Lambda function** logs the event and sends alerts
- **SNS Topic** broadcasts the alert to an email recipient

---

## 📂 Deployment Instructions

1. Replace the SNS email with your own in the Terraform file:
```hcl
endpoint  = "your.email@example.com"
```
2. Confirm the email subscription once you receive the SNS confirmation.

3. Deploy the project:
```bash
terraform init
terraform apply
```

4. (Optional) Add more detection rules by duplicating and editing `aws_cloudwatch_event_rule` blocks.

---

## 🔄 Lambda Function Behavior
- Captures event details from CloudTrail or GuardDuty
- Extracts event name, resource, and user identity
- Sends a detailed alert to SNS for visibility

> Lambda code is located in `lambda/index.py` and zipped into `auto_remediate.zip`

---

## 🔎 Outputs
| Output Name                     | Description                                        |
|--------------------------------|----------------------------------------------------|
| `lambda_function_name`         | Deployed Lambda function name                     |
| `eventbridge_rule_name_iam`    | Rule for IAM policy change detection              |
| `eventbridge_rule_name_s3`     | Rule for detecting public S3 config changes       |
| `eventbridge_rule_name_guardduty` | Rule for GuardDuty findings                    |
| `sns_topic_arn`                | ARN of the SNS topic used for alerts              |
| `sns_email_subscription`       | Email subscribed to receive SNS alerts            |

---

## 🛡️ What This Achieves
✅ Demonstrates hands-on capability in:
- Event-driven detection
- Lambda automation
- IAM hardening + response
- GuardDuty integration
- DevSecOps alerting pipeline

This phase completes the **Cloud Security Operations Framework**.

---

## 🗂️ Next Steps
You can now:
- Export this to GitHub with all 3 phases
- Share your story and architecture on LinkedIn
- Use this as a **portfolio project** to apply for Cloud Security roles

