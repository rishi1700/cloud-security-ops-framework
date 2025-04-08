# Phase 2: IAM Hardening & Security Services Activation

## 🎯 Goal
Harden IAM, enable security monitoring, and enforce compliance using AWS native services.

## ✅ Features Implemented
- IAM Role with Least Privilege (Custom Read-Only)
- GuardDuty Activation
- Security Hub Enablement
- AWS Config + Compliance Rules
- IAM Access Analyzer Setup

## 🛠️ Terraform Commands

```bash
terraform init
terraform apply -var="logs_s3_bucket_name=<your-access-log-bucket-name>"
