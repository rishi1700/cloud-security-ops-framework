#!/bin/bash

LAMBDA_NAME="auto-remediate-v2"
TEST_EVENT_FILE=$1

if [ -z "$TEST_EVENT_FILE" ]; then
  echo "❌ Usage: ./test-lambda-and-logs.sh <test-event-file.json>"
  exit 1
fi

echo "🚀 Invoking Lambda: $LAMBDA_NAME with payload $TEST_EVENT_FILE"
aws lambda invoke \
  --function-name "$LAMBDA_NAME" \
  --cli-binary-format raw-in-base64-out \
  --payload file://$TEST_EVENT_FILE \
  response.json > /dev/null

echo "⏳ Waiting for logs..."

sleep 5

# Fetch latest log stream
LOG_STREAM=$(aws logs describe-log-streams \
  --log-group-name /aws/lambda/$LAMBDA_NAME \
  --order-by LastEventTime \
  --descending \
  --limit 1 \
  --query "logStreams[0].logStreamName" \
  --output text)

if [ "$LOG_STREAM" == "None" ]; then
  echo "❌ No log stream found. Check if Lambda ran correctly."
  exit 1
fi

echo "📄 Latest Log Stream: $LOG_STREAM"
echo "🔍 Fetching logs..."

aws logs get-log-events \
  --log-group-name /aws/lambda/$LAMBDA_NAME \
  --log-stream-name "$LOG_STREAM" \
  --limit 50 \
  --query "events[*].message" \
  --output text
