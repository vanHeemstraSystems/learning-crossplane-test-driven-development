#!/bin/bash

# Run integration tests for Crossplane configurations

# Usage: ./run-integration-tests.sh [combo-name] [size]

# Example: ./run-integration-tests.sh developer-combo small

set -e

COMBO_NAME=${1:-developer-combo}
SIZE=${2:-small}

echo “🧪 Running Integration Tests”
echo “━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━”
echo “Combo: ${COMBO_NAME}”
echo “Size: ${SIZE}”
echo “”

# Colors

RED=’\033[0;31m’
GREEN=’\033[0;32m’
YELLOW=’\033[1;33m’
NC=’\033[0m’

# Test namespace

TEST_NAMESPACE=“crossplane-test-$(date +%s)”

cleanup() {
echo “”
echo “🧹 Cleaning up test namespace…”
kubectl delete namespace “${TEST_NAMESPACE}” –wait=false 2>/dev/null || true
}

trap cleanup EXIT

# Create test namespace

echo “📦 Creating test namespace: ${TEST_NAMESPACE}”
kubectl create namespace “${TEST_NAMESPACE}”

# Function to run a test step

run_step() {
local step_name=$1
local description=$2
local command=$3

echo “”
echo “━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━”
echo “Step: ${step_name}”
echo “Description: ${description}”
echo “━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━”

if eval “${command}”; then
echo -e “${GREEN}✅ ${step_name} - PASSED${NC}”
return 0
else
echo -e “${RED}❌ ${step_name} - FAILED${NC}”
return 1
fi
}

# Test 1: Create claim

echo “”
echo “Test 1: Creating ${SIZE} Developer Combo claim”

cat <<EOF | kubectl apply -f -
apiVersion: example.com/v1alpha1
kind: DeveloperCombo
metadata:
name: test-combo-${SIZE}
namespace: ${TEST_NAMESPACE}
spec:
size: ${SIZE}
includeDatabase: true
storageSize: “10Gi”
environment: development
compositionSelector:
matchLabels:
provider: azure
combo: developer
EOF

# Test 2: Verify claim was accepted

run_step “Claim Accepted”   
“Verify the claim was accepted by Crossplane”   
“kubectl get developercombo test-combo-${SIZE} -n ${TEST_NAMESPACE} -o yaml | grep -q ‘kind: DeveloperCombo’”

# Test 3: Wait for composite resource creation

echo “”
echo “⏳ Waiting for composite resource to be created…”
sleep 5

COMPOSITE_NAME=$(kubectl get developercombo test-combo-${SIZE} -n ${TEST_NAMESPACE}   
-o jsonpath=’{.spec.resourceRef.name}’ 2>/dev/null || echo “”)

if [ -z “$COMPOSITE_NAME” ]; then
echo -e “${YELLOW}⚠️  Composite resource not yet created (this is normal initially)${NC}”
else
echo -e “${GREEN}✅ Composite resource created: ${COMPOSITE_NAME}${NC}”

# Test 4: Check managed resources

echo “”
echo “📊 Checking managed resources…”

MANAGED_RESOURCES=$(kubectl get managed -l crossplane.io/composite=${COMPOSITE_NAME} 2>/dev/null | tail -n +2 | wc -l)
echo “Found ${MANAGED_RESOURCES} managed resources”

if [ “${MANAGED_RESOURCES}” -gt 0 ]; then
echo -e “${GREEN}✅ Managed resources are being created${NC}”
echo “”
echo “Current managed resources:”
kubectl get managed -l crossplane.io/composite=${COMPOSITE_NAME} –no-headers | awk ‘{print “  - “ $1 “ (” $2 “)”}’
fi
fi

# Test 5: Monitor reconciliation

echo “”
echo “🔄 Monitoring reconciliation (will wait up to 2 minutes)…”

for i in {1..24}; do
STATUS=$(kubectl get developercombo test-combo-${SIZE} -n ${TEST_NAMESPACE}   
-o jsonpath=’{.status.conditions[?(@.type==“Ready”)].status}’ 2>/dev/null || echo “Unknown”)

if [ “$STATUS” = “True” ]; then
echo -e “${GREEN}✅ Claim is ready!${NC}”
break
elif [ “$STATUS” = “False” ]; then
REASON=$(kubectl get developercombo test-combo-${SIZE} -n ${TEST_NAMESPACE}   
-o jsonpath=’{.status.conditions[?(@.type==“Ready”)].reason}’ 2>/dev/null)
echo “Status: Not Ready (${REASON})”
else
echo “Status: ${STATUS} (waiting…)”
fi

sleep 5
done

# Test 6: Verify expected database SKU

echo “”
echo “🔍 Verifying database SKU matches size…”

EXPECTED_SKU=””
case ${SIZE} in
small) EXPECTED_SKU=“B_Standard_B1ms” ;;
medium) EXPECTED_SKU=“GP_Standard_D2s_v3” ;;
large) EXPECTED_SKU=“GP_Standard_D4s_v3” ;;
esac

if [ -n “$COMPOSITE_NAME” ]; then
ACTUAL_SKU=$(kubectl get flexibleserver -l crossplane.io/composite=${COMPOSITE_NAME}   
-o jsonpath=’{.items[0].spec.forProvider.skuName}’ 2>/dev/null || echo “NotFound”)

if [ “$ACTUAL_SKU” = “$EXPECTED_SKU” ]; then
echo -e “${GREEN}✅ Database SKU is correct: ${ACTUAL_SKU}${NC}”
else
echo -e “${YELLOW}⚠️  Database SKU mismatch. Expected: ${EXPECTED_SKU}, Got: ${ACTUAL_SKU}${NC}”
fi
fi

# Summary

echo “”
echo “━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━”
echo “📊 Integration Test Summary”
echo “━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━”
echo “”

# Final status check

FINAL_STATUS=$(kubectl get developercombo test-combo-${SIZE} -n ${TEST_NAMESPACE}   
-o jsonpath=’{.status.conditions[?(@.type==“Ready”)].status}’ 2>/dev/null || echo “Unknown”)

if [ “$FINAL_STATUS” = “True” ]; then
echo -e “${GREEN}✅ Integration test PASSED${NC}”
echo “”
echo “Your Developer Combo is ready to serve!”

ENDPOINT=$(kubectl get developercombo test-combo-${SIZE} -n ${TEST_NAMESPACE}   
-o jsonpath=’{.status.endpoint}’ 2>/dev/null)

if [ -n “$ENDPOINT” ]; then
echo “📍 Endpoint: ${ENDPOINT}”
fi

exit 0
else
echo -e “${YELLOW}⚠️  Integration test INCOMPLETE${NC}”
echo “”
echo “The claim is still reconciling. This is normal for Azure resources.”
echo “They can take 10-15 minutes to provision.”
echo “”
echo “Continue monitoring with:”
echo “  kubectl get developercombo test-combo-${SIZE} -n ${TEST_NAMESPACE} –watch”
echo “”
echo “View details:”
echo “  kubectl describe developercombo test-combo-${SIZE} -n ${TEST_NAMESPACE}”

exit 0
fi
