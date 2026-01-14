# Getting Started with Crossplane TDD

> A step-by-step guide to start your Crossplane Test-Driven Development journey

## 🎯 What You’ll Learn

By following this guide, you’ll:

- Set up a complete Crossplane development environment
- Understand the TDD workflow for infrastructure
- Deploy your first tested Developer Combo
- Run all three levels of tests (unit, integration, E2E)

## ⏱️ Time Required

- **Quick start** (minimal testing): 30 minutes
- **Full TDD workflow** (with all tests): 2-3 hours
- **Deep learning** (including experimentation): 1-2 days

## 📋 Prerequisites Checklist

Before starting, ensure you have:

- [ ] **Minikube** v1.32+ installed
- [ ] **kubectl** v1.28+ installed
- [ ] **Helm** v3.12+ installed
- [ ] **yq** v4.35+ installed
- [ ] **Azure CLI** installed (for Azure provider)
- [ ] **Azure subscription** with Contributor access
- [ ] **Optional:** conftest, chainsaw (for advanced testing)

### Installation Commands

```bash
# macOS
brew install minikube kubectl helm yq azure-cli

# Linux (Ubuntu/Debian)
# Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install kubectl /usr/local/bin/kubectl

# Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# yq
wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O yq
sudo install yq /usr/local/bin/yq

# Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

## 🚀 Quick Start (30 minutes)

### Step 1: Clone and Setup (5 minutes)

```bash
# Clone the repository
git clone https://github.com/vanHeemstraSystems/learning-crossplane-test-driven-development.git
cd learning-crossplane-test-driven-development

# Make scripts executable
chmod +x environments/minikube/*.sh
chmod +x scripts/**/*.sh
```

### Step 2: Start Minikube Cluster (5 minutes)

```bash
# Start Minikube with Crossplane-optimized settings
./environments/minikube/setup.sh

# Verify cluster is running
kubectl cluster-info
kubectl get nodes
```

Expected output:

```
✅ Minikube cluster is ready!
NAME                 STATUS   ROLES           AGE   VERSION
crossplane-tdd       Ready    control-plane   1m    v1.28.0
```

### Step 3: Install Crossplane (5 minutes)

```bash
# Install Crossplane and core functions
./environments/minikube/crossplane-install.sh

# Verify installation
kubectl get pods -n crossplane-system
```

Expected output:

```
NAME                                       READY   STATUS    RESTARTS   AGE
crossplane-7d4c5f5f5d-xxxxx               1/1     Running   0          2m
crossplane-rbac-manager-xxxxxxxxx-xxxxx   1/1     Running   0          2m
```

### Step 4: Install Azure Providers (5 minutes)

```bash
# Install all Azure providers
./environments/minikube/provider-install.sh

# Wait for providers to be healthy (this takes a few minutes)
kubectl get providers

# Expected output after a few minutes:
# NAME                              INSTALLED   HEALTHY   PACKAGE
# provider-azure                    True        True      xpkg.upbound.io/...
# provider-azure-storage            True        True      xpkg.upbound.io/...
# provider-azure-dbforpostgresql    True        True      xpkg.upbound.io/...
# provider-azure-network            True        True      xpkg.upbound.io/...
```

### Step 5: Configure Azure Credentials (5 minutes)

```bash
# Login to Azure
az login

# Create Service Principal
az ad sp create-for-rbac \
  --name crossplane-sp-$(date +%s) \
  --role Contributor \
  --scopes /subscriptions/$(az account show --query id -o tsv) \
  --sdk-auth

# Copy the output JSON
```

Create the Kubernetes secret with your credentials:

```bash
kubectl create secret generic azure-credentials \
  -n crossplane-system \
  --from-literal=credentials='{
    "clientId": "YOUR_CLIENT_ID",
    "clientSecret": "YOUR_CLIENT_SECRET",
    "subscriptionId": "YOUR_SUBSCRIPTION_ID",
    "tenantId": "YOUR_TENANT_ID"
  }'
```

Apply ProviderConfig:

```bash
kubectl apply -f crossplane/providers/providerconfig-azure.yaml
```

### Step 6: Deploy Your First Developer Combo (5 minutes)

```bash
# Apply XRD (the menu)
kubectl apply -f crossplane/xrds/developer-combo/xrd.yaml

# Apply Composition (the recipe)
kubectl apply -f crossplane/compositions/developer-combo/azure-composition.yaml

# Create a small combo (the order)
kubectl apply -f crossplane/xrds/developer-combo/examples/small-claim.yaml

# Watch it cook!
kubectl get developercombo --watch
```

Expected progression:

```
NAME        READY   ENDPOINT   AGE
myapp-dev   False              10s
myapp-dev   False              30s
myapp-dev   True    db.postgres.database.azure.com   10m
```

🎉 **Congratulations!** You’ve deployed your first infrastructure using Crossplane!

## 🧪 Full TDD Workflow (2-3 hours)

### Phase 1: Unit Tests (15 minutes)

Run pre-deployment tests that don’t require a cluster:

```bash
# Run all unit tests
./scripts/test/run-unit-tests.sh
```

This tests:

- ✅ YAML syntax validation
- ✅ Schema structure
- ✅ Composition resources
- ✅ Policy compliance
- ✅ Patching logic
- ✅ Deletion policies

Expected output:

```
📊 Unit Test Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Passed:  25
Failed:  0
Skipped: 0

Success rate: 100%
✅ All unit tests passed!
```

### Phase 2: Integration Tests (30-60 minutes)

Test actual resource creation in Azure:

```bash
# Run integration test for small combo
./scripts/test/run-integration-tests.sh developer-combo small

# Test medium combo
./scripts/test/run-integration-tests.sh developer-combo medium

# Test large combo  
./scripts/test/run-integration-tests.sh developer-combo large
```

These tests:

- Create actual Azure resources
- Verify correct SKU based on size
- Check status conditions
- Validate endpoints
- Clean up resources

**Note:** Each test takes 10-15 minutes for Azure resources to provision.

### Phase 3: End-to-End Tests (60-90 minutes)

Test complete lifecycle:

```bash
# Run full E2E test
./scripts/test/run-e2e-tests.sh
```

This tests:

1. **Create** - Deploy small combo
1. **Update** - Upgrade to medium
1. **Delete** - Clean up all resources

Expected output:

```
📊 End-to-End Test Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Phase 1 - Create:  PASS
Phase 2 - Update:  PASS
Phase 3 - Delete:  PASS

✅ All E2E tests PASSED!
🎉 Your Crossplane TDD setup is working perfectly!
```

### Phase 4: TDD Workflow Automation (30 minutes)

Run the complete TDD cycle:

```bash
./scripts/test/tdd-workflow.sh
```

This demonstrates:

- 🔴 **RED** - Write failing tests
- 🟢 **GREEN** - Make tests pass
- 🔵 **REFACTOR** - Improve implementation

## 📚 Learning Path

### Week 1: Foundation

- [ ] Complete Quick Start
- [ ] Read “Fast Food Infrastructure” article
- [ ] Understand XRD → Composition → Claim flow
- [ ] Deploy all three sizes (small/medium/large)
- [ ] Review related repos:
  - [learning-crossplane](https://github.com/vanHeemstraSystems/learning-crossplane)
  - [learning-test-driven-development](https://github.com/vanHeemstraSystems/learning-test-driven-development)

### Week 2: Testing Mastery

- [ ] Install conftest: `brew install conftest`
- [ ] Write custom policies in `tools/conftest/policy/`
- [ ] Practice YQ generation scripts
- [ ] Create custom XRD for your use case
- [ ] Run unit tests after each change

### Week 3: Integration Testing

- [ ] Install chainsaw: Follow [chainsaw docs](https://kyverno.github.io/chainsaw/)
- [ ] Write integration tests for your XRD
- [ ] Test failure scenarios
- [ ] Practice debugging with `kubectl describe`

### Week 4: Production Ready

- [ ] Build multi-environment setup (dev/staging/prod)
- [ ] Implement GitOps with ArgoCD/Flux
- [ ] Add monitoring and observability
- [ ] Create CI/CD pipeline
- [ ] Document your compositions

## 🎓 Understanding the Fast Food Metaphor

Throughout this repository, we use a fast food restaurant metaphor:

|Crossplane          |Fast Food      |What It Does                    |
|--------------------|---------------|--------------------------------|
|**XRD**             |Menu Board     |Defines what customers can order|
|**Composition**     |Recipe Card    |Instructions for the kitchen    |
|**Claim**           |Customer Order |“I’ll have a medium combo”      |
|**XR**              |Completed Meal |All items on the tray           |
|**Provider**        |Kitchen Station|Azure, AWS, GCP cooking stations|
|**Managed Resource**|Food Items     |Burger, fries, drink            |
|**ProviderConfig**  |Kitchen Keys   |Credentials to access equipment |

Example conversation:

- Customer: “I’d like a medium Developer Combo”
- Counter: Creates a Claim
- Kitchen: Reads the Composition recipe
- Grill Station: Cooks the burger (Database)
- Fryer Station: Makes the fries (Storage)
- Drink Station: Fills the cup (Network)
- Counter: Assembles on tray (Resource Group)
- Customer: Picks up ready meal! 🍔🍟🥤

## 🔧 Useful Commands

### Development

```bash
# Generate new XRD
./scripts/generate/generate-xrd.sh mycombo

# Generate composition
./scripts/generate/generate-composition.sh mycombo azure

# Generate claim
./scripts/generate/generate-claim.sh myapp dev small

# Validate policies
./scripts/validate/validate-policies.sh
```

### Debugging

```bash
# Check claim status
kubectl get developercombo <name> -n <namespace>

# Describe claim for details
kubectl describe developercombo <name> -n <namespace>

# Get composite resource
kubectl get xdevelopercombo

# List all managed resources
kubectl get managed

# Check provider logs
kubectl logs -n crossplane-system -l pkg.crossplane.io/provider=provider-azure-storage

# View Crossplane events
kubectl get events -n crossplane-system --sort-by='.lastTimestamp'
```

### Cleanup

```bash
# Delete a claim
kubectl delete developercombo <name> -n <namespace>

# Delete all claims in namespace
kubectl delete developercombo --all -n <namespace>

# Reset entire cluster
minikube delete -p crossplane-tdd
```

## ❓ Troubleshooting

### “Provider not healthy”

```bash
# Check provider status
kubectl get providers

# View provider logs
kubectl logs -n crossplane-system deployment/provider-azure-storage

# Reinstall if needed
kubectl delete provider provider-azure-storage
kubectl apply -f crossplane/providers/provider-azure-storage.yaml
```

### “Claim stuck in Not Ready”

```bash
# Check composite resource
kubectl get xdevelopercombo

# Check managed resources
kubectl get managed

# Look for errors
kubectl describe developercombo <name>

# Common issues:
# 1. Invalid Azure credentials
# 2. Azure quota exceeded  
# 3. Region not supported
# 4. Provider not healthy
```

### “Resources not created”

```bash
# Verify ProviderConfig
kubectl get providerconfig

# Check credentials secret exists
kubectl get secret azure-credentials -n crossplane-system

# Verify providers are installed
kubectl get providers
```

## 📖 Additional Resources

### Documentation

- [Crossplane Documentation](https://docs.crossplane.io/)
- [Upbound Provider Docs](https://marketplace.upbound.io/)
- [Fast Food Infrastructure Article](https://dev.to/the-software-s-journey/fast-infrastructure-understanding-crossplane-like-a-fast-food-restaurant-1ikk)

### Tools

- [conftest](https://www.conftest.dev/) - Policy testing
- [chainsaw](https://kyverno.github.io/chainsaw/) - E2E testing
- [yq](https://github.com/mikefarah/yq) - YAML processor

### Community

- [Crossplane Slack](https://slack.crossplane.io/)
- [Crossplane GitHub](https://github.com/crossplane/crossplane)
- [Upbound Community](https://www.upbound.io/community)

## 🎯 Next Steps

After completing this guide:

1. **Customize** - Create your own XRDs and Compositions
1. **Expand** - Add more providers (AWS, GCP)
1. **Integrate** - Set up GitOps with ArgoCD
1. **Share** - Contribute back to the community

-----

**Happy Testing! 🎉 May your infrastructure be as reliable as a combo meal!**
