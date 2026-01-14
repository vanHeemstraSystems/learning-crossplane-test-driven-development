# Tooling Guide for Crossplane TDD

> Essential tools for testing Crossplane infrastructure

## 📋 Overview

This guide covers all tools used in the Crossplane TDD workflow, from YAML validation to end-to-end testing. Each tool serves a specific purpose in the testing pyramid.

## 🛠️ Core Tools

### 1. yq - YAML Processor

**Purpose:** Parse, validate, and manipulate YAML files

**Installation:**

```bash
# macOS
brew install yq

# Linux
wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
sudo install yq_linux_amd64 /usr/local/bin/yq

# Verify
yq --version
# yq (https://github.com/mikefarah/yq/) version v4.35.2
```

**Common Use Cases:**

**Validate YAML syntax:**

```bash
yq eval 'explode(.)' file.yaml > /dev/null && echo "Valid YAML"
```

**Extract specific fields:**

```bash
# Get deletion policy
yq eval '.spec.resources[].base.spec.deletionPolicy' composition.yaml

# Get all resource names
yq eval '.spec.resources[].name' composition.yaml

# Get size enum values
yq eval '.spec.versions[0].schema.openAPIV3Schema.properties.spec.properties.size.enum[]' xrd.yaml
```

**Modify YAML:**

```bash
# Add deletion policy to all resources
yq eval '.spec.resources[] |= .base.spec.deletionPolicy = "Delete"' \
  -i composition.yaml

# Update database version
yq eval '.spec.resources[] | 
  select(.name == "database") | 
  .base.spec.forProvider.version = "15"' \
  -i composition.yaml

# Add tags
yq eval '.spec.resources[] |= 
  .base.spec.forProvider.tags.ManagedBy = "Crossplane"' \
  -i composition.yaml
```

**Generate YAML from templates:**

```bash
# Replace placeholders
APP_NAME="myapp" \
SIZE="medium" \
yq eval '
  .metadata.name = env(APP_NAME) |
  .spec.size = env(SIZE)
' template.yaml > output.yaml
```

**Tips:**

- Use `eval` for all operations
- Use `explode(.)` to validate syntax
- Use `-i` flag to modify in-place
- Use `env()` to access environment variables
- Pipe through `yq` multiple times for complex transformations

### 2. kubectl - Kubernetes CLI

**Purpose:** Interact with Kubernetes API, validate resources

**Installation:**

```bash
# macOS
brew install kubectl

# Linux
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install kubectl /usr/local/bin/kubectl

# Verify
kubectl version --client
```

**Key Testing Commands:**

**Dry-run validation:**

```bash
# Validate XRD without creating it
kubectl apply --dry-run=server -f xrd.yaml

# Validate composition
kubectl apply --dry-run=client -f composition.yaml

# Check if file would be accepted
kubectl create --dry-run=server -f claim.yaml
```

**Resource inspection:**

```bash
# Get claims
kubectl get developercombo

# Describe for details
kubectl describe developercombo myapp-dev

# Get managed resources
kubectl get managed

# Filter by composite
kubectl get managed -l crossplane.io/composite=myapp-dev
```

**Status checking:**

```bash
# Wait for ready
kubectl wait --for=condition=ready \
  developercombo/myapp-dev --timeout=15m

# Get status conditions
kubectl get developercombo myapp-dev \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")]}'

# Get endpoint
kubectl get developercombo myapp-dev \
  -o jsonpath='{.status.endpoint}'
```

**Debugging:**

```bash
# View events
kubectl get events --sort-by='.lastTimestamp'

# Filter events for specific resource
kubectl get events --field-selector involvedObject.name=myapp-dev

# Get Crossplane logs
kubectl logs -n crossplane-system deployment/crossplane -f

# Get provider logs
kubectl logs -n crossplane-system \
  -l pkg.crossplane.io/provider=provider-azure-storage
```

### 3. conftest - Policy Testing (OPA)

**Purpose:** Test configurations against policies

**Installation:**

```bash
# macOS
brew install conftest

# Linux
curl -L https://github.com/open-policy-agent/conftest/releases/latest/download/conftest_Linux_x86_64.tar.gz | tar xz
sudo mv conftest /usr/local/bin

# Verify
conftest --version
```

**Policy Structure:**

```
tools/conftest/policy/
├── crossplane.rego          # Main policies
├── security.rego            # Security policies
├── naming.rego              # Naming conventions
└── compliance.rego          # Compliance rules
```

**Writing Policies:**

**Example 1: Require deletion policy**

```rego
# tools/conftest/policy/deletion-policy.rego
package crossplane.composition

deny[msg] {
  input.kind == "Composition"
  resource := input.spec.resources[_]
  not resource.base.spec.deletionPolicy
  
  msg := sprintf(
    "Resource '%s' missing deletionPolicy",
    [resource.name]
  )
}
```

**Example 2: Validate tags**

```rego
# tools/conftest/policy/tags.rego
package crossplane.composition

required_tags := ["ManagedBy", "Environment", "Owner"]

deny[msg] {
  input.kind == "Composition"
  resource := input.spec.resources[_]
  
  missing_tag := required_tags[_]
  not resource.base.spec.forProvider.tags[missing_tag]
  
  msg := sprintf(
    "Resource '%s' missing required tag: %s",
    [resource.name, missing_tag]
  )
}
```

**Running Tests:**

```bash
# Test single file
conftest test composition.yaml

# Test with specific policy
conftest test -p tools/conftest/policy/deletion-policy.rego \
  composition.yaml

# Test all compositions
conftest test crossplane/compositions/ --all-namespaces

# Show detailed trace
conftest test --trace composition.yaml

# Output as JSON
conftest test -o json composition.yaml
```

**Best Practices:**

- One policy per file
- Clear error messages
- Use `deny` for errors, `warn` for warnings
- Group related policies in packages
- Test policies themselves with example data

### 4. kubeconform - Schema Validation

**Purpose:** Validate Kubernetes resources against OpenAPI schemas

**Installation:**

```bash
# macOS
brew install kubeconform

# Linux
wget https://github.com/yannh/kubeconform/releases/latest/download/kubeconform-linux-amd64.tar.gz
tar xf kubeconform-linux-amd64.tar.gz
sudo mv kubeconform /usr/local/bin

# Verify
kubeconform -v
```

**Usage:**

```bash
# Validate XRD
kubeconform -strict xrd.yaml

# Validate composition
kubeconform -strict composition.yaml

# Validate with specific Kubernetes version
kubeconform -kubernetes-version 1.28.0 xrd.yaml

# Validate all files in directory
kubeconform -strict crossplane/

# Output summary
kubeconform -summary crossplane/
```

### 5. chainsaw - E2E Testing Framework

**Purpose:** End-to-end testing for Kubernetes operators

**Installation:**

```bash
# macOS
brew install kyverno/chainsaw/chainsaw

# Linux
curl -L https://github.com/kyverno/chainsaw/releases/latest/download/chainsaw-linux-amd64.tar.gz | tar xz
sudo mv chainsaw /usr/local/bin

# Verify
chainsaw version
```

**Test Structure:**

```yaml
apiVersion: chainsaw.kyverno.io/v1alpha1
kind: Test
metadata:
  name: developer-combo-test
spec:
  steps:
  # Step 1: Create
  - name: create-claim
    try:
    - apply:
        file: claim.yaml
    - assert:
        resource:
          apiVersion: example.com/v1alpha1
          kind: DeveloperCombo
          status:
            conditions:
            - type: Ready
              status: "True"
        timeout: 15m
  
  # Step 2: Verify
  - name: verify-database
    try:
    - assert:
        resource:
          apiVersion: dbforpostgresql.azure.upbound.io/v1beta1
          kind: FlexibleServer
          spec:
            forProvider:
              skuName: B_Standard_B1ms
        timeout: 1m
  
  # Step 3: Cleanup
  - name: delete-claim
    try:
    - delete:
        ref:
          apiVersion: example.com/v1alpha1
          kind: DeveloperCombo
          name: test-combo
```

**Running Tests:**

```bash
# Run single test
chainsaw test --test-file tests/e2e/developer-combo-test.yaml

# Run all tests in directory
chainsaw test --test-dir tests/e2e/

# Run with specific namespace
chainsaw test --namespace test-env

# Skip cleanup
chainsaw test --no-cleanup

# Verbose output
chainsaw test -v 4
```

**Tips:**

- Use timeouts generously (Azure is slow)
- Clean up in test steps, not just at end
- Use unique names per test run
- Assert on status conditions, not just existence

### 6. Helm - Package Manager

**Purpose:** Install Crossplane and manage releases

**Installation:**

```bash
# macOS
brew install helm

# Linux
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify
helm version
```

**Common Commands:**

```bash
# Add Crossplane repo
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update

# Install Crossplane
helm install crossplane crossplane-stable/crossplane \
  --namespace crossplane-system \
  --create-namespace \
  --wait

# Upgrade Crossplane
helm upgrade crossplane crossplane-stable/crossplane \
  --namespace crossplane-system

# Check status
helm status crossplane -n crossplane-system

# List releases
helm list -n crossplane-system

# Uninstall
helm uninstall crossplane -n crossplane-system
```

### 7. Minikube - Local Kubernetes

**Purpose:** Local Kubernetes cluster for testing

**Installation:**

```bash
# macOS
brew install minikube

# Linux
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Verify
minikube version
```

**Cluster Management:**

```bash
# Start cluster
minikube start -p crossplane-tdd \
  --kubernetes-version=v1.28.0 \
  --cpus=4 \
  --memory=8192

# Stop cluster
minikube stop -p crossplane-tdd

# Delete cluster
minikube delete -p crossplane-tdd

# SSH into cluster
minikube ssh -p crossplane-tdd

# View dashboard
minikube dashboard -p crossplane-tdd
```

**Addons:**

```bash
# Enable metrics
minikube addons enable metrics-server -p crossplane-tdd

# Enable ingress
minikube addons enable ingress -p crossplane-tdd

# List addons
minikube addons list -p crossplane-tdd
```

## 🔧 Development Tools

### VS Code Extensions

**Recommended Extensions:**

```json
{
  "recommendations": [
    "redhat.vscode-yaml",           // YAML support
    "ms-kubernetes-tools.vscode-kubernetes-tools", // K8s tools
    "tsandall.opa",                 // OPA/Rego support
    "GitHub.copilot",               // AI assistance
    "eamodio.gitlens"               // Git tools
  ]
}
```

**Workspace Settings:**

```json
{
  "yaml.schemas": {
    "https://json.schemastore.org/kustomization": "kustomization.yaml",
    "https://raw.githubusercontent.com/crossplane/crossplane/master/cluster/crds/*.yaml": "crossplane/*.yaml"
  },
  "yaml.customTags": [
    "!Ref scalar",
    "!Sub scalar"
  ],
  "files.associations": {
    "*.rego": "rego"
  }
}
```

### Git Hooks

**Pre-commit Hook:**

```bash
#!/bin/bash
# .git/hooks/pre-commit

echo "Running pre-commit checks..."

# Run unit tests
./scripts/test/run-unit-tests.sh || {
  echo "❌ Unit tests failed"
  exit 1
}

# Run policy tests
./scripts/validate/validate-policies.sh || {
  echo "❌ Policy tests failed"
  exit 1
}

echo "✅ Pre-commit checks passed"
```

**Pre-push Hook:**

```bash
#!/bin/bash
# .git/hooks/pre-push

echo "Running pre-push checks..."

# Run integration tests (optional, can be slow)
if [ "$SKIP_INTEGRATION" != "true" ]; then
  ./scripts/test/run-integration-tests.sh || {
    echo "❌ Integration tests failed"
    echo "To skip: SKIP_INTEGRATION=true git push"
    exit 1
  }
fi

echo "✅ Pre-push checks passed"
```

## 📊 Monitoring & Observability

### Crossplane Metrics

**Prometheus Queries:**

```promql
# Reconciliation rate
rate(crossplane_reconcile_total[5m])

# Reconciliation errors
rate(crossplane_reconcile_errors_total[5m])

# Reconciliation duration
histogram_quantile(0.95, 
  rate(crossplane_reconcile_duration_seconds_bucket[5m])
)

# Managed resources
crossplane_managed_resources
```

**Grafana Dashboard:**

- Import dashboard ID: 14371 (Crossplane Overview)
- Customize for your XRDs
- Add alerts for failures

### Logging

**Structured Logging:**

```bash
# View Crossplane logs in JSON
kubectl logs -n crossplane-system deployment/crossplane \
  --tail=100 -f | jq '.'

# Filter for errors
kubectl logs -n crossplane-system deployment/crossplane \
  --tail=1000 | jq 'select(.level == "error")'

# Filter by controller
kubectl logs -n crossplane-system deployment/crossplane \
  --tail=1000 | jq 'select(.controller == "composite/xdevelopercombo.example.com")'
```

## 🚀 CI/CD Integration

### GitHub Actions

**Install Tools:**

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Install yq
      run: |
        sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq
        sudo chmod +x /usr/bin/yq
    
    - name: Install conftest
      run: |
        curl -L https://github.com/open-policy-agent/conftest/releases/latest/download/conftest_Linux_x86_64.tar.gz | tar xz
        sudo mv conftest /usr/local/bin
    
    - name: Install kubectl
      uses: azure/setup-kubectl@v3
      with:
        version: 'v1.28.0'
    
    - name: Run tests
      run: ./scripts/test/run-unit-tests.sh
```

### GitLab CI

**Tool Installation:**

```yaml
before_script:
  - apt-get update
  - apt-get install -y curl wget
  
  # Install yq
  - wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq
  - chmod +x /usr/bin/yq
  
  # Install conftest
  - curl -L https://github.com/open-policy-agent/conftest/releases/latest/download/conftest_Linux_x86_64.tar.gz | tar xz
  - mv conftest /usr/local/bin

test:
  script:
    - ./scripts/test/run-unit-tests.sh
```

## 📚 Tool Comparison

### Schema Validation

|Tool            |Speed|Coverage       |Accuracy |
|----------------|-----|---------------|---------|
|yq              |⚡⚡⚡  |YAML only      |High     |
|kubeconform     |⚡⚡   |K8s resources  |Very High|
|kubectl –dry-run|⚡    |Full validation|Highest  |

**Recommendation:** Use all three in sequence:

1. yq for syntax
1. kubeconform for schema
1. kubectl for API validation

### Policy Testing

|Tool        |Language|Learning Curve|Flexibility|
|------------|--------|--------------|-----------|
|conftest    |Rego    |Medium        |Very High  |
|kyverno     |YAML    |Low           |High       |
|bash scripts|Bash    |Low           |Medium     |

**Recommendation:**

- Start with bash scripts for simple checks
- Use conftest for complex policies
- Consider kyverno for runtime policies

### E2E Testing

|Tool        |Features         |Complexity|Kubernetes-Native|
|------------|-----------------|----------|-----------------|
|chainsaw    |Rich assertions  |Medium    |Yes              |
|kuttl       |Simple, effective|Low       |Yes              |
|bash scripts|Full control     |High      |No               |

**Recommendation:**

- Use chainsaw for operator-like testing
- Use kuttl for simpler scenarios
- Use bash for custom workflows

## 🎯 Tool Selection Guide

### For Your Project Size

**Small Project (1-5 XRDs):**

- yq + kubectl + bash scripts
- Manual testing acceptable
- Minimal tooling overhead

**Medium Project (5-20 XRDs):**

- yq + kubectl + conftest
- chainsaw for E2E
- Automated testing critical

**Large Project (20+ XRDs):**

- Full toolchain
- Custom test framework
- Dedicated test infrastructure

## 💡 Pro Tips

### yq Pro Tips

```bash
# Use aliases for common operations
alias yq-validate='yq eval "explode(.)"'
alias yq-get='yq eval'
alias yq-set='yq eval -i'

# Create reusable functions
yq-add-deletion-policy() {
  yq eval '.spec.resources[] |= 
    .base.spec.deletionPolicy = "Delete"' -i "$1"
}
```

### kubectl Pro Tips

```bash
# Use aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kd='kubectl describe'
alias kl='kubectl logs'

# Custom output formats
kubectl get developercombo -o custom-columns=\
  NAME:.metadata.name,\
  READY:.status.conditions[0].status,\
  ENDPOINT:.status.endpoint
```

### conftest Pro Tips

```bash
# Test policies themselves
conftest verify -p tools/conftest/policy/

# Create test data
mkdir -p tools/conftest/testdata/
# Add example valid and invalid files

# Run policy tests in CI
conftest test --all-namespaces crossplane/
```

-----

**Remember:** Tools are meant to help, not hinder. Start simple, add complexity only when needed, and always optimize for developer experience.

**“Use the right tool for the job.”** 🛠️
