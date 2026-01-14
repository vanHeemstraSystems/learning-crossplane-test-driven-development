#!/bin/bash

# Install Azure Providers for Crossplane

# Usage: ./provider-install.sh

set -e

echo “☁️  Installing Azure Providers for Crossplane…”
echo “”

# Configuration

PROVIDER_VERSION=“v1.3.0”

# Install providers

echo “📦 Installing Azure providers…”

## cat <<EOF | kubectl apply -f -

# Provider Family - Azure

apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
name: upbound-provider-family-azure
spec:
package: xpkg.upbound.io/upbound/provider-family-azure:${PROVIDER_VERSION}

-----

# Provider - Azure Storage

apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
name: provider-azure-storage
spec:
package: xpkg.upbound.io/upbound/provider-azure-storage:${PROVIDER_VERSION}

-----

# Provider - Azure SQL/PostgreSQL

apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
name: provider-azure-dbforpostgresql
spec:
package: xpkg.upbound.io/upbound/provider-azure-dbforpostgresql:${PROVIDER_VERSION}

-----

# Provider - Azure Network

apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
name: provider-azure-network
spec:
package: xpkg.upbound.io/upbound/provider-azure-network:${PROVIDER_VERSION}

-----

# Provider - Azure Base (Resource Groups, etc.)

apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
name: provider-azure
spec:
package: xpkg.upbound.io/upbound/provider-azure:${PROVIDER_VERSION}
EOF

echo “⏳ Waiting for providers to download and install…”
echo “   This may take a few minutes…”
sleep 10

# Wait for providers to be healthy

echo “”
echo “⏳ Waiting for providers to be healthy…”

providers=(
“upbound-provider-family-azure”
“provider-azure-storage”
“provider-azure-dbforpostgresql”
“provider-azure-network”
“provider-azure”
)

for provider in “${providers[@]}”; do
echo “   Waiting for ${provider}…”
kubectl wait –for=condition=healthy –timeout=600s “provider/${provider}” || true
done

# Show provider status

echo “”
echo “📊 Provider Status:”
kubectl get providers

echo “”
echo “━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━”
echo “✅ Azure Providers installed!”
echo “━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━”
echo “”
echo “📝 Next steps:”
echo “1. Create Azure Service Principal:”
echo “   az ad sp create-for-rbac \”
echo “     –name crossplane-sp \”
echo “     –role Contributor \”
echo “     –scopes /subscriptions/YOUR_SUBSCRIPTION_ID”
echo “”
echo “2. Create Kubernetes secret:”
echo “   kubectl create secret generic azure-credentials \”
echo “     -n crossplane-system \”
echo “     –from-literal=credentials=’{"clientId": "…", …}’”
echo “”
echo “3. Apply ProviderConfig:”
echo “   kubectl apply -f crossplane/providers/providerconfig-azure.yaml”
echo “”
echo “🔍 Useful commands:”
echo “   Check provider status:  kubectl get providers”
echo “   View provider logs:     kubectl logs -n crossplane-system -l pkg.crossplane.io/provider=provider-azure-storage”
echo “   Describe provider:      kubectl describe provider provider-azure-storage”
