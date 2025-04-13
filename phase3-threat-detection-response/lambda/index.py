import json
import boto3
import os
from playbooks.remediate_s3 import handle_s3_public_access
from playbooks.remediate_admin import handle_admin_policy_attach
from playbooks.remediate_guardduty import handle_guardduty_finding

def lambda_handler(event, context):
    print("📥 Event received:")
    print("📦 DEBUG: Event Source =", event.get("source", "unknown"))
    print("📦 DEBUG: Detail-Type =", event.get("detail-type", "unknown"))
    print("📦 DEBUG: Full Event:")
    print(json.dumps(event, indent=2))

    detail_type = event.get("detail-type", "")
    source = event.get("source", "")
    detail = event.get("detail", {})

    try:
        if source == "aws.iam" and "AttachUserPolicy" in detail.get("eventName", ""):
            return handle_admin_policy_attach(detail)
        
        elif source == "aws.s3" and detail.get("eventName") in ["PutBucketAcl", "PutBucketPolicy"]:
            return handle_s3_public_access(detail)
        
        elif source == "aws.guardduty" and detail_type == "GuardDuty Finding":
            return handle_guardduty_finding(detail)
        
        else:
            print("❌ No remediation playbook matched.")
            return {"statusCode": 200, "body": "No remediation needed."}

    except Exception as e:
        print(f"❌ Error during remediation: {e}")
        return {"statusCode": 500, "body": str(e)}
