#!/bin/bash

# Generate Composition using YQ

# Usage: ./generate-composition.sh <combo-name> <provider>

# Example: ./generate-composition.sh developercombo azure

set -e

COMBO_NAME=${1:-developercombo}
PROVIDER=${2:-azure}
API_GROUP=“example.com”
OUTPUT_DIR=“crossplane/compositions/${COMBO_NAME}”

echo “👨‍🍳 Generating Composition for: ${COMBO_NAME}”
echo “🏪 Provider: ${PROVIDER}”

# Create output directory

mkdir -p “${OUTPUT_DIR}”

# Generate base composition

yq eval ’

# Set metadata

.metadata.name = “’${COMBO_NAME}’.’${PROVIDER}’.’${API_GROUP}’” |
.metadata.labels.provider = “’${PROVIDER}’” |
.metadata.labels.combo = “’${COMBO_NAME}’” |

# Set composite type reference

.spec.compositeTypeRef.apiVersion = “’${API_GROUP}’/v1alpha1” |
.spec.compositeTypeRef.kind = “X’${COMBO_NAME^}’”
’ templates/composition-template.yaml > /tmp/composition-base.yaml

# Add deletion policies to all resources

echo “🧹 Adding deletion policies…”
yq eval ’
.spec.pipeline[0].input.resources[] |=
.base.spec.deletionPolicy = “Delete”
’ -i /tmp/composition-base.yaml

# Add ManagedBy tags

echo “🏷️  Adding management tags…”
yq eval ’
.spec.pipeline[0].input.resources[] |=
.base.spec.forProvider.tags.ManagedBy = “Crossplane”
’ -i /tmp/composition-base.yaml

# Validate the generated YAML

echo “🔍 Validating YAML syntax…”
yq eval ‘explode(.)’ /tmp/composition-base.yaml > /dev/null && echo “✅ Valid YAML”

# Run policy tests

echo “🔍 Running policy tests…”
if command -v conftest &> /dev/null; then
if conftest test /tmp/composition-base.yaml -p tools/conftest/policy/ 2>/dev/null; then
echo “✅ Policy tests passed!”
else
echo “⚠️  Policy tests failed - review the composition”
echo “   (You can still save it and fix issues later)”
fi
else
echo “⚠️  conftest not installed - skipping policy tests”
fi

# Dry-run validation

echo “🔍 Validating against Kubernetes API…”
if kubectl apply –dry-run=server -f /tmp/composition-base.yaml 2>/dev/null; then
echo “✅ Composition is valid!”
mv /tmp/composition-base.yaml “${OUTPUT_DIR}/${PROVIDER}-composition.yaml”
echo “✅ Saved: ${OUTPUT_DIR}/${PROVIDER}-composition.yaml”
else
echo “❌ Composition validation failed (this is ok if cluster isn’t running)”
mv /tmp/composition-base.yaml “${OUTPUT_DIR}/${PROVIDER}-composition.yaml”
echo “📝 Saved anyway: ${OUTPUT_DIR}/${PROVIDER}-composition.yaml”
fi

echo “”
echo “📝 Next steps:”
echo “1. Review: ${OUTPUT_DIR}/${PROVIDER}-composition.yaml”
echo “2. Add specific resources (database, storage, network)”
echo “3. Add patches for size mapping”
echo “4. Test: ./scripts/validate/validate-policies.sh”
echo “5. Apply: kubectl apply -f ${OUTPUT_DIR}/${PROVIDER}-composition.yaml”
