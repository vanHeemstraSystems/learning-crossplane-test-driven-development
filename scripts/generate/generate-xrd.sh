#!/bin/bash

# Generate XRD using YQ

# Usage: ./generate-xrd.sh <combo-name> <api-group>

# Example: ./generate-xrd.sh developercombo example.com

set -e

COMBO_NAME=${1:-developercombo}
API_GROUP=${2:-example.com}
OUTPUT_DIR=“crossplane/xrds/${COMBO_NAME}”

echo “🍔 Generating XRD for: ${COMBO_NAME}”
echo “📋 API Group: ${API_GROUP}”

# Create output directory

mkdir -p “${OUTPUT_DIR}”

# Generate XRD using yq

yq eval ’

# Set metadata

.metadata.name = “x’${COMBO_NAME}’.’${API_GROUP}’” |

# Set spec.group

.spec.group = “’${API_GROUP}’” |

# Set names

.spec.names.kind = “X’${COMBO_NAME^}’” |
.spec.names.plural = “x’${COMBO_NAME}’” |

# Set claim names

.spec.claimNames.kind = “’${COMBO_NAME^}’” |
.spec.claimNames.plural = “’${COMBO_NAME}’” |

# Add description

.spec.versions[0].schema.openAPIV3Schema.properties.spec.description =
“’${COMBO_NAME^}’ specification - like ordering from a fast food menu”
’ templates/xrd-template.yaml > “${OUTPUT_DIR}/xrd.yaml”

echo “✅ Generated: ${OUTPUT_DIR}/xrd.yaml”

# Validate the generated YAML

echo “🔍 Validating YAML syntax…”
yq eval ‘explode(.)’ “${OUTPUT_DIR}/xrd.yaml” > /dev/null && echo “✅ Valid YAML”

# Dry-run validation

echo “🔍 Validating against Kubernetes API…”
if kubectl apply –dry-run=server -f “${OUTPUT_DIR}/xrd.yaml” 2>/dev/null; then
echo “✅ XRD is valid!”
else
echo “❌ XRD validation failed (this is ok if cluster isn’t running)”
fi

echo “”
echo “📝 Next steps:”
echo “1. Review: ${OUTPUT_DIR}/xrd.yaml”
echo “2. Customize the schema properties”
echo “3. Generate composition: ./scripts/generate/generate-composition.sh ${COMBO_NAME} azure”
echo “4. Apply: kubectl apply -f ${OUTPUT_DIR}/xrd.yaml”
