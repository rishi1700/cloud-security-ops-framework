import boto3

iam = boto3.client('iam')

def handle_guardduty_finding(detail):
    finding_type = detail.get("type", "")
    resource = detail.get("resource", {}).get("resourceType", "")
    user = detail.get("resource", {}).get("accessKeyDetails", {}).get("userName", "unknown-user")

    print(f"🔔 GuardDuty finding detected: {finding_type}")

    if resource == "AccessKey" and finding_type.startswith("UnauthorizedAccess"):
        print(f"⚠️ Suspicious IAM user detected: {user}")
        try:
            iam.update_login_profile(UserName=user, PasswordResetRequired=True)
            iam.delete_login_profile(UserName=user)
            print(f"✅ Disabled login profile for {user}")
        except Exception as e:
            print(f"❌ Error disabling user login: {e}")
            raise
    else:
        print("✅ No remediation needed for this finding type.")

    return {
        "statusCode": 200,
        "body": f"GuardDuty finding reviewed and user {user} handled if needed"
    }
