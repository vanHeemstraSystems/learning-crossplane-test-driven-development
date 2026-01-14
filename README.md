# Learning Crossplane Test-Driven Development

> A systematic approach to testing Crossplane infrastructure-as-code using the Fast Food Restaurant metaphor

[![.github/workflows/ci.yml](https://github.com/vanHeemstraSystems/learning-crossplane-test-driven-development/actions/workflows/ci.yml/badge.svg)](https://github.com/vanHeemstraSystems/learning-crossplane-test-driven-development/actions/workflows/ci.yml)
[![Crossplane](https://img.shields.io/badge/Crossplane-v2.x-blue)](https://crossplane.io/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.28+-green)](https://kubernetes.io/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## 📚 Related Repositories

This repository is part of a learning series:

- **[learning-crossplane](https://github.com/vanHeemstraSystems/learning-crossplane)** - Core Crossplane concepts and fundamentals
- **[learning-test-driven-development](https://github.com/vanHeemstraSystems/learning-test-driven-development)** - TDD principles and practices
- **This Repository** - Applying TDD to Crossplane infrastructure

## 🎯 Purpose

Learn how to apply Test-Driven Development (TDD) principles to Crossplane infrastructure provisioning, ensuring reliable, maintainable, and well-tested infrastructure-as-code. We use the **Fast Food Restaurant metaphor** from [this article](https://dev.to/the-software-s-journey/fast-infrastructure-understanding-crossplane-like-a-fast-food-restaurant-1ikk) to make concepts easier to understand.

## 🍔 The Fast Food Metaphor

|Crossplane Concept     |Fast Food Metaphor        |What We Test                       |
|-----------------------|--------------------------|-----------------------------------|
|XRD                    |Menu Board                |Schema validation, API contract    |
|Composition            |Recipe Card               |Resource creation, patching logic  |
|Claim                  |Customer Order            |Input validation, user experience  |
|Composite Resource (XR)|Completed Meal            |End-to-end integration             |
|Provider               |Kitchen Station           |Provider configuration, credentials|
|Managed Resource       |Food Items (burger, fries)|Individual resource properties     |

## 🏗️ Repository Structure

```
learning-crossplane-test-driven-development/
├── README.md                           # This file
├── docs/
│   ├── 01-tdd-principles.md           # TDD fundamentals for infrastructure
│   ├── 02-testing-strategy.md         # Overall testing approach
│   ├── 03-tooling.md                  # Tools and their usage
│   └── 04-best-practices.md           # Patterns and anti-patterns
│
├── environments/
│   ├── minikube/
│   │   ├── setup.sh                   # Minikube cluster setup
│   │   ├── crossplane-install.sh      # Crossplane installation
│   │   └── provider-install.sh        # Azure providers
│   └── kind/                          # Alternative: kind cluster
│       └── setup.sh
│
├── scripts/
│   ├── generate/                      # YQ-based YAML generators
│   │   ├── generate-xrd.sh
│   │   ├── generate-composition.sh
│   │   └── generate-claim.sh
│   ├── validate/                      # Pre-deployment validation
│   │   ├── validate-schema.sh
│   │   ├── validate-policies.sh
│   │   └── validate-with-conftest.sh
│   └── test/                          # Test execution scripts
│       ├── run-unit-tests.sh
│       ├── run-integration-tests.sh
│       └── run-e2e-tests.sh
│
├── tests/
│   ├── unit/                          # Unit-level tests
│   │   ├── xrd/
│   │   │   ├── test-schema-validation.yaml
│   │   │   └── test-required-fields.yaml
│   │   ├── composition/
│   │   │   ├── test-patching-logic.yaml
│   │   │   └── test-resource-naming.yaml
│   │   └── policies/
│   │       ├── deletion-policy.rego
│   │       ├── naming-convention.rego
│   │       └── security-baseline.rego
│   │
│   ├── integration/                   # Integration tests
│   │   ├── developer-combo/
│   │   │   ├── test-small-combo.yaml
│   │   │   ├── test-medium-combo.yaml
│   │   │   └── test-large-combo.yaml
│   │   └── assertions/
│   │       ├── assert-resources-created.yaml
│   │       └── assert-status-conditions.yaml
│   │
│   └── e2e/                           # End-to-end tests
│       ├── scenarios/
│       │   ├── full-lifecycle.yaml    # Create → Update → Delete
│       │   ├── multi-environment.yaml # Dev → Staging → Prod
│       │   └── failure-recovery.yaml  # Error handling
│       └── chainsaw/
│           └── developer-combo-test.yaml
│
├── crossplane/
│   ├── providers/                     # Provider configurations
│   │   ├── provider-azure-storage.yaml
│   │   ├── provider-azure-sql.yaml
│   │   ├── provider-azure-network.yaml
│   │   └── providerconfig-azure.yaml
│   │
│   ├── xrds/                          # Composite Resource Definitions (The Menu)
│   │   ├── developer-combo/
│   │   │   ├── xrd.yaml
│   │   │   └── examples/
│   │   │       ├── small-claim.yaml
│   │   │       ├── medium-claim.yaml
│   │   │       └── large-claim.yaml
│   │   └── application-stack/
│   │       └── xrd.yaml
│   │
│   ├── compositions/                  # Compositions (The Recipes)
│   │   ├── developer-combo/
│   │   │   ├── azure-composition.yaml
│   │   │   └── README.md
│   │   └── application-stack/
│   │       └── composition.yaml
│   │
│   └── claims/                        # Example claims (Customer Orders)
│       ├── dev/
│       │   └── myapp-dev-combo.yaml
│       ├── staging/
│       │   └── myapp-staging-combo.yaml
│       └── prod/
│           └── myapp-prod-combo.yaml
│
├── templates/                         # YQ templates for generation
│   ├── xrd-template.yaml
│   ├── composition-template.yaml
│   └── claim-template.yaml
│
└── tools/
    ├── conftest/
    │   └── policy/
    │       └── crossplane.rego
    ├── kyverno/
    │   └── policies/
    │       └── crossplane-policies.yaml
    └── chainsaw/
        └── config.yaml
```

## 🚀 Quick Start

### Prerequisites

- **Minikube** v1.32+ (or kind/k3d)
- **kubectl** v1.28+
- **yq** v4.35+
- **helm** v3.12+
- **conftest** (for policy testing)
- **crossplane CLI** (optional but recommended)
- **Azure CLI** (for Azure provider)

### 1. Setup Environment

```bash
# Clone this repository
git clone https://github.com/vanHeemstraSystems/learning-crossplane-test-driven-development.git
cd learning-crossplane-test-driven-development

# Start Minikube cluster
./environments/minikube/setup.sh

# Install Crossplane
./environments/minikube/crossplane-install.sh

# Install Azure providers
./environments/minikube/provider-install.sh
```

### 2. Configure Azure Credentials

```bash
# Create Azure Service Principal
az ad sp create-for-rbac \
  --name crossplane-sp \
  --role Contributor \
  --scopes /subscriptions/YOUR_SUBSCRIPTION_ID

# Create Kubernetes secret
kubectl create secret generic azure-credentials \
  -n crossplane-system \
  --from-literal=credentials='{"clientId": "your-client-id",
  "clientSecret": "your-client-secret",
  "subscriptionId": "your-subscription-id",
  "tenantId": "your-tenant-id"}'

# Apply ProviderConfig
kubectl apply -f crossplane/providers/providerconfig-azure.yaml
```

### 3. Run Your First Test

```bash
# Validate XRD schema
./scripts/validate/validate-schema.sh crossplane/xrds/developer-combo/xrd.yaml

# Run policy tests
./scripts/validate/validate-policies.sh

# Deploy and test a Developer Combo
kubectl apply -f crossplane/xrds/developer-combo/xrd.yaml
kubectl apply -f crossplane/compositions/developer-combo/azure-composition.yaml
kubectl apply -f crossplane/xrds/developer-combo/examples/small-claim.yaml

# Watch the reconciliation
kubectl get developercombo --watch
```

## 🧪 Testing Strategy

### Level 1: Schema Validation (Pre-deployment)

**What**: Validate YAML structure and OpenAPI schemas
**When**: Before committing to Git
**Tools**: `yq`, `kubectl --dry-run`, `kubeconform`

```bash
# Example: Validate XRD schema
yq eval '.spec.versions[0].schema.openAPIV3Schema' \
  crossplane/xrds/developer-combo/xrd.yaml | \
  kubeconform -schema-location default -strict
```

### Level 2: Policy Testing (Pre-deployment)

**What**: Enforce organizational standards and best practices
**When**: In CI/CD pipeline before deployment
**Tools**: `conftest` (OPA), `kyverno`

```bash
# Example: Test deletion policy
conftest test crossplane/compositions/developer-combo/azure-composition.yaml \
  -p tools/conftest/policy/crossplane.rego
```

### Level 3: Integration Testing (Live cluster)

**What**: Deploy to test cluster and verify resource creation
**When**: In ephemeral test environment
**Tools**: `chainsaw`, `kuttl`, custom scripts

```bash
# Example: Run integration test
./scripts/test/run-integration-tests.sh developer-combo small
```

### Level 4: End-to-End Testing (Live cluster)

**What**: Full lifecycle testing (create → update → delete)
**When**: Before promoting to production
**Tools**: `chainsaw`, custom test scenarios

```bash
# Example: Run E2E test
./scripts/test/run-e2e-tests.sh tests/e2e/scenarios/full-lifecycle.yaml
```

## 🛠️ TDD Workflow

### Red → Green → Refactor

#### 1. RED: Write a Failing Test

```bash
# Create a policy test that should fail
cat > tests/unit/policies/require-deletion-policy.rego <<EOF
package crossplane.composition

deny[msg] {
  input.kind == "Composition"
  resource := input.spec.resources[_]
  not resource.base.spec.deletionPolicy
  msg := sprintf("Resource %s missing deletionPolicy", [resource.name])
}
EOF

# Run test (should fail)
conftest test crossplane/compositions/developer-combo/azure-composition.yaml \
  -p tests/unit/policies/
# Output: FAIL - Resource database missing deletionPolicy
```

#### 2. GREEN: Make the Test Pass

```bash
# Update composition using yq
yq eval '.spec.pipeline[0].input.resources[] |= 
  .base.spec.deletionPolicy = "Delete"' \
  -i crossplane/compositions/developer-combo/azure-composition.yaml

# Run test again (should pass)
conftest test crossplane/compositions/developer-combo/azure-composition.yaml \
  -p tests/unit/policies/
# Output: PASS
```

#### 3. REFACTOR: Improve the Implementation

```bash
# Extract to reusable yq function
cat > scripts/generate/lib/add-deletion-policy.yq <<EOF
.spec.pipeline[0].input.resources[] |= 
  .base.spec.deletionPolicy = "Delete"
EOF

# Use in generation script
yq eval -f scripts/generate/lib/add-deletion-policy.yq \
  templates/composition-template.yaml
```

## 📝 Using YQ for YAML Generation

### Generate XRD

```bash
#!/bin/bash
# scripts/generate/generate-xrd.sh

COMBO_NAME=$1
API_GROUP="example.com"

yq eval '
  .metadata.name = "x'${COMBO_NAME}'.${API_GROUP}" |
  .spec.group = "${API_GROUP}" |
  .spec.names.kind = "X'${COMBO_NAME^}'" |
  .spec.claimNames.kind = "'${COMBO_NAME^}'"
' templates/xrd-template.yaml > "crossplane/xrds/${COMBO_NAME}/xrd.yaml"

echo "✅ Generated XRD: crossplane/xrds/${COMBO_NAME}/xrd.yaml"
```

### Generate Composition with Validation

```bash
#!/bin/bash
# scripts/generate/generate-composition.sh

COMBO_NAME=$1
PROVIDER=$2

# Generate base composition
yq eval '
  .metadata.name = "'${COMBO_NAME}'.'${PROVIDER}'.example.com" |
  .metadata.labels.provider = "'${PROVIDER}'" |
  .spec.compositeTypeRef.kind = "X'${COMBO_NAME^}'"
' templates/composition-template.yaml > /tmp/composition.yaml

# Add deletion policies
yq eval -f scripts/generate/lib/add-deletion-policy.yq \
  -i /tmp/composition.yaml

# Validate before saving
kubectl apply --dry-run=server -f /tmp/composition.yaml && \
  mv /tmp/composition.yaml "crossplane/compositions/${COMBO_NAME}/${PROVIDER}-composition.yaml"

echo "✅ Generated and validated composition"
```

## 🔍 Example: Developer Combo Test Suite

### Unit Test: Schema Validation

```yaml
# tests/unit/xrd/test-required-fields.yaml
apiVersion: example.com/v1alpha1
kind: DeveloperCombo
metadata:
  name: test-missing-size
spec:
  # Missing required field: size
  includeDatabase: true

# Expected: Validation error
# kubectl apply fails with: spec.size is required
```

### Policy Test: Deletion Policy

```rego
# tests/unit/policies/deletion-policy.rego
package crossplane.composition

deny[msg] {
  input.kind == "Composition"
  resource := input.spec.pipeline[0].input.resources[_]
  not resource.base.spec.deletionPolicy
  msg := sprintf("Resource '%s' missing deletionPolicy", [resource.name])
}

deny[msg] {
  input.kind == "Composition"
  resource := input.spec.pipeline[0].input.resources[_]
  resource.base.spec.deletionPolicy == "Orphan"
  msg := sprintf("Resource '%s' uses Orphan policy (should be Delete)", [resource.name])
}
```

### Integration Test: Small Developer Combo

```yaml
# tests/integration/developer-combo/test-small-combo.yaml
apiVersion: chainsaw.kyverno.io/v1alpha1
kind: Test
metadata:
  name: developer-combo-small
spec:
  steps:
  - name: create-claim
    try:
    - apply:
        file: ../../../crossplane/xrds/developer-combo/examples/small-claim.yaml
    - assert:
        file: assertions/claim-accepted.yaml

  - name: verify-resources
    try:
    - assert:
        file: assertions/resourcegroup-created.yaml
    - assert:
        file: assertions/database-created.yaml
    - assert:
        file: assertions/storage-created.yaml
    - assert:
        file: assertions/network-created.yaml

  - name: verify-ready
    try:
    - assert:
        file: assertions/claim-ready.yaml
        timeout: 10m

  - name: cleanup
    try:
    - delete:
        file: ../../../crossplane/xrds/developer-combo/examples/small-claim.yaml
    - assert:
        file: assertions/resources-deleted.yaml
        timeout: 5m
```

### E2E Test: Full Lifecycle

```yaml
# tests/e2e/scenarios/full-lifecycle.yaml
apiVersion: chainsaw.kyverno.io/v1alpha1
kind: Test
metadata:
  name: developer-combo-lifecycle
spec:
  steps:
  # Phase 1: Create
  - name: create-small
    try:
    - apply:
        file: ../../crossplane/claims/dev/myapp-dev-combo.yaml
    - assert:
        resource:
          apiVersion: example.com/v1alpha1
          kind: DeveloperCombo
          metadata:
            name: myapp-dev
            namespace: development
          status:
            conditions:
            - type: Ready
              status: "True"
        timeout: 10m

  # Phase 2: Update (scale up)
  - name: update-to-medium
    try:
    - patch:
        resource:
          apiVersion: example.com/v1alpha1
          kind: DeveloperCombo
          metadata:
            name: myapp-dev
            namespace: development
          spec:
            size: medium  # Changed from small
    - assert:
        resource:
          apiVersion: dbforpostgresql.azure.upbound.io/v1beta1
          kind: FlexibleServer
          status:
            atProvider:
              skuName: GP_Standard_D2s_v3
        timeout: 15m

  # Phase 3: Delete
  - name: delete-combo
    try:
    - delete:
        file: ../../crossplane/claims/dev/myapp-dev-combo.yaml
    - script:
        content: |
          # Verify Azure resources are deleted
          kubectl wait --for=delete resourcegroup/rg-combo-myapp-dev \
            --timeout=10m
```

## 🎓 Learning Path

### Week 1: Foundation

- [ ] Set up Minikube with Crossplane
- [ ] Understand XRD → Composition → Claim flow
- [ ] Write first schema validation test
- [ ] Deploy your first Developer Combo

### Week 2: Unit Testing

- [ ] Learn conftest and OPA policies
- [ ] Write 5 policy tests
- [ ] Implement YQ-based generation scripts
- [ ] Practice Red-Green-Refactor cycle

### Week 3: Integration Testing

- [ ] Set up chainsaw testing framework
- [ ] Write integration tests for all combo sizes
- [ ] Test resource naming conventions
- [ ] Verify status condition propagation

### Week 4: E2E Testing

- [ ] Build full lifecycle tests
- [ ] Test multi-environment scenarios
- [ ] Implement failure recovery tests
- [ ] Create CI/CD pipeline

## 🔧 Useful Commands

### Development Workflow

```bash
# Generate new XRD
./scripts/generate/generate-xrd.sh mycombo

# Validate YAML syntax
yq eval 'explode(.)' crossplane/xrds/mycombo/xrd.yaml > /dev/null && echo "✅ Valid YAML"

# Dry-run apply
kubectl apply --dry-run=server -f crossplane/xrds/mycombo/xrd.yaml

# Run all policy tests
conftest test crossplane/compositions/ -p tests/unit/policies/ --all-namespaces

# Watch claim status
kubectl get developercombo -w

# Debug composition
kubectl describe xdevelopercombo <name>

# Check managed resources
kubectl get managed
```

### Troubleshooting

```bash
# Check Crossplane logs
kubectl logs -n crossplane-system deployment/crossplane -f

# Check provider logs
kubectl logs -n crossplane-system deployment/provider-azure-storage -f

# View events
kubectl get events --sort-by='.lastTimestamp'

# Check provider health
kubectl get providers

# Verify ProviderConfig
kubectl describe providerconfig default
```

## 📚 Additional Resources

### Official Documentation

- [Crossplane Docs](https://docs.crossplane.io/)
- [Crossplane Testing Guide](https://docs.crossplane.io/knowledge-base/guides/testing/)
- [Composition Functions](https://docs.crossplane.io/latest/concepts/composition-functions/)

### Testing Tools

- [conftest](https://www.conftest.dev/) - Policy testing
- [chainsaw](https://kyverno.github.io/chainsaw/) - E2E testing
- [kuttl](https://kuttl.dev/) - Kubernetes operator testing
- [kubeconform](https://github.com/yannh/kubeconform) - Schema validation

### Articles & Tutorials

- [Fast Infrastructure: Understanding Crossplane like a Fast Food Restaurant](https://dev.to/the-software-s-journey/fast-infrastructure-understanding-crossplane-like-a-fast-food-restaurant-1ikk)
- [Testing Crossplane Compositions](https://blog.crossplane.io/testing-crossplane/)
- [TDD for Infrastructure](https://www.hashicorp.com/resources/test-driven-development-tdd-for-infrastructure)

## 🤝 Contributing

This is a learning repository. Feel free to:

- Open issues for questions
- Submit PRs with improvements
- Share your own test cases
- Suggest new examples

## 📄 License

MIT License - See <LICENSE> file for details

## 👤 Author

**Willem van Heemstra**

- Cloud Engineer & Security Domain Expert
- GitHub: [@vanHeemstraSystems](https://github.com/vanHeemstraSystems)
- LinkedIn: [Willem van Heemstra](https://www.linkedin.com/in/wvanheemstra/)

-----

**Happy Testing! 🎯 May your infrastructure be as reliable as a fast food combo meal!**
