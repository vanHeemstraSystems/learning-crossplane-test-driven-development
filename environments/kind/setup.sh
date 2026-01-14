#!/bin/bash

# Setup kind (Kubernetes in Docker) cluster for Crossplane TDD

# kind is lighter and faster than Minikube, great for CI/CD

# Usage: ./setup.sh

set -e

echo “🚀 Setting up kind cluster for Crossplane TDD…”
echo “”

# Colors for output

RED=’\033[0;31m’
GREEN=’\033[0;32m’
YELLOW=’\033[1;33m’
BLUE=’\033[0;34m’
NC=’\033[0m’ # No Color

# Check if kind is installed

if ! command -v kind &> /dev/null; then
echo -e “${RED}❌ kind is not installed!${NC}”
echo “”
echo “Install with:”
echo “”
echo “  # macOS”
echo “  brew install kind”
echo “”
echo “  # Linux”
echo “  curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64”
echo “  chmod +x ./kind”
echo “  sudo mv ./kind /usr/local/bin/kind”
echo “”
echo “  # Windows (PowerShell)”
echo “  curl.exe -Lo kind-windows-amd64.exe https://kind.sigs.k8s.io/dl/v0.20.0/kind-windows-amd64”
echo “  Move-Item .\kind-windows-amd64.exe c:\windows\system32\kind.exe”
echo “”
exit 1
fi

# Check if Docker is running

if ! docker info &> /dev/null; then
echo -e “${RED}❌ Docker is not running!${NC}”
echo “”
echo “Please start Docker Desktop and try again.”
exit 1
fi

# Configuration

CLUSTER_NAME=“crossplane-tdd”
K8S_VERSION=“v1.28.0”
WORKER_NODES=2

echo -e “${BLUE}📋 Cluster Configuration:${NC}”
echo “   Name: ${CLUSTER_NAME}”
echo “   Kubernetes: ${K8S_VERSION}”
echo “   Control Plane: 1 node”
echo “   Worker Nodes: ${WORKER_NODES}”
echo “”

# Check if cluster already exists

if kind get clusters 2>/dev/null | grep -q “^${CLUSTER_NAME}$”; then
echo -e “${YELLOW}⚠️  Cluster ‘${CLUSTER_NAME}’ already exists${NC}”
read -p “Delete and recreate? (y/n) “ -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
echo -e “${BLUE}🗑️  Deleting existing cluster…${NC}”
kind delete cluster –name “${CLUSTER_NAME}”
else
echo -e “${GREEN}ℹ️  Using existing cluster${NC}”
kubectl cluster-info –context “kind-${CLUSTER_NAME}”
exit 0
fi
fi

# Create kind configuration file

echo -e “${BLUE}📝 Creating cluster configuration…${NC}”

cat > /tmp/kind-config.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: ${CLUSTER_NAME}

# Kubernetes version

nodes:

- role: control-plane
  image: kindest/node:${K8S_VERSION}@sha256:b7e1cf6b2b729f604133c667a6be8aab6f4dde5bb042c1891ae248d9154f665b
  
  # Port mappings for services (optional)
  
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
  
  # Increase resources for Crossplane
  
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
    kubeletExtraArgs:
    node-labels: “ingress-ready=true”

# Worker nodes for better resource distribution

$(for i in $(seq 1 $WORKER_NODES); do
echo “- role: worker”
echo “  image: kindest/node:${K8S_VERSION}@sha256:b7e1cf6b2b729f604133c667a6be8aab6f4dde5bb042c1891ae248d9154f665b”
done)

# Networking configuration

networking:

# Prevent port conflicts

apiServerAddress: “127.0.0.1”
apiServerPort: 6443

# Feature gates

featureGates:
“EphemeralContainers”: true

# Runtime configuration

containerdConfigPatches:

- |-
  [plugins.“io.containerd.grpc.v1.cri”.registry.mirrors.“localhost:5000”]
  endpoint = [“http://kind-registry:5000”]
  EOF

echo -e “${GREEN}✅ Configuration created${NC}”

# Create the cluster

echo “”
echo -e “${BLUE}🎬 Creating kind cluster (this takes 2-3 minutes)…${NC}”

if kind create cluster –config /tmp/kind-config.yaml; then
echo -e “${GREEN}✅ Cluster created successfully!${NC}”
else
echo -e “${RED}❌ Failed to create cluster${NC}”
rm -f /tmp/kind-config.yaml
exit 1
fi

# Clean up config file

rm -f /tmp/kind-config.yaml

# Set kubectl context

echo “”
echo -e “${BLUE}🎯 Setting kubectl context…${NC}”
kubectl cluster-info –context “kind-${CLUSTER_NAME}”

# Verify cluster

echo “”
echo -e “${BLUE}✅ Verifying cluster…${NC}”
kubectl get nodes

# Wait for nodes to be ready

echo “”
echo -e “${BLUE}⏳ Waiting for all nodes to be ready…${NC}”
kubectl wait –for=condition=ready nodes –all –timeout=300s

# Install metrics-server (optional but useful)

echo “”
read -p “Install metrics-server for resource monitoring? (y/n) “ -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
echo -e “${BLUE}📊 Installing metrics-server…${NC}”

kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Patch metrics-server for kind (disable TLS verification)

kubectl patch deployment metrics-server -n kube-system –type=‘json’   
-p=’[{“op”: “add”, “path”: “/spec/template/spec/containers/0/args/-”, “value”: “–kubelet-insecure-tls”}]’

echo -e “${GREEN}✅ metrics-server installed${NC}”
fi

# Install ingress-nginx (optional)

echo “”
read -p “Install ingress-nginx controller? (y/n) “ -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
echo -e “${BLUE}🌐 Installing ingress-nginx…${NC}”

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

echo -e “${BLUE}⏳ Waiting for ingress-nginx to be ready…${NC}”
kubectl wait –namespace ingress-nginx   
–for=condition=ready pod   
–selector=app.kubernetes.io/component=controller   
–timeout=300s

echo -e “${GREEN}✅ ingress-nginx installed${NC}”
fi

# Display cluster information

echo “”
echo “━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━”
echo -e “${GREEN}✅ kind cluster is ready!${NC}”
echo “━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━”
echo “”
echo -e “${BLUE}📊 Cluster Details:${NC}”
echo “   Name: ${CLUSTER_NAME}”
echo “   Context: kind-${CLUSTER_NAME}”
echo “   Nodes: $(kubectl get nodes –no-headers | wc -l)”
echo “”

# Show nodes with resource information

echo -e “${BLUE}🖥️  Nodes:${NC}”
kubectl get nodes -o wide

echo “”
echo -e “${BLUE}📝 Next steps:${NC}”
echo “1. Install Crossplane:”
echo “   ${YELLOW}./environments/kind/crossplane-install.sh${NC}”
echo “”
echo “2. Install Azure providers:”
echo “   ${YELLOW}./environments/kind/provider-install.sh${NC}”
echo “”
echo “3. Configure Azure credentials:”
echo “   Follow instructions in README.md”
echo “”
echo -e “${BLUE}🎛️  Useful commands:${NC}”
echo “   View logs:       ${YELLOW}kind export logs –name ${CLUSTER_NAME}${NC}”
echo “   Stop cluster:    ${YELLOW}docker stop ${CLUSTER_NAME}-control-plane${NC}”
echo “   Start cluster:   ${YELLOW}docker start ${CLUSTER_NAME}-control-plane${NC}”
echo “   Delete cluster:  ${YELLOW}kind delete cluster –name ${CLUSTER_NAME}${NC}”
echo “   Get kubeconfig:  ${YELLOW}kind get kubeconfig –name ${CLUSTER_NAME}${NC}”
echo “   Load image:      ${YELLOW}kind load docker-image <image> –name ${CLUSTER_NAME}${NC}”
echo “”

# kind vs Minikube comparison

echo -e “${BLUE}💡 kind vs Minikube:${NC}”
echo “   ✅ kind: Faster startup, lighter, better for CI/CD”
echo “   ✅ Minikube: More features, easier debugging, GUI dashboard”
echo “”
echo “   Current choice: kind”
echo “   To use Minikube instead: ./environments/minikube/setup.sh”
echo “”

# Show resource usage

echo -e “${BLUE}📈 Resource Usage:${NC}”
docker stats –no-stream –format “table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}”   
$(docker ps –filter “name=${CLUSTER_NAME}” –format “{{.Names}}”)

echo “”
echo -e “${GREEN}🎉 Setup complete! Happy testing!${NC}”
echo “”

# Optional: Create a local registry for faster image pulls

read -p “Create local Docker registry for faster image pulls? (y/n) “ -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
echo -e “${BLUE}📦 Creating local Docker registry…${NC}”

# Check if registry already exists

if docker ps -a –format ‘{{.Names}}’ | grep -q “^kind-registry$”; then
echo -e “${YELLOW}⚠️  Registry already exists${NC}”
else
# Create registry container
docker run -d   
–restart=always   
–name “kind-registry”   
-p “127.0.0.1:5001:5000”   
registry:2

```
# Connect registry to kind network
docker network connect "kind" "kind-registry" 2>/dev/null || true

echo -e "${GREEN}✅ Local registry created at localhost:5001${NC}"
echo ""
echo "   Push images: ${YELLOW}docker push localhost:5001/image:tag${NC}"
echo "   Use in k8s:  ${YELLOW}image: localhost:5001/image:tag${NC}"
```

fi
fi

echo “”
echo -e “${BLUE}🔍 Cluster Status:${NC}”
kubectl cluster-info
