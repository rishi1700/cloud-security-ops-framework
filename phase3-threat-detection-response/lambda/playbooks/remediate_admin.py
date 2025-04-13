import boto3

iam = boto3.client('iam')

def handle_admin_policy_attach(detail):
    user_name = detail.get("requestParameters", {}).get("userName")
    policy_arn = detail.get("requestParameters", {}).get("policyArn")

    print(f"🔍 Checking if attached policy is AdministratorAccess...")
    if "AdministratorAccess" in policy_arn:
        print(f"⚠️ Detected admin policy on user: {user_name}")
        try:
            iam.detach_user_policy(UserName=user_name, PolicyArn=policy_arn)
            print(f"✅ Detached AdministratorAccess from {user_name}")
        except Exception as e:
            print(f"❌ Failed to detach policy: {e}")
            raise
    else:
        print("✅ Policy is not AdministratorAccess — no action needed.")

    return {
        "statusCode": 200,
        "body": f"Checked and remediated admin access if necessary for {user_name}"
    }
