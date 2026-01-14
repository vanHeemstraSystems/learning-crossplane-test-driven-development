# TDD Principles for Infrastructure as Code

> Applying Test-Driven Development to Crossplane infrastructure

## 📖 Overview

Test-Driven Development (TDD) for infrastructure applies the same rigor to infrastructure code that we apply to application code. In Crossplane, this means writing tests before creating XRDs, Compositions, and Claims.

## 🎯 Why TDD for Infrastructure?

### Traditional Problems

- **“Works on my machine”** - Infrastructure drift between environments
- **Breaking changes** - Updates break existing workloads
- **No validation** - YAML errors caught too late
- **Manual testing** - Time-consuming, error-prone
- **Fear of changes** - Teams afraid to modify compositions

### TDD Solutions

- **Automated validation** - Catch errors before deployment
- **Regression prevention** - Tests ensure changes don’t break existing functionality
- **Living documentation** - Tests document expected behavior
- **Confidence in changes** - Safe to refactor and improve
- **Faster feedback** - Find issues in seconds, not hours

## 🔄 The TDD Cycle for Crossplane

### Red → Green → Refactor

```
┌─────────────┐
│   🔴 RED    │  Write a failing test
│             │  (Test what you want to create)
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  🟢 GREEN   │  Make the test pass
│             │  (Implement just enough)
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  🔵 REFACTOR│  Improve the code
│             │  (Keep tests passing)
└──────┬──────┘
       │
       └──────── Repeat
```

## 📊 Test Pyramid for Crossplane

```
        ┌────────┐
        │  E2E   │  Slow, expensive (1-2 hours)
        │  Tests │  Full lifecycle in live cluster
        └────────┘
      ┌────────────┐
      │Integration │  Medium speed (15-30 min)
      │   Tests    │  Deploy to test cluster
      └────────────┘
    ┌────────────────┐
    │  Unit Tests    │  Fast (1-2 minutes)
    │  Policy Tests  │  No cluster needed
    └────────────────┘
```

### Test Distribution (Recommended)

- **70%** - Unit and Policy Tests (fast feedback)
- **20%** - Integration Tests (verify resources)
- **10%** - E2E Tests (full lifecycle)

## 🧪 Test Levels Explained

### 1. Unit Tests

**What:** Test individual components without deploying to a cluster

**Tools:** `yq`, `kubectl --dry-run`, `kubeconform`

**Speed:** Seconds to minutes

**Examples:**

- YAML syntax validation
- Schema validation
- Required field checks
- Enum value validation
- Patch logic verification

```bash
# Example: Validate XRD schema
yq eval '.spec.versions[0].schema.openAPIV3Schema' xrd.yaml | \
  kubeconform -schema-location default -strict

# Example: Check required fields
yq eval '.spec.versions[0].schema.openAPIV3Schema.properties.spec.required[]' \
  xrd.yaml | grep -q 'size'
```

### 2. Policy Tests

**What:** Enforce organizational standards and best practices

**Tools:** `conftest` (OPA), `kyverno`

**Speed:** Seconds

**Examples:**

- All resources have deletionPolicy
- Resources are properly tagged
- Naming conventions followed
- Security baselines met
- No hardcoded secrets

```bash
# Example: Policy test with conftest
conftest test composition.yaml -p policies/

# PASS - 0 warnings, 0 failures
# or
# FAIL - Resource 'database' missing deletionPolicy
```

### 3. Integration Tests

**What:** Deploy to test cluster and verify resource creation

**Tools:** `chainsaw`, `kuttl`, custom scripts

**Speed:** 15-30 minutes (Azure provisioning time)

**Examples:**

- Resources created successfully
- Status conditions correct
- Patches applied properly
- Size mapping works
- Endpoints populated

```bash
# Example: Integration test
kubectl apply -f claim.yaml
kubectl wait --for=condition=ready developercombo/test-combo --timeout=15m
```

### 4. End-to-End Tests

**What:** Full lifecycle testing (create → update → delete)

**Tools:** `chainsaw`, custom test scenarios

**Speed:** 1-2 hours

**Examples:**

- Create small combo
- Update to medium
- Verify upgrade successful
- Delete combo
- Verify cleanup complete

## 📝 TDD Workflow Example

### Scenario: Add PostgreSQL version validation

#### 🔴 RED - Write Failing Test

```rego
# tests/unit/policies/postgres-version.rego
package crossplane.composition

deny[msg] {
  input.kind == "Composition"
  database := input.spec.resources[_]
  database.name == "database"
  not is_valid_postgres_version(database.base.spec.forProvider.version)
  msg := sprintf("PostgreSQL version must be 13, 14, or 15, got: %v", 
    [database.base.spec.forProvider.version])
}

is_valid_postgres_version(version) {
  version == "13"
}

is_valid_postgres_version(version) {
  version == "14"
}

is_valid_postgres_version(version) {
  version == "15"
}
```

Run test:

```bash
$ conftest test composition.yaml -p tests/unit/policies/
FAIL - PostgreSQL version must be 13, 14, or 15, got: 12
```

#### 🟢 GREEN - Make Test Pass

Update composition:

```yaml
# compositions/developer-combo/azure-composition.yaml
- name: database
  base:
    apiVersion: dbforpostgresql.azure.upbound.io/v1beta1
    kind: FlexibleServer
    spec:
      forProvider:
        version: "15"  # Changed from "12"
```

Run test:

```bash
$ conftest test composition.yaml -p tests/unit/policies/
PASS - 0 warnings, 0 failures
```

#### 🔵 REFACTOR - Improve Implementation

Make version configurable:

```yaml
# XRD: Add version field
spec:
  properties:
    postgresVersion:
      type: string
      description: "PostgreSQL version: 13, 14, or 15"
      enum: ["13", "14", "15"]
      default: "15"

# Composition: Use patch
patches:
- type: FromCompositeFieldPath
  fromFieldPath: spec.postgresVersion
  toFieldPath: spec.forProvider.version
```

Run tests again:

```bash
$ conftest test composition.yaml -p tests/unit/policies/
PASS - 0 warnings, 0 failures

$ ./scripts/test/run-unit-tests.sh
✅ All unit tests passed!
```

## 🎯 TDD Best Practices

### 1. Start with the Simplest Test

Don’t write complex tests first. Start with:

- YAML syntax validation
- Required fields present
- Correct resource types

Then gradually add:

- Policy enforcement
- Patch logic
- Integration tests

### 2. Write Tests for Bugs

When you find a bug:

1. Write a test that exposes the bug (RED)
1. Fix the bug (GREEN)
1. Refactor if needed (REFACTOR)

Now the bug can never return unnoticed.

### 3. Keep Tests Independent

Each test should:

- Run independently of others
- Clean up after itself
- Not depend on execution order
- Use unique names/namespaces

### 4. Fast Feedback Loop

Optimize for speed:

- Run unit tests on every change (seconds)
- Run integration tests before commit (minutes)
- Run E2E tests in CI/CD (hours)

### 5. Test Behavior, Not Implementation

❌ **Bad:** Test that composition has 4 resources

✅ **Good:** Test that claim creates database, storage, network

The implementation might change (5 resources instead of 4), but the behavior stays the same.

## 🚀 TDD in CI/CD Pipeline

```yaml
# .github/workflows/crossplane-tdd.yml
name: Crossplane TDD

on: [push, pull_request]

jobs:
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run unit tests
        run: ./scripts/test/run-unit-tests.sh
    # Fast: 1-2 minutes
    
  policy-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install conftest
        run: |
          curl -L https://github.com/open-policy-agent/conftest/releases/latest/download/conftest_Linux_x86_64.tar.gz | tar xz
          sudo mv conftest /usr/local/bin
      - name: Run policy tests
        run: ./scripts/validate/validate-policies.sh
    # Fast: seconds
    
  integration-tests:
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'
    steps:
      - uses: actions/checkout@v3
      - name: Setup test cluster
        run: ./environments/minikube/setup.sh
      - name: Install Crossplane
        run: ./environments/minikube/crossplane-install.sh
      - name: Run integration tests
        run: ./scripts/test/run-integration-tests.sh
    # Medium: 15-30 minutes
    
  e2e-tests:
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3
      - name: Setup test cluster
        run: ./environments/minikube/setup.sh
      - name: Run E2E tests
        run: ./scripts/test/run-e2e-tests.sh
    # Slow: 1-2 hours
```

## 📚 Common Testing Patterns

### Pattern 1: Golden Master Testing

Keep known-good configurations and compare:

```bash
# Generate composition
./scripts/generate/generate-composition.sh myapp azure > output.yaml

# Compare with golden master
diff output.yaml tests/golden/myapp-azure-composition.yaml
```

### Pattern 2: Property-Based Testing

Test with many inputs:

```bash
# Test all sizes
for size in small medium large; do
  ./scripts/generate/generate-claim.sh testapp dev $size
  ./scripts/validate/validate-policies.sh
done
```

### Pattern 3: Snapshot Testing

Capture output and verify consistency:

```bash
# Capture managed resources
kubectl get managed -o yaml > snapshot.yaml

# Verify count hasn't changed
RESOURCE_COUNT=$(yq eval '.items | length' snapshot.yaml)
test $RESOURCE_COUNT -eq 4 || exit 1
```

## 🎓 Learning Path

### Week 1: Unit Testing

- Write YAML validation tests
- Add schema validation
- Learn conftest/OPA basics
- Create 5 policy tests

### Week 2: Integration Testing

- Set up test cluster
- Deploy first composition
- Verify resource creation
- Check status conditions

### Week 3: E2E Testing

- Write full lifecycle test
- Test create/update/delete
- Handle failures gracefully
- Add to CI/CD

### Week 4: Advanced

- Property-based testing
- Mutation testing
- Performance testing
- Chaos engineering

## 🔍 Debugging Failed Tests

### Unit Test Failures

```bash
# Check YAML syntax
yq eval 'explode(.)' file.yaml

# Validate against schema
kubectl apply --dry-run=server -f file.yaml

# Check specific field
yq eval '.spec.pipeline[0].input.resources[].base.spec.deletionPolicy' composition.yaml
```

### Policy Test Failures

```bash
# Run with verbose output
conftest test -p policies/ --trace composition.yaml

# Test specific policy
conftest test -p policies/deletion-policy.rego composition.yaml

# Check what OPA sees
conftest parse composition.yaml
```

### Integration Test Failures

```bash
# Describe the claim
kubectl describe developercombo test-combo

# Check managed resources
kubectl get managed -l crossplane.io/composite=test-combo

# View events
kubectl get events --sort-by='.lastTimestamp'

# Check provider logs
kubectl logs -n crossplane-system -l pkg.crossplane.io/provider=provider-azure
```

## 📖 Additional Resources

### Books

- “Test Driven Development” by Kent Beck
- “Growing Object-Oriented Software, Guided by Tests” by Freeman & Pryce

### Articles

- [Testing Crossplane Compositions](https://blog.crossplane.io/testing-crossplane/)
- [Infrastructure Testing with Terratest](https://terratest.gruntwork.io/)

### Tools

- [conftest](https://www.conftest.dev/) - Policy testing
- [chainsaw](https://kyverno.github.io/chainsaw/) - E2E testing
- [kuttl](https://kuttl.dev/) - Kubernetes operator testing

## 🎯 Key Takeaways

1. **Write tests first** - They guide your design
1. **Keep tests fast** - Fast feedback enables rapid iteration
1. **Test behavior** - Not implementation details
1. **Automate everything** - Manual testing doesn’t scale
1. **Test in production** - Use smoke tests and monitoring

-----

**Remember:** The goal of TDD isn’t perfect test coverage. It’s about confidence, quality, and speed of delivery. Start small, be consistent, and improve over time.

**“Infrastructure is code. Test it like code.”** 🧪
