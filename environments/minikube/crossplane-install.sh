#!/bin/bash

# Install Crossplane on Minikube

# Usage: ./crossplane-install.sh

set -e

echo “🎯 Installing Crossplane…”
echo “”

# Check if helm is installed

if ! command -v helm &> /dev/null; then
echo “❌ Helm is not installed!”
echo “”
echo “Install with:”
echo “  brew install helm  # macOS”
echo “  # OR follow: https://helm.sh/docs/intro/install/”
exit 1
fi

# Configuration

CROSSPLANE_VERSION=“1.17.0”
NAMESPACE=“crossplane-system”

echo “📦 Installing Crossplane ${CROSSPLANE_VERSION}…”

# Add Crossplane Helm repository

echo “📚 Adding Crossplane Helm repository…”
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update

# Install Crossplane

echo “🚀 Installing Crossplane…”
helm upgrade –install crossplane   
crossplane-stable/crossplane   
–namespace “${NAMESPACE}”   
–create-namespace   
–version “${CROSSPLANE_VERSION}”   
–wait

# Install Crossplane CLI (optional but useful)

echo “🛠️  Installing Crossplane CLI…”
if [[ “$OSTYPE” == “darwin”* ]]; then
if command -v brew &> /dev/null; then
brew install crossplane/tap/crossplane
else
curl -sL https://raw.githubusercontent.com/crossplane/crossplane/master/install.sh | sh
sudo mv crossplane /usr/local/bin
fi
elif [[ “$OSTYPE” == “linux-gnu”* ]]; then
curl -sL https://raw.githubusercontent.com/crossplane/crossplane/master/install.sh | sh
sudo mv crossplane /usr/local/bin
fi

# Wait for Crossplane to be ready

echo “⏳ Waiting for Crossplane to be ready…”
kubectl wait –for=condition=available –timeout=300s   
deployment/crossplane -n “${NAMESPACE}”

# Verify installation

echo “✅ Verifying Crossplane installation…”
kubectl get pods -n “${NAMESPACE}”

# Check Crossplane version

echo “”
echo “📊 Crossplane version:”
kubectl get deployment crossplane -n “${NAMESPACE}”   
-o jsonpath=’{.spec.template.spec.containers[0].image}’
echo “”

# Install Crossplane function for patch-and-transform

echo “🔧 Installing function-patch-and-transform…”
cat <<EOF | kubectl apply -f -
apiVersion: pkg.crossplane.io/v1beta1
kind: Function
metadata:
name: function-patch-and-transform
spec:
package: xpkg.upbound.io/crossplane-contrib/function-patch-and-transform:v0.8.0
EOF

echo “⏳ Waiting for function to be ready…”
kubectl wait –for=condition=healthy –timeout=300s   
function/function-patch-and-transform

echo “”
echo “━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━”
echo “✅ Crossplane is installed and ready!”
echo “━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━”
echo “”
echo “📝 Next steps:”
echo “1. Install Azure providers: ./provider-install.sh”
echo “2. Configure Azure credentials”
echo “3. Deploy your first XRD and Composition”
echo “”
echo “🔍 Useful commands:”
echo “   Check pods:      kubectl get pods -n ${NAMESPACE}”
echo “   Check functions: kubectl get functions”
echo “   Check providers: kubectl get providers”
echo “   View logs:       kubectl logs -n ${NAMESPACE} deployment/crossplane -f”
