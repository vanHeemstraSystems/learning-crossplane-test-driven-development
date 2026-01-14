#!/bin/bash

# Run unit tests for Crossplane configurations

# These are pre-deployment tests that don’t require a live cluster

# Usage: ./run-unit-tests.sh

set -e

echo “🧪 Running Unit Tests”
echo “━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━”
echo “”

# Colors

RED=’\033[0;31m’
GREEN=’\033[0;32m’
YELLOW=’\033[1;33m’
NC=’\033[0m’

PASSED=0
FAILED=0
SKIPPED=0

run_test() {
local test_name=$1
local test_command=$2

echo -n “Testing: ${test_name}… “

if eval “${test_command}” &>/dev/null; then
echo -e “${GREEN}PASS${NC}”
((PASSED++))
return 0
else
echo -e “${RED}FAIL${NC}”
((FAILED++))
return 1
fi
}

# Test Suite 1: YAML Syntax Validation

echo “📋 Test Suite 1: YAML Syntax Validation”
echo “━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━”

if command -v yq &> /dev/null; then
run_test “XRD YAML syntax”   
“yq eval ‘explode(.)’ crossplane/xrds/developer-combo/xrd.yaml”

run_test “Composition YAML syntax”   
“yq eval ‘explode(.)’ crossplane/compositions/developer-combo/azure-composition.yaml”

run_test “Example claims YAML syntax”   
“yq eval ‘explode(.)’ crossplane/xrds/developer-combo/examples/small-claim.yaml”
else
echo -e “${YELLOW}⚠️  yq not installed - skipping YAML syntax tests${NC}”
((SKIPPED+=3))
fi

echo “”

# Test Suite 2: Schema Validation

echo “📋 Test Suite 2: Schema Validation”
echo “━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━”

run_test “XRD has required metadata”   
“yq eval ‘.metadata.name’ crossplane/xrds/developer-combo/xrd.yaml | grep -q ‘xdevelopercombo’”

run_test “XRD defines claimNames”   
“yq eval ‘.spec.claimNames.kind’ crossplane/xrds/developer-combo/xrd.yaml | grep -q ‘DeveloperCombo’”

run_test “XRD schema has size enum”   
“yq eval ‘.spec.versions[0].schema.openAPIV3Schema.properties.spec.properties.size.enum[]’ crossplane/xrds/developer-combo/xrd.yaml | grep -q ‘small’”

run_test “XRD requires size field”   
“yq eval ‘.spec.versions[0].schema.openAPIV3Schema.properties.spec.required[]’ crossplane/xrds/developer-combo/xrd.yaml | grep -q ‘size’”

echo “”

# Test Suite 3: Composition Structure

echo “📋 Test Suite 3: Composition Structure”
echo “━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━”

run_test “Composition uses Pipeline mode”   
“yq eval ‘.spec.mode’ crossplane/compositions/developer-combo/azure-composition.yaml | grep -q ‘Pipeline’”

run_test “Composition has function reference”   
“yq eval ‘.spec.pipeline[0].functionRef.name’ crossplane/compositions/developer-combo/azure-composition.yaml | grep -q ‘function-patch-and-transform’”

run_test “Composition has resources”   
“yq eval ‘.spec.pipeline[0].input.resources | length’ crossplane/compositions/developer-combo/azure-composition.yaml | grep -q ‘[1-9]’”

echo “”

# Test Suite 4: Policy Tests (if conftest available)

echo “📋 Test Suite 4: Policy Tests”
echo “━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━”

if command -v conftest &> /dev/null; then
if [ -f “tools/conftest/policy/crossplane.rego” ]; then
if conftest test crossplane/compositions/developer-combo/azure-composition.yaml   
-p tools/conftest/policy/crossplane.rego &>/dev/null; then
echo -e “Testing: All policy rules… ${GREEN}PASS${NC}”
((PASSED++))
else
echo -e “Testing: All policy rules… ${RED}FAIL${NC}”
echo “”
echo “Policy violations found:”
conftest test crossplane/compositions/developer-combo/azure-composition.yaml   
-p tools/conftest/policy/crossplane.rego 2>&1 | grep -E “(WARN|FAIL)” | sed ‘s/^/  /’
((FAILED++))
fi
else
echo -e “${YELLOW}⚠️  Policy file not found - skipping${NC}”
((SKIPPED++))
fi
else
echo -e “${YELLOW}⚠️  conftest not installed - skipping policy tests${NC}”
((SKIPPED++))
fi

echo “”

# Test Suite 5: Resource Validation

echo “📋 Test Suite 5: Resource Validation”
echo “━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━”

# Count resources in composition

RESOURCE_COUNT=$(yq eval ‘.spec.pipeline[0].input.resources | length’   
crossplane/compositions/developer-combo/azure-composition.yaml)

echo “Found ${RESOURCE_COUNT} resources in composition”

# Check for expected resources

run_test “Has ResourceGroup”   
“yq eval ‘.spec.pipeline[0].input.resources[] | select(.name == "resourcegroup")’ crossplane/compositions/developer-combo/azure-composition.yaml | grep -q ‘ResourceGroup’”

run_test “Has Database”   
“yq eval ‘.spec.pipeline[0].input.resources[] | select(.name == "database")’ crossplane/compositions/developer-combo/azure-composition.yaml | grep -q ‘FlexibleServer’”

run_test “Has Storage Account”   
“yq eval ‘.spec.pipeline[0].input.resources[] | select(.name == "storage")’ crossplane/compositions/developer-combo/azure-composition.yaml | grep -q ‘Account’”

run_test “Has Virtual Network”   
“yq eval ‘.spec.pipeline[0].input.resources[] | select(.name == "network")’ crossplane/compositions/developer-combo/azure-composition.yaml | grep -q ‘VirtualNetwork’”

echo “”

# Test Suite 6: Deletion Policy Tests

echo “📋 Test Suite 6: Deletion Policy Tests”
echo “━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━”

# Check each resource has deletionPolicy

for resource in resourcegroup database storage network; do
run_test “${resource} has deletionPolicy”   
“yq eval ‘.spec.pipeline[0].input.resources[] | select(.name == "${resource}") | .base.spec.deletionPolicy’ crossplane/compositions/developer-combo/azure-composition.yaml | grep -q ‘Delete’”
done

echo “”

# Test Suite 7: Patching Logic Tests

echo “📋 Test Suite 7: Patching Logic Tests”
echo “━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━”

run_test “Database has size mapping patch”   
“yq eval ‘.spec.pipeline[0].input.resources[] | select(.name == "database") | .patches[] | select(.fromFieldPath == "spec.size")’ crossplane/compositions/developer-combo/azure-composition.yaml | grep -q ‘toFieldPath’”

run_test “Database size map has small->B1ms”   
“yq eval ‘.spec.pipeline[0].input.resources[] | select(.name == "database") | .patches[] | select(.fromFieldPath == "spec.size") | .transforms[0].map.small’ crossplane/compositions/developer-combo/azure-composition.yaml | grep -q ‘B_Standard_B1ms’”

run_test “Database size map has medium->D2s”   
“yq eval ‘.spec.pipeline[0].input.resources[] | select(.name == "database") | .patches[] | select(.fromFieldPath == "spec.size") | .transforms[0].map.medium’ crossplane/compositions/developer-combo/azure-composition.yaml | grep -q ‘GP_Standard_D2s_v3’”

run_test “Database size map has large->D4s”   
“yq eval ‘.spec.pipeline[0].input.resources[] | select(.name == "database") | .patches[] | select(.fromFieldPath == "spec.size") | .transforms[0].map.large’ crossplane/compositions/developer-combo/azure-composition.yaml | grep -q ‘GP_Standard_D4s_v3’”

echo “”

# Summary

echo “━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━”
echo “📊 Unit Test Summary”
echo “━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━”
echo “”
echo -e “Passed:  ${GREEN}${PASSED}${NC}”
echo -e “Failed:  ${RED}${FAILED}${NC}”
echo -e “Skipped: ${YELLOW}${SKIPPED}${NC}”
echo “”

TOTAL=$((PASSED + FAILED))
if [ $TOTAL -gt 0 ]; then
PERCENTAGE=$(( (PASSED * 100) / TOTAL ))
echo “Success rate: ${PERCENTAGE}%”
fi

echo “”

if [ $FAILED -eq 0 ]; then
echo -e “${GREEN}✅ All unit tests passed!${NC}”
echo “”
echo “📝 Next steps:”
echo “1. Run integration tests: ./scripts/test/run-integration-tests.sh”
echo “2. Deploy to cluster: kubectl apply -f crossplane/xrds/developer-combo/”
exit 0
else
echo -e “${RED}❌ Some unit tests failed${NC}”
echo “”
echo “Please fix the failing tests before proceeding.”
exit 1
fi
