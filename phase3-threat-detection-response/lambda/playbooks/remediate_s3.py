import boto3
from botocore.exceptions import ClientError

s3 = boto3.client('s3')

def handle_s3_public_access(detail):
    bucket_name = detail.get("requestParameters", {}).get("bucketName", "unknown-bucket")

    print(f"🔧 Attempting to revoke public access from bucket: {bucket_name}")

    try:
        # Set ACL to private
        s3.put_bucket_acl(Bucket=bucket_name, ACL='private')
        print(f"✅ Public access revoked for bucket: {bucket_name}")

    except ClientError as e:
        if "AccessControlListNotSupported" in str(e):
            print(f"ℹ️ Bucket {bucket_name} does not allow ACL changes (ACLs disabled). No action taken.")
        else:
            print(f"❌ Failed to update ACL: {e}")
            raise

    return {
        "statusCode": 200,
        "body": f"ACL remediation completed for {bucket_name}"
    }
