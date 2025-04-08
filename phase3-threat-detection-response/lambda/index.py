import boto3
import json
import os

sns_client = boto3.client('sns')

def lambda_handler(event, context):
    print("📥 Event received:")
    print(json.dumps(event, indent=2))

    try:
        detail = event.get('detail', {})
        event_name = detail.get('eventName', 'UnknownEvent')
        user_identity = detail.get('userIdentity', {}).get('arn', 'UnknownUser')
        target = detail.get('requestParameters', {}).get('userName') or 'UnknownTarget'

        message = f"""
🚨 Security Alert Detected 🚨

Event: {event_name}
User: {user_identity}
Target: {target}

Raw Event:
{json.dumps(event, indent=2)}
        """

        print("📤 Sending alert via SNS...")

        sns_client.publish(
            TopicArn=os.environ['SNS_TOPIC_ARN'],
            Subject=f"[ALERT] IAM Policy Change Detected: {event_name}",
            Message=message
        )

        print("✅ Alert sent successfully.")

    except Exception as e:
        print(f"❌ Error: {str(e)}")

    return {
        'statusCode': 200,
        'body': 'Execution completed.'
    }
