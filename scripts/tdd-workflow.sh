#!/bin/bash

# TDD Workflow for Crossplane

# Implements Red -> Green -> Refactor cycle

# Usage: ./tdd-workflow.sh

set -e

SCRIPT_DIR=”$(cd “$(dirname “${BASH_SOURCE[0]}”)” && pwd)”
PROJECT_ROOT=”$(cd “${SCRIPT_DIR}/../..” && pwd)”

echo “🔴🟢🔵 Crossplane TDD Workflow”
echo “━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━”
echo “”

# Colors for output

RED=’\033[0;31m’
GREEN=’\033[0;32m’
YELLOW=’\033[1;33m’
NC=’\033[0m’ # No Color

run_test_phase() {
local phase=$1
local description=$2
local command=$3

echo “”
echo “━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━”
echo -e “${YELLOW}Phase: ${phase}${NC}”
echo “Description: ${description}”
echo “━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━”
echo “”

if eval “${command}”; then
echo -e “${GREEN}✅ ${phase} - PASSED${NC}”
return 0
else
echo -e “${RED}❌ ${phase} - FAILED${NC}”
return 1
fi
}

echo “🍔 Fast Food Restaurant TDD Workflow”
echo “”
echo “We’ll test our Developer Combo like a restaurant quality control process:”
echo “1. 🔴 RED: Write tests that fail (menu not ready)”
echo “2. 🟢 GREEN: Make tests pass (cook the meal)”
echo “3. 🔵 REFACTOR: Improve the recipe”
echo “”

# Phase 1: Schema Validation (Testing the Menu)

echo “Phase 1: Testing the Menu Board (XRD Schema)”
if run_test_phase “Schema Validation”   
“Validate XRD has correct structure”   
“yq eval ‘explode(.)’ ${PROJECT_ROOT}/crossplane/xrds/developer-combo/xrd.yaml > /dev/null”; then
echo “   ✅ Menu board is readable”
else
echo “   ❌ Menu board has errors”
exit 1
fi

# Phase 2: Policy Tests (Testing Kitchen Standards)

echo “”
echo “Phase 2: Testing Kitchen Standards (Policies)”

if command -v conftest &> /dev/null; then
if run_test_phase “Deletion Policy Check”   
“All resources must have deletion policies (cleanup rules)”   
“conftest test ${PROJECT_ROOT}/crossplane/compositions/developer-combo/azure-composition.yaml -p ${PROJECT_ROOT}/tools/conftest/policy/crossplane.rego”; then
echo “   ✅ Kitchen cleanup rules are in place”
else
echo “   ❌ Kitchen cleanup rules missing”
echo “”
echo “   Fix with:”
echo “   yq eval ‘.spec.pipeline[0].input.resources[] |= .base.spec.deletionPolicy = "Delete"’ -i composition.yaml”
fi
else
echo “   ⚠️  Skipping policy tests (conftest not installed)”
fi

# Phase 3: Dry-run Validation (Testing Before Opening)

echo “”
echo “Phase 3: Testing Before Opening Restaurant (Dry-run)”

if run_test_phase “XRD Dry-run”   
“Check if XRD would be accepted by Kubernetes”   
“kubectl apply –dry-run=server -f ${PROJECT_ROOT}/crossplane/xrds/developer-combo/xrd.yaml 2>&1”; then
echo “   ✅ Menu can be displayed”
else
echo “   ❌ Menu has errors”
exit 1
fi

if run_test_phase “Composition Dry-run”   
“Check if Composition would be accepted”   
“kubectl apply –dry-run=server -f ${PROJECT_ROOT}/crossplane/compositions/developer-combo/azure-composition.yaml 2>&1”; then
echo “   ✅ Recipe is valid”
else
echo “   ❌ Recipe has errors”
exit 1
fi

# Phase 4: Live Cluster Tests (Opening the Restaurant)

echo “”
echo “Phase 4: Opening the Restaurant (Live Cluster)”

read -p “Deploy to live cluster? This will create actual Azure resources. (y/n) “ -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
echo “Skipping live cluster tests”
else
echo “🚀 Deploying to cluster…”

# Deploy XRD

if run_test_phase “Deploy XRD”   
“Install the menu board”   
“kubectl apply -f ${PROJECT_ROOT}/crossplane/xrds/developer-combo/xrd.yaml”; then
echo “   ✅ Menu board installed”
fi

# Deploy Composition

if run_test_phase “Deploy Composition”   
“Give chefs the recipe”   
“kubectl apply -f ${PROJECT_ROOT}/crossplane/compositions/developer-combo/azure-composition.yaml”; then
echo “   ✅ Recipe provided to kitchen”
fi

# Create test claim

echo “”
echo “📝 Creating test order (small combo)…”

cat <<EOF | kubectl apply -f -
apiVersion: example.com/v1alpha1
kind: DeveloperCombo
metadata:
name: tdd-test-combo
namespace: default
spec:
size: small
includeDatabase: true
storageSize: “10Gi”
environment: development
compositionSelector:
matchLabels:
provider: azure
combo: developer
EOF

echo “⏳ Waiting for order to be ready (this takes 5-10 minutes)…”
echo “   You can watch progress with:”
echo “   kubectl get developercombo tdd-test-combo –watch”
echo “”

# Wait for claim to be ready

if kubectl wait –for=condition=ready –timeout=600s   
developercombo/tdd-test-combo 2>/dev/null; then
echo -e “${GREEN}✅ Order is ready!${NC}”

```
# Show endpoint
ENDPOINT=$(kubectl get developercombo tdd-test-combo -o jsonpath='{.status.endpoint}')
echo "📍 Pick up your order at: ${ENDPOINT}"
```

else
echo -e “${YELLOW}⏰ Order is taking longer than expected${NC}”
echo “   This is normal for Azure resources”
echo “   Continue watching: kubectl get developercombo tdd-test-combo –watch”
fi

# Cleanup

echo “”
read -p “Clean up test resources? (y/n) “ -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
echo “🧹 Cleaning up…”
kubectl delete developercombo tdd-test-combo || true
echo “✅ Cleanup initiated (resources will be deleted in background)”
fi
fi

# Summary

echo “”
echo “━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━”
echo “🎉 TDD Workflow Complete!”
echo “━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━”
echo “”
echo “Summary of what we tested:”
echo “✅ Menu board (XRD) structure”
echo “✅ Kitchen standards (Policies)”
echo “✅ Recipe validity (Composition)”
echo “✅ Restaurant opening (Live deployment)”
echo “”
echo “📚 Next steps for learning:”
echo “1. Add more policy tests in tools/conftest/policy/”
echo “2. Create integration tests in tests/integration/”
echo “3. Build E2E scenarios in tests/e2e/”
echo “4. Try the chainsaw test framework”
echo “”
echo “🔍 Useful commands:”
echo “   Run unit tests:        ./scripts/test/run-unit-tests.sh”
echo “   Run integration tests: ./scripts/test/run-integration-tests.sh”
echo “   Validate policies:     ./scripts/validate/validate-policies.sh”
echo “   Generate new combo:    ./scripts/generate/generate-xrd.sh mycombo”
