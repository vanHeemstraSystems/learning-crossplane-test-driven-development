# File Index - Crossplane TDD Repository

> Quick reference guide to all files in the repository

## 📖 Documentation Files

|File                |Purpose                                                     |When to Read        |
|--------------------|------------------------------------------------------------|--------------------|
|`README.md`         |Main repository overview, directory structure, learning path|**Start here**      |
|`GETTING_STARTED.md`|Step-by-step setup guide with troubleshooting               |After reading README|

## ⚙️ Setup & Installation Scripts

|File                   |Purpose                                         |Command                  |
|-----------------------|------------------------------------------------|-------------------------|
|`minikube-setup.sh`    |Create Minikube cluster with Crossplane settings|`./minikube-setup.sh`    |
|`crossplane-install.sh`|Install Crossplane and core functions           |`./crossplane-install.sh`|
|`provider-install.sh`  |Install all Azure providers                     |`./provider-install.sh`  |

**Run in order**: minikube-setup → crossplane-install → provider-install

## 🎯 Crossplane Configuration Files

### Core Resources

|File                       |Type          |Description                             |
|---------------------------|--------------|----------------------------------------|
|`xrd.yaml`                 |XRD           |Developer Combo menu board (defines API)|
|`azure-composition.yaml`   |Composition   |Recipe for Azure resources              |
|`example-claims.yaml`      |Claims        |Sample orders (dev/staging/prod)        |
|`providerconfig-azure.yaml`|ProviderConfig|Azure credentials configuration         |

### Templates (for YQ generation)

|File                       |Purpose                                 |
|---------------------------|----------------------------------------|
|`xrd-template.yaml`        |Template for generating new XRDs        |
|`composition-template.yaml`|Template for generating new Compositions|

## 🛠️ Generation Scripts (YQ-based)

|Script                   |Usage                                        |Output                                 |
|-------------------------|---------------------------------------------|---------------------------------------|
|`generate-xrd.sh`        |`./generate-xrd.sh <name> <group>`           |Creates new XRD file                   |
|`generate-composition.sh`|`./generate-composition.sh <name> <provider>`|Creates new Composition with validation|
|`generate-claim.sh`      |`./generate-claim.sh <app> <env> <size>`     |Creates new Claim                      |

**Example workflow:**

```bash
./generate-xrd.sh myapp example.com
./generate-composition.sh myapp azure  
./generate-claim.sh myapp dev small
```

## 🧪 Testing Scripts

### Validation Scripts

|Script                |Purpose                  |When to Run           |
|----------------------|-------------------------|----------------------|
|`validate-policies.sh`|Run conftest policy tests|Before committing code|

### Test Runners

|Script                    |Test Level        |Duration |When to Run       |
|--------------------------|------------------|---------|------------------|
|`run-unit-tests.sh`       |Unit              |1-2 min  |After every change|
|`run-integration-tests.sh`|Integration       |15-30 min|Before deployment |
|`run-e2e-tests.sh`        |End-to-End        |60-90 min|Before release    |
|`tdd-workflow.sh`         |Complete TDD cycle|15-90 min|Learning/Demo     |

**Usage examples:**

```bash
# Quick validation
./run-unit-tests.sh

# Test specific combo size
./run-integration-tests.sh developer-combo small

# Full lifecycle test
./run-e2e-tests.sh

# Automated TDD demo
./tdd-workflow.sh
```

## 📋 Policy Files

### Conftest (OPA)

|File                      |Purpose                                   |
|--------------------------|------------------------------------------|
|`crossplane-policies.rego`|OPA policies for Crossplane best practices|

**Policies enforced:**

- ✅ All resources have deletionPolicy
- ⚠️ Warn about Orphan policies
- ✅ ManagedBy tags required
- ✅ Naming conventions
- ✅ Readiness checks

### Kyverno

|File                   |Purpose                                |
|-----------------------|---------------------------------------|
|`kyverno-policies.yaml`|Kyverno policies for runtime validation|

**Policies included:**

- Composition validation
- XRD validation
- Claim validation

## 🧪 Test Definition Files

|File                       |Framework|Purpose                                      |
|---------------------------|---------|---------------------------------------------|
|`developer-combo-test.yaml`|Chainsaw |Integration and E2E tests for Developer Combo|

**Test scenarios:**

- ✅ Small combo creation
- ✅ Size upgrade (small → medium)
- ✅ Full lifecycle (create → update → delete)

## 📊 File Organization by Use Case

### “I want to learn Crossplane TDD”

1. Read `README.md`
1. Read `GETTING_STARTED.md`
1. Run `minikube-setup.sh`
1. Run `crossplane-install.sh`
1. Run `provider-install.sh`
1. Explore `xrd.yaml` and `azure-composition.yaml`

### “I want to test my configurations”

1. Run `run-unit-tests.sh` (fast, no cluster needed)
1. Run `validate-policies.sh` (policy validation)
1. Run `run-integration-tests.sh` (requires cluster)
1. Run `run-e2e-tests.sh` (full lifecycle)

### “I want to create new resources”

1. Use `generate-xrd.sh` to create XRD
1. Use `generate-composition.sh` to create Composition
1. Use `generate-claim.sh` to create Claims
1. Validate with `validate-policies.sh`
1. Test with `run-unit-tests.sh`

### “I want to understand TDD workflow”

1. Read fast food metaphor in `README.md`
1. Run `tdd-workflow.sh` (automated demo)
1. Study `run-unit-tests.sh` source code
1. Study `run-integration-tests.sh` source code
1. Study `run-e2e-tests.sh` source code

## 🎯 Quick Reference: What File for What Task?

|Task                       |File to Use                                                          |
|---------------------------|---------------------------------------------------------------------|
|Setup Minikube             |`minikube-setup.sh`                                                  |
|Install Crossplane         |`crossplane-install.sh`                                              |
|Install providers          |`provider-install.sh`                                                |
|Configure Azure            |`providerconfig-azure.yaml`                                          |
|Create menu (XRD)          |`xrd.yaml` or `generate-xrd.sh`                                      |
|Create recipe (Composition)|`azure-composition.yaml` or `generate-composition.sh`                |
|Place order (Claim)        |`example-claims.yaml` or `generate-claim.sh`                         |
|Run tests                  |`run-unit-tests.sh` → `run-integration-tests.sh` → `run-e2e-tests.sh`|
|Validate policies          |`validate-policies.sh`                                               |
|Learn TDD                  |`tdd-workflow.sh`                                                    |

## 📦 File Sizes and Line Counts

```
README.md                    19K  (comprehensive guide)
GETTING_STARTED.md           12K  (step-by-step tutorial)
xrd.yaml                      2K  (XRD definition)
azure-composition.yaml        6K  (full composition)
example-claims.yaml           1K  (3 sample claims)
crossplane-policies.rego      2K  (OPA policies)
kyverno-policies.yaml         7K  (Kyverno policies)
developer-combo-test.yaml     7K  (chainsaw tests)

minikube-setup.sh             3K
crossplane-install.sh         3K
provider-install.sh           3K

generate-xrd.sh               2K
generate-composition.sh       3K
generate-claim.sh             3K
validate-policies.sh          2K

run-unit-tests.sh             8K  (comprehensive unit tests)
run-integration-tests.sh      6K  (live cluster tests)
run-e2e-tests.sh             10K  (full lifecycle tests)
tdd-workflow.sh               7K  (automated TDD demo)
```

## 🔗 Related Resources

|Resource           |Location                                                                                                           |
|-------------------|-------------------------------------------------------------------------------------------------------------------|
|Learning Crossplane|https://github.com/vanHeemstraSystems/learning-crossplane                                                          |
|Learning TDD       |https://github.com/vanHeemstraSystems/learning-test-driven-development                                             |
|Fast Food Article  |https://dev.to/the-software-s-journey/fast-infrastructure-understanding-crossplane-like-a-fast-food-restaurant-1ikk|

## 🆘 Which File When Something Goes Wrong?

|Problem                     |Check This File            |Look For                       |
|----------------------------|---------------------------|-------------------------------|
|Cluster won’t start         |`minikube-setup.sh`        |Resource limits, driver issues |
|Crossplane install fails    |`crossplane-install.sh`    |Helm errors, namespace issues  |
|Providers not healthy       |`provider-install.sh`      |Package URLs, network issues   |
|Azure auth fails            |`providerconfig-azure.yaml`|Credentials, subscription ID   |
|Claim not creating resources|`azure-composition.yaml`   |Resource definitions, patches  |
|Policy tests failing        |`crossplane-policies.rego` |Policy rules                   |
|Tests timing out            |`run-*-tests.sh`           |Timeout values, wait conditions|

## 📝 Maintenance Notes

**Files to customize for your use case:**

- `xrd.yaml` - Adjust schema for your needs
- `azure-composition.yaml` - Modify resources and patches
- `crossplane-policies.rego` - Add custom policies
- `*-template.yaml` - Templates for generation

**Files you probably shouldn’t change:**

- Setup scripts (`*-setup.sh`, `*-install.sh`)
- Test runners (unless adding features)

**Files to update when policies change:**

- `crossplane-policies.rego`
- `kyverno-policies.yaml`
- `validate-policies.sh`

-----

**💡 Tip:** Start with `GETTING_STARTED.md` and use this index as a reference when you need to find specific functionality!
