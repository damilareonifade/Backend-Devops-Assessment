#!/bin/bash

# Set variables
AWS_SECRET_NAME="banka-os-secret"   # The AWS Secrets Manager secret name
K8S_SECRET_NAME="banka-os-secret"  # The Kubernetes secret name
K8S_NAMESPACE="default"                  # The Kubernetes namespace
REGION="us-east-1"                       # AWS region

# Check if jq and aws CLI are installed
if ! command -v jq &> /dev/null || ! command -v aws &> /dev/null; then
    echo "Error: This script requires 'jq' and 'aws-cli' to be installed."
    exit 1
fi

# Get the secret string from AWS Secrets Manager
SECRET=$(aws secretsmanager get-secret-value --secret-id "$AWS_SECRET_NAME" --query SecretString --output text --region "$REGION")

if [ $? -ne 0 ]; then
    echo "Error: Failed to retrieve the secret from AWS Secrets Manager."
    exit 1
fi

# Delete the existing Kubernetes secret if it exists
kubectl delete secret "$K8S_SECRET_NAME" --namespace "$K8S_NAMESPACE" --ignore-not-found

# Parse the JSON secret and dynamically construct the kubectl command
CREATE_CMD="kubectl create secret generic $K8S_SECRET_NAME --namespace $K8S_NAMESPACE"
for key in $(echo "$SECRET" | jq -r 'keys[]'); do
    value=$(echo "$SECRET" | jq -r --arg key "$key" '.[$key]')
    CREATE_CMD="$CREATE_CMD --from-literal=$key=\"$value\""
done

# Execute the kubectl command
eval "$CREATE_CMD"

if [ $? -eq 0 ]; then
    echo "Kubernetes secret '$K8S_SECRET_NAME' created successfully in namespace '$K8S_NAMESPACE'."
else
    echo "Error: Failed to create Kubernetes secret."
    exit 1
fi
