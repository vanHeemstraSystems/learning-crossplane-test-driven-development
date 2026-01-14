#!/bin/bash

# Generate Claim using YQ

# Usage: ./generate-claim.sh <app-name> <environment> <size>

# Example: ./generate-claim.sh myapp dev small

set -e

APP_NAME=${1:-myapp}
ENVIRONMENT=${2:-development}
SIZE=${3:-small}
API_GROUP=“example.com”
NAMESPACE=”${ENVIRONMENT}”

echo “🛒 Generating Claim (Customer Order)…”
echo “📦 App: ${APP_NAME}”
echo “🏷️  Environment: ${ENVIRONMENT}”
echo “📏 Size: ${SIZE}”

# Validate size

if [[ ! “${SIZE}” =~ ^(small|medium|large)$ ]]; then
echo “❌ Invalid size: ${SIZE}”
echo “   Valid sizes: small, medium, large”
exit 1
fi

# Create namespace directory

OUTPUT_DIR=“crossplane/claims/${ENVIRONMENT}”
mkdir -p “${OUTPUT_DIR}”

# Generate claim

cat > “${OUTPUT_DIR}/${APP_NAME}-${ENVIRONMENT}-combo.yaml” <<EOF

# ${APP_NAME^} ${ENVIRONMENT^} Environment

# Size: ${SIZE} ($(describe_size ${SIZE}))

apiVersion: ${API_GROUP}/v1alpha1
kind: DeveloperCombo
metadata:
name: ${APP_NAME}-${ENVIRONMENT}
namespace: ${NAMESPACE}
annotations:
description: “${SIZE^} combo for ${ENVIRONMENT} - ${APP_NAME}”
spec:
size: ${SIZE}
includeDatabase: true
storageSize: “$(get_storage_size ${SIZE})”
environment: ${ENVIRONMENT}

compositionSelector:
matchLabels:
provider: azure
combo: developer
EOF

echo “✅ Generated: ${OUTPUT_DIR}/${APP_NAME}-${ENVIRONMENT}-combo.yaml”

# Validate

echo “🔍 Validating YAML syntax…”
yq eval ‘explode(.)’ “${OUTPUT_DIR}/${APP_NAME}-${ENVIRONMENT}-combo.yaml” > /dev/null && echo “✅ Valid YAML”

echo “”
echo “📝 Your Order Summary:”
echo “━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━”
echo “🍔 Meal: Developer Combo (${SIZE})”
echo “🍟 Storage: $(get_storage_size ${SIZE})”
echo “🥤 Database: PostgreSQL Flexible Server”
echo “🍽️  Environment: ${ENVIRONMENT}”
echo “━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━”
echo “”
echo “📝 Next steps:”
echo “1. Review: ${OUTPUT_DIR}/${APP_NAME}-${ENVIRONMENT}-combo.yaml”
echo “2. Create namespace: kubectl create namespace ${NAMESPACE}”
echo “3. Apply: kubectl apply -f ${OUTPUT_DIR}/${APP_NAME}-${ENVIRONMENT}-combo.yaml”
echo “4. Watch: kubectl get developercombo -n ${NAMESPACE} –watch”

# Helper functions

describe_size() {
case $1 in
small) echo “Kids Meal - Development” ;;
medium) echo “Regular Meal - Staging” ;;
large) echo “Super Size - Production” ;;
esac
}

get_storage_size() {
case $1 in
small) echo “10Gi” ;;
medium) echo “50Gi” ;;
large) echo “500Gi” ;;
esac
}
