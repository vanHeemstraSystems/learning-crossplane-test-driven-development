# Testing Strategy for Crossplane Infrastructure

> A comprehensive approach to testing Crossplane XRDs, Compositions, and Claims

## 📋 Executive Summary

This document defines the testing strategy for Crossplane-based infrastructure at Atos IDP. Our approach ensures reliable, secure, and well-validated infrastructure delivery through automated testing at multiple levels.

## 🎯 Testing Objectives

### Primary Goals

1. **Prevent production incidents** - Catch issues before deployment
1. **Enable safe changes** - Refactor with confidence
1. **Accelerate delivery** - Fast feedback on changes
1. **Maintain quality** - Enforce organizational standards
1. **Document behavior** - Tests serve as living documentation

### Success Metrics

- **Zero failed deployments** due to configuration errors
- **<5 minutes** for unit test feedback
- **<30 minutes** for integration test feedback
- **100% policy compliance** for all compositions
- **90%+ test coverage** for critical paths

## 🏗️ Testing Architecture

### Test Layers

```
┌─────────────────────────────────────────────────┐
│            Production Environment                │
│  (Monitored with smoke tests & observability)   │
└─────────────────────────────────────────────────┘
                      ▲
                      │ Deploy after all tests pass
                      │
┌─────────────────────────────────────────────────┐
│              E2E Tests (10%)                     │
│  Full lifecycle: Create → Update → Delete       │
│  Time: 1-2 hours | Frequency: On main branch   │
└─────────────────────────────────────────────────┘
                      ▲
                      │
┌─────────────────────────────────────────────────┐
│         Integration Tests (20%)                  │
│  Deploy to test cluster, verify resources       │
│  Time: 15-30 min | Frequency: On PR            │
└─────────────────────────────────────────────────┘
                      ▲
                      │
┌─────────────────────────────────────────────────┐
│      Unit & Policy Tests (70%)                   │
│  Fast validation without cluster                │
│  Time: 1-2 min | Frequency: On every commit    │
└─────────────────────────────────────────────────┘
```

## 🧪 Test Level Definitions

### Level 1: Unit Tests (70% of tests)

**Purpose:** Validate individual components in isolation

**Scope:**

- YAML syntax and structure
- Schema compliance (OpenAPI v3)
- Required fields present
- Enum values valid
- Patch logic correct
- Naming conventions

**Tools:**

- `yq` - YAML parsing and validation
- `kubectl --dry-run` - Kubernetes API validation
- `kubeconform` - Schema validation
- Custom bash scripts

**Execution:**

- **When:** On every file change
- **Where:** Developer workstation, CI/CD
- **Duration:** 10-30 seconds per test
- **Pass Criteria:** All syntax and schema validations pass

**Example Test:**

```bash
# Test: XRD has required claim names
test_xrd_has_claim_names() {
  local claim_kind=$(yq eval '.spec.claimNames.kind' xrd.yaml)
  
  if [ -z "$claim_kind" ]; then
    echo "FAIL: XRD missing claimNames.kind"
    return 1
  fi
  
  echo "PASS: XRD has claimNames"
  return 0
}
```

**Coverage Goals:**

- 100% of XRDs validated
- 100% of Compositions validated
- All critical paths tested

### Level 2: Policy Tests (Included in Unit Tests)

**Purpose:** Enforce organizational standards and security baselines

**Scope:**

- Deletion policies set
- Resources properly tagged
- Security configurations
- Naming conventions
- No hardcoded secrets
- Compliance requirements

**Tools:**

- `conftest` (Open Policy Agent)
- `kyverno` (Kubernetes-native policies)

**Execution:**

- **When:** On every commit
- **Where:** Developer workstation, CI/CD
- **Duration:** 5-10 seconds per policy
- **Pass Criteria:** Zero policy violations

**Example Policy:**

```rego
# Policy: All resources must have deletionPolicy
package crossplane.composition

deny[msg] {
  input.kind == "Composition"
  resource := input.spec.resources[_]
  not resource.base.spec.deletionPolicy
  
  msg := sprintf(
    "Resource '%s' missing deletionPolicy. Required for cleanup.",
    [resource.name]
  )
}
```

**Policy Categories:**

1. **Security** - No secrets in plain text, proper RBAC
1. **Compliance** - Required tags, naming patterns
1. **Operations** - Deletion policies, monitoring labels
1. **Cost** - Resource limits, approved SKUs

### Level 3: Integration Tests (20% of tests)

**Purpose:** Verify resources are created correctly in a real cluster

**Scope:**

- Resources provision successfully
- Status conditions propagate
- Patches apply correctly
- Endpoints are accessible
- Dependencies resolve
- Cleanup works

**Tools:**

- `kubectl` - Resource verification
- `chainsaw` - Test orchestration
- Custom verification scripts

**Execution:**

- **When:** On pull request
- **Where:** Ephemeral test cluster (Minikube/kind)
- **Duration:** 15-30 minutes (Azure provisioning)
- **Pass Criteria:** All resources reach Ready state

**Test Structure:**

```yaml
# Integration test example
apiVersion: chainsaw.kyverno.io/v1alpha1
kind: Test
metadata:
  name: developer-combo-integration
spec:
  steps:
  - name: deploy-claim
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
        
  - name: verify-resources
    try:
    - assert:
        resource:
          apiVersion: dbforpostgresql.azure.upbound.io/v1beta1
          kind: FlexibleServer
          status:
            conditions:
            - type: Ready
              status: "True"
```

**Verification Points:**

- ✅ Composite Resource created
- ✅ All Managed Resources created
- ✅ Status conditions accurate
- ✅ Patches applied correctly
- ✅ Ready state achieved
- ✅ Endpoints populated

### Level 4: End-to-End Tests (10% of tests)

**Purpose:** Validate complete lifecycle including updates and deletions

**Scope:**

- Create infrastructure
- Update/modify configuration
- Verify changes applied
- Delete infrastructure
- Verify cleanup complete

**Tools:**

- `chainsaw` - Test orchestration
- Custom test scenarios
- Azure CLI - Verify actual resources

**Execution:**

- **When:** On main branch merge, nightly
- **Where:** Dedicated test environment
- **Duration:** 1-2 hours
- **Pass Criteria:** Full lifecycle completes successfully

**Test Scenarios:**

**Scenario 1: Happy Path**

```
1. Create small Developer Combo
2. Wait for Ready
3. Verify database SKU = B_Standard_B1ms
4. Update to medium
5. Verify database SKU = GP_Standard_D2s_v3
6. Delete combo
7. Verify all Azure resources deleted
```

**Scenario 2: Failure Recovery**

```
1. Create combo with invalid configuration
2. Verify claim shows error condition
3. Fix configuration
4. Verify recovery to Ready state
```

**Scenario 3: Concurrent Claims**

```
1. Create 5 claims simultaneously
2. Verify all reach Ready state
3. Delete all claims
4. Verify cleanup completes
```

## 📊 Test Coverage Requirements

### By Component Type

|Component     |Unit Tests|Policy Tests|Integration|E2E|
|--------------|----------|------------|-----------|---|
|XRD           |100%      |100%        |50%        |25%|
|Composition   |100%      |100%        |75%        |50%|
|Claim Examples|100%      |N/A         |100%       |75%|
|Policies      |N/A       |100%        |50%        |25%|

### By Criticality

|Criticality  |Required Coverage      |
|-------------|-----------------------|
|Critical Path|90%+ all levels        |
|High         |75%+ unit + integration|
|Medium       |50%+ unit tests        |
|Low          |Unit tests only        |

**Critical Paths:**

- Production-facing XRDs
- Shared platform compositions
- Database provisioning
- Network configurations
- Security-related resources

## 🔄 Testing Workflow

### Developer Workflow

```bash
# 1. Create feature branch
git checkout -b feature/add-postgres-ha

# 2. Write failing test (RED)
cat > tests/unit/postgres-ha-test.sh <<EOF
test_postgres_has_ha_enabled() {
  ha_enabled=$(yq eval '.spec.resources[] | 
    select(.name == "database") | 
    .base.spec.forProvider.highAvailability.mode' composition.yaml)
  
  test "$ha_enabled" = "ZoneRedundant"
}
EOF

# 3. Run test - should fail
./scripts/test/run-unit-tests.sh
# FAIL: test_postgres_has_ha_enabled

# 4. Implement feature (GREEN)
yq eval '.spec.resources[] | 
  select(.name == "database") | 
  .base.spec.forProvider.highAvailability.mode = "ZoneRedundant"' \
  -i composition.yaml

# 5. Run test - should pass
./scripts/test/run-unit-tests.sh
# PASS: test_postgres_has_ha_enabled

# 6. Run all validations
./scripts/validate/validate-policies.sh
./scripts/test/run-unit-tests.sh

# 7. Commit and push
git add .
git commit -m "feat: Add PostgreSQL high availability"
git push origin feature/add-postgres-ha
```

### CI/CD Workflow

```yaml
# Pull Request Checks
on: pull_request
jobs:
  unit-tests:
    - run: ./scripts/test/run-unit-tests.sh
    - required: true
    
  policy-tests:
    - run: ./scripts/validate/validate-policies.sh
    - required: true
    
  integration-tests:
    - run: ./scripts/test/run-integration-tests.sh
    - required: true
    - timeout: 30 minutes

# Main Branch Checks  
on: push to main
jobs:
  e2e-tests:
    - run: ./scripts/test/run-e2e-tests.sh
    - required: true
    - timeout: 2 hours
    
  deploy-staging:
    - requires: [e2e-tests]
    - environment: staging
```

## 🎯 Test Data Management

### Test Data Principles

1. **Isolated** - Each test uses unique names/namespaces
1. **Reproducible** - Same test data produces same results
1. **Minimal** - Only data needed for the test
1. **Cleaned** - Tests clean up after themselves

### Test Namespaces

```bash
# Pattern: {test-type}-{timestamp}
unit-tests-1705234567
integration-tests-1705234890
e2e-tests-1705235123
```

### Test Credentials

```bash
# Use separate service principals for testing
# Never use production credentials in tests

# Test SP: crossplane-test-sp
# Permissions: Limited to test resource groups
# Cleanup: Automatic deletion after 7 days
```

### Test Resource Cleanup

```yaml
# Automatic cleanup configuration
apiVersion: azure.upbound.io/v1beta1
kind: ResourceGroup
metadata:
  annotations:
    # Auto-delete after 24 hours
    expires: "2026-01-15T00:00:00Z"
spec:
  forProvider:
    location: westeurope
    tags:
      Environment: test
      AutoDelete: "true"
      CreatedBy: ci-pipeline
```

## 🚨 Handling Test Failures

### Failure Classification

**Type 1: Fast Failures (Unit/Policy)**

- **Response Time:** < 5 minutes
- **Action:** Fix immediately, block PR
- **Escalation:** None needed

**Type 2: Integration Failures**

- **Response Time:** < 30 minutes
- **Action:** Investigate, may block PR
- **Escalation:** Notify team lead if persistent

**Type 3: E2E Failures**

- **Response Time:** < 2 hours
- **Action:** Investigate thoroughly
- **Escalation:** Architect review if infrastructure issue

### Debugging Checklist

```bash
# Unit Test Failure
□ Check YAML syntax with yq
□ Validate schema with kubectl --dry-run
□ Review test expectations
□ Compare with golden master

# Policy Test Failure
□ Run conftest with --trace
□ Check policy rules
□ Verify input data
□ Test policy in isolation

# Integration Test Failure
□ Describe the claim
□ Check managed resources
□ View Crossplane events
□ Check provider logs
□ Verify Azure credentials

# E2E Test Failure
□ Review test logs
□ Check Azure Portal
□ Verify cleanup completed
□ Check for quota issues
□ Review network connectivity
```

## 📈 Metrics and Reporting

### Key Metrics

1. **Test Execution Time**
- Unit tests: < 2 minutes
- Integration tests: < 30 minutes
- E2E tests: < 2 hours
1. **Test Success Rate**
- Target: > 95% pass rate
- Alert if < 90% for 3 consecutive runs
1. **Code Coverage**
- XRDs: 100%
- Compositions: > 90%
- Policies: 100%
1. **Mean Time to Detection (MTTD)**
- Target: < 5 minutes for critical issues
- Measured from commit to test failure
1. **Mean Time to Resolution (MTTR)**
- Unit test failures: < 15 minutes
- Integration failures: < 1 hour
- E2E failures: < 4 hours

### Reporting Dashboard

```
┌─────────────────────────────────────┐
│   Crossplane Testing Dashboard      │
├─────────────────────────────────────┤
│ Test Execution (Last 24h)           │
│ ✅ Unit:        247 / 250  (98.8%)  │
│ ✅ Policy:      125 / 125  (100%)   │
│ ✅ Integration:  18 /  20  (90.0%)  │
│ ✅ E2E:          4 /   4  (100%)    │
├─────────────────────────────────────┤
│ Performance                          │
│ ⚡ Unit:        1.2 min  (target: 2)│
│ ⚡ Integration: 22 min   (target: 30)│
│ ⚡ E2E:         87 min   (target: 120)│
├─────────────────────────────────────┤
│ Coverage                             │
│ 📊 XRDs:         15/15    (100%)    │
│ 📊 Compositions:  8/9     (88.9%)   │
│ 📊 Policies:     12/12    (100%)    │
└─────────────────────────────────────┘
```

## 🔐 Security Testing

### Security Test Categories

1. **Secret Scanning**
   
   ```bash
   # Check for hardcoded secrets
   grep -r "password\|secret\|key" crossplane/ | \
     grep -v "secretRef" | grep -v "passwordSecretRef"
   ```
1. **RBAC Validation**
   
   ```bash
   # Verify least-privilege principles
   kubectl auth can-i --list --as=system:serviceaccount:crossplane-system:provider-azure
   ```
1. **Network Policy**
   
   ```bash
   # Verify network isolation
   kubectl get networkpolicy -n crossplane-system
   ```
1. **Image Scanning**
   
   ```bash
   # Scan provider images
   trivy image xpkg.upbound.io/upbound/provider-azure:v1.3.0
   ```

## 🎓 Test Environment Management

### Environment Tiers

|Tier      |Purpose                  |Lifespan |Cost  |
|----------|-------------------------|---------|------|
|Local     |Developer testing        |On-demand|Free  |
|CI        |Automated testing        |Per-build|Low   |
|Staging   |Pre-production validation|Permanent|Medium|
|Production|Live workloads           |Permanent|High  |

### Environment Parity

Ensure test environments match production:

- ✅ Same Crossplane version
- ✅ Same provider versions
- ✅ Same Azure region
- ✅ Similar resource quotas
- ✅ Same network configuration
- ✅ Same RBAC policies

## 📚 Testing Best Practices

### DO ✅

- Write tests before code (TDD)
- Keep tests independent
- Use descriptive test names
- Clean up test resources
- Test failure scenarios
- Mock external dependencies when appropriate
- Version control test data
- Run tests locally before pushing
- Review test failures immediately
- Update tests when requirements change

### DON’T ❌

- Skip tests to save time
- Use production credentials
- Leave test resources running
- Ignore flaky tests
- Test implementation details
- Share state between tests
- Hardcode values
- Mix test types
- Test in production first
- Commit failing tests

## 🔄 Continuous Improvement

### Monthly Review

- Analyze test failure patterns
- Identify flaky tests
- Review test execution times
- Update test coverage goals
- Refactor slow tests
- Add tests for new patterns
- Remove obsolete tests
- Update documentation

### Quarterly Goals

- Reduce E2E test time by 10%
- Increase integration test coverage
- Improve test reliability
- Enhance reporting
- Train team on testing practices

-----

**Remember:** Testing is not about perfection. It’s about confidence, speed, and quality. Invest in tests that provide the most value for your team and organization.

**“If it’s not tested, it’s broken.”** 🧪
