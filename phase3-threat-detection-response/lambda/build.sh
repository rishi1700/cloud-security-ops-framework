#!/bin/bash

set -e

LAMBDA_NAME="auto-remediate-v2"
ZIP_NAME="auto_remediate.zip"

echo "📦 Zipping Lambda files..."

rm -f $ZIP_NAME

# Create a zip with the main handler and playbooks folder
zip -r $ZIP_NAME index.py playbooks/

echo "✅ Zipped as $ZIP_NAME"

echo "⬆️ Uploading to Lambda: $LAMBDA_NAME"

aws lambda update-function-code \
  --function-name $LAMBDA_NAME \
  --zip-file fileb://$ZIP_NAME

echo "🚀 Lambda updated successfully!"
