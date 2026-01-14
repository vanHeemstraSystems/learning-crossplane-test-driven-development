#!/bin/bash

# Validate Crossplane configurations using conftest policies

# Usage: ./validate-policies.sh [file-or-directory]

set -e

TARGET=${1:-crossplane/compositions/}
POLICY_DIR=“tools/conftest/policy”

echo “🔍 Validating Crossplane configurations with conftest…”
echo “📁 Target: ${TARGET}”
echo “📋 Policies: ${POLICY_DIR}”
echo “”

# Check if conftest is installed

if ! command -v conftest &> /dev/null; then
echo “❌ conftest is not installed!”
echo “”
echo “Install with:”
echo “  brew install conftest  # macOS”
echo “  # OR”
echo “  curl -L https://github.com/open-policy-agent/conftest/releases/latest/download/conftest_Linux_x86_64.tar.gz | tar xz”
exit 1
fi

# Run conftest

echo “Running tests…”
echo “━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━”

if conftest test “${TARGET}” -p “${POLICY_DIR}” –all-namespaces; then
echo “━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━”
echo “”
echo “✅ All policy tests passed!”
echo “🎉 Your Crossplane configurations are ready to serve!”
exit 0
else
echo “━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━”
echo “”
echo “❌ Some policy tests failed!”
echo “”
echo “Common fixes:”
echo “1. Add deletionPolicy: Delete to all resources”
echo “2. Add ManagedBy tag to all resources”
echo “3. Add readiness checks”
echo “4. Follow naming conventions”
echo “”
echo “Run this to auto-fix some issues:”
echo “  ./scripts/generate/generate-composition.sh <combo-name> <provider>”
exit 1
fi
