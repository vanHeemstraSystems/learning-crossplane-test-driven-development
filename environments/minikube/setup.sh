#!/bin/bash

# Setup Minikube cluster for Crossplane TDD

# Usage: ./setup.sh

set -e

echo “🚀 Setting up Minikube for Crossplane TDD…”
echo “”

# Check if minikube is installed

if ! command -v minikube &> /dev/null; then
echo “❌ Minikube is not installed!”
echo “”
echo “Install with:”
echo “  # macOS”
echo “  brew install minikube”
echo “”
echo “  # Linux”
echo “  curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64”
echo “  sudo install minikube-linux-amd64 /usr/local/bin/minikube”
exit 1
fi

# Configuration

CLUSTER_NAME=“crossplane-tdd”
K8S_VERSION=“v1.28.0”
CPUS=4
MEMORY=8192
DISK_SIZE=“40g”

echo “📋 Cluster Configuration:”
echo “   Name: ${CLUSTER_NAME}”
echo “   Kubernetes: ${K8S_VERSION}”
echo “   CPUs: ${CPUS}”
echo “   Memory: ${MEMORY}MB”
echo “   Disk: ${DISK_SIZE}”
echo “”

# Check if cluster already exists

if minikube profile list | grep -q “${CLUSTER_NAME}”; then
echo “⚠️  Cluster ‘${CLUSTER_NAME}’ already exists”
read -p “Delete and recreate? (y/n) “ -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
echo “🗑️  Deleting existing cluster…”
minikube delete -p “${CLUSTER_NAME}”
else
echo “ℹ️  Using existing cluster”
minikube start -p “${CLUSTER_NAME}”
exit 0
fi
fi

# Start Minikube

echo “🎬 Starting Minikube cluster…”
minikube start   
-p “${CLUSTER_NAME}”   
–kubernetes-version=”${K8S_VERSION}”   
–cpus=”${CPUS}”   
–memory=”${MEMORY}”   
–disk-size=”${DISK_SIZE}”   
–driver=docker

# Enable addons

echo “🔌 Enabling addons…”
minikube addons enable metrics-server -p “${CLUSTER_NAME}”
minikube addons enable dashboard -p “${CLUSTER_NAME}”

# Set kubectl context

echo “🎯 Setting kubectl context…”
kubectl config use-context “${CLUSTER_NAME}”

# Verify cluster

echo “✅ Verifying cluster…”
kubectl cluster-info
kubectl get nodes

echo “”
echo “━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━”
echo “✅ Minikube cluster is ready!”
echo “━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━”
echo “”
echo “📝 Next steps:”
echo “1. Install Crossplane: ./crossplane-install.sh”
echo “2. Install providers: ./provider-install.sh”
echo “3. Configure credentials: Follow README.md”
echo “”
echo “🎛️  Useful commands:”
echo “   View dashboard:  minikube dashboard -p ${CLUSTER_NAME}”
echo “   Stop cluster:    minikube stop -p ${CLUSTER_NAME}”
echo “   Delete cluster:  minikube delete -p ${CLUSTER_NAME}”
echo “   SSH to cluster:  minikube ssh -p ${CLUSTER_NAME}”
