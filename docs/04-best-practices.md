# Best Practices for Crossplane Infrastructure

> Proven patterns and practices for production Crossplane deployments

## 📋 Overview

This document captures architectural best practices, design patterns, and lessons learned from implementing Crossplane at scale. These practices are based on production experience and community wisdom.

## 🏗️ XRD Design Principles

### 1. Keep XRDs Simple and Focused

**Good - Single Responsibility:**

```yaml
# XRD for just a database
apiVersion: apiextensions.crossplane.io/v1
kind: CompositeResourceDefinition
metadata:
  name: xpostgresqldatabase.example.com
spec:
  group: example.com
  names:
    kind: XPostgreSQLDatabase
    plural: xpostgresqldatabases
```

**Bad - Too Many Responsibilities:**

```yaml
# DON'T: XRD that tries to do everything
apiVersion: apiextensions.crossplane.io/v1
kind: CompositeResourceDefinition
metadata:
  name: xentireapplication.example.com
  # This includes: database, storage, network, compute, monitoring, logging...
```

**Why:** Single-responsibility XRDs are easier to test, compose, and maintain.

### 2. Use Clear, Descriptive Names

**Naming Convention:**

```
X{Resource}{Type}.{organization}.com

Examples:
- XPostgreSQLDatabase.atos.internal
- XAzureStorageAccount.atos.internal  
- XVirtualNetwork.atos.internal
- XKubernetesCluster.atos.internal
```

**Claim Names:**

```
{Resource}{Type}

Examples:
- PostgreSQLDatabase
- AzureStorageAccount
- VirtualNetwork
- KubernetesCluster
```

### 3. Provide Sensible Defaults

**Good - Smart Defaults:**

```yaml
spec:
  versions:
  - schema:
      openAPIV3Schema:
        properties:
          spec:
            properties:
              size:
                type: string
                default: "small"        # Default to most common
              highAvailability:
                type: boolean
                default: false          # Safe default
              backupRetention:
                type: integer
                default: 7              # Reasonable default
```

**Why:** Developers can get started quickly, customize only what they need.

### 4. Use Enums for Controlled Values

**Good - Restricted Choices:**

```yaml
size:
  type: string
  enum: ["small", "medium", "large"]
  description: "Database size: small (dev), medium (staging), large (prod)"

environment:
  type: string
  enum: ["development", "staging", "production"]
  description: "Environment type affects resource sizing and HA"
```

**Bad - Free-form String:**

```yaml
size:
  type: string  # No constraints!
  description: "Enter a size"
```

**Why:** Enums prevent typos, enable validation, and make self-service safer.

### 5. Document Everything

**Excellent Documentation:**

```yaml
spec:
  versions:
  - schema:
      openAPIV3Schema:
        description: >-
          PostgreSQL Database provisioned via Azure Database for PostgreSQL.
          Includes automatic backups, high availability options, and 
          point-in-time restore capabilities.
        properties:
          spec:
            description: "PostgreSQLDatabase specification"
            properties:
              size:
                type: string
                description: |
                  Database size affects compute and storage:
                  - small: B_Standard_B1ms, 32GB storage (development)
                  - medium: GP_Standard_D2s_v3, 128GB storage (staging)
                  - large: GP_Standard_D4s_v3, 512GB storage (production)
                enum: ["small", "medium", "large"]
                default: "small"
```

## 🎨 Composition Patterns

### Pattern 1: Resource Naming

**Use Consistent Naming:**

```yaml
patches:
- type: FromCompositeFieldPath
  fromFieldPath: metadata.name
  toFieldPath: metadata.annotations[crossplane.io/external-name]
  transforms:
  - type: string
    string:
      fmt: "rg-%s"            # Resource Group
      type: Format

- type: FromCompositeFieldPath
  fromFieldPath: metadata.name
  toFieldPath: metadata.annotations[crossplane.io/external-name]
  transforms:
  - type: string
    string:
      fmt: "db-%s"            # Database
      type: Format
```

**Pattern:**

- `rg-{name}` - Resource Groups
- `db-{name}` - Databases
- `st-{name}` - Storage Accounts
- `vnet-{name}` - Virtual Networks

### Pattern 2: Tagging Strategy

**Required Tags:**

```yaml
spec:
  forProvider:
    tags:
      ManagedBy: "Crossplane"           # Required
      Environment: "{{ .environment }}"  # Required
      Owner: "{{ .team }}"               # Required
      CostCenter: "{{ .costCenter }}"    # Required
      Project: "{{ .project }}"          # Optional
      CreatedAt: "{{ .timestamp }}"      # Auto-generated
```

**Implementation:**

```yaml
patches:
# Auto-tag all resources
- type: FromCompositeFieldPath
  fromFieldPath: spec.environment
  toFieldPath: spec.forProvider.tags.Environment

- type: FromCompositeFieldPath
  fromFieldPath: spec.owner
  toFieldPath: spec.forProvider.tags.Owner
  
# Add managed-by tag automatically
- type: Transform
  transform:
    type: string
    string:
      type: Format
      fmt: "Crossplane"
  toFieldPath: spec.forProvider.tags.ManagedBy
```

### Pattern 3: Deletion Policies

**Always Set Deletion Policy:**

```yaml
spec:
  resources:
  - name: database
    base:
      spec:
        deletionPolicy: Delete  # Clean up on delete
        
  - name: storage-critical
    base:
      spec:
        deletionPolicy: Orphan  # Keep data after deletion
```

**Guidelines:**

- **Delete:** For dev/test resources, networking
- **Orphan:** For production data stores, critical configs

### Pattern 4: Size Mapping

**Use Transform Maps:**

```yaml
patches:
- type: FromCompositeFieldPath
  fromFieldPath: spec.size
  toFieldPath: spec.forProvider.skuName
  transforms:
  - type: map
    map:
      small: "B_Standard_B1ms"
      medium: "GP_Standard_D2s_v3"
      large: "GP_Standard_D4s_v3"
      xlarge: "GP_Standard_D8s_v3"

- type: FromCompositeFieldPath
  fromFieldPath: spec.size
  toFieldPath: spec.forProvider.storageMb
  transforms:
  - type: map
    map:
      small: "32768"     # 32 GB
      medium: "131072"   # 128 GB
      large: "524288"    # 512 GB
      xlarge: "1048576"  # 1 TB
```

### Pattern 5: Conditional Resources

**Create Resources Based on Flags:**

```yaml
# In XRD
spec:
  properties:
    enableMonitoring:
      type: boolean
      default: true

# In Composition - Use readinessChecks to conditionally create
- name: monitoring
  base:
    apiVersion: insights.azure.upbound.io/v1beta1
    kind: ApplicationInsights
  patches:
  - type: FromCompositeFieldPath
    fromFieldPath: spec.enableMonitoring
    policy:
      fromFieldPath: Required  # Only create if true
```

### Pattern 6: Status Propagation

**Copy Important Data to Status:**

```yaml
# Make endpoints available to users
patches:
- type: ToCompositeFieldPath
  fromFieldPath: status.atProvider.fqdn
  toFieldPath: status.endpoint

- type: ToCompositeFieldPath
  fromFieldPath: metadata.annotations[crossplane.io/external-name]
  toFieldPath: status.resourceGroupName

# Connection secrets
- type: ToCompositeFieldPath
  fromFieldPath: status.atProvider.id
  toFieldPath: status.resourceId
```

## 🔒 Security Best Practices

### 1. Never Hardcode Secrets

**Bad - Hardcoded:**

```yaml
spec:
  forProvider:
    administratorLogin: "admin"
    administratorPassword: "P@ssw0rd123"  # NEVER DO THIS
```

**Good - Secret Reference:**

```yaml
spec:
  forProvider:
    administratorLogin: "admin"
    administratorPasswordSecretRef:
      name: postgres-admin-password
      namespace: crossplane-system
      key: password
```

### 2. Use Separate Service Principals

**Per Environment:**

```yaml
# Development
ProviderConfig: dev-azure
Service Principal: crossplane-dev-sp
Permissions: Contributor on dev-rg-*

# Production  
ProviderConfig: prod-azure
Service Principal: crossplane-prod-sp
Permissions: Contributor on prod-rg-*
```

### 3. Implement RBAC

**Namespace Isolation:**

```yaml
# Team A can only create claims in team-a namespace
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: team-a-crossplane
  namespace: team-a
subjects:
- kind: Group
  name: team-a
roleRef:
  kind: ClusterRole
  name: crossplane:claim:creator
```

### 4. Secret Management

**Use External Secrets:**

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: azure-credentials
  namespace: crossplane-system
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: azure-keyvault
    kind: SecretStore
  target:
    name: azure-credentials
  data:
  - secretKey: credentials
    remoteRef:
      key: crossplane-azure-sp
```

## 📊 Operational Best Practices

### 1. Use CompositionRevisions

**Enable Automatic Updates:**

```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: postgres.azure.example.com
  labels:
    channel: stable
spec:
  publishConnectionDetailsWithStoreConfigRef:
    name: default
  revisionActivationPolicy: Automatic  # Auto-update claims
  revisionHistoryLimit: 3              # Keep 3 old versions
```

**Or Manual Control:**

```yaml
spec:
  revisionActivationPolicy: Manual  # Explicit upgrade
```

### 2. Monitor Everything

**Add Monitoring Labels:**

```yaml
spec:
  forProvider:
    tags:
      MonitoringEnabled: "true"
      AlertingEnabled: "true"
      LogRetention: "30"
```

**Prometheus Metrics:**

```yaml
# ServiceMonitor for Crossplane
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: crossplane
spec:
  selector:
    matchLabels:
      app: crossplane
  endpoints:
  - port: metrics
```

### 3. Implement Observability

**Structured Logging:**

```yaml
# Crossplane deployment
env:
- name: POD_NAME
  valueFrom:
    fieldRef:
      fieldPath: metadata.name
- name: POD_NAMESPACE
  valueFrom:
    fieldRef:
      fieldPath: metadata.namespace

args:
- --debug
- --enable-composition-functions
```

**Trace Reconciliation:**

```bash
# View reconciliation logs
kubectl logs -n crossplane-system deployment/crossplane \
  | grep "controller=composite/xpostgresqldatabase"
```

### 4. Health Checks

**Readiness Checks:**

```yaml
- name: database
  readinessChecks:
  - type: MatchString
    fieldPath: status.atProvider.state
    matchString: "Ready"
    
  - type: MatchInteger
    fieldPath: status.atProvider.replicaCount
    matchInteger: 3

  - type: NonEmpty
    fieldPath: status.atProvider.endpoint
```

### 5. Resource Limits

**Set Provider Limits:**

```yaml
# Provider deployment
resources:
  limits:
    cpu: "1"
    memory: "1Gi"
  requests:
    cpu: "100m"
    memory: "128Mi"
```

## 🎯 Performance Optimization

### 1. Optimize Reconciliation

**Reduce Polling:**

```yaml
spec:
  resources:
  - name: database
    base:
      spec:
        managementPolicy: ObserveCreateDelete  # Don't constantly update
```

### 2. Batch Operations

**Use CompositionRevisionSelector:**

```yaml
# Update multiple claims at once
spec:
  compositionRevisionSelector:
    matchLabels:
      version: v2
```

### 3. Cache Provider Credentials

**Reuse Connections:**

```yaml
# ProviderConfig with connection pooling
spec:
  credentials:
    source: Secret
    secretRef:
      name: azure-credentials
  # Provider will cache and reuse connections
```

## 🧪 Testing Best Practices

### 1. Test Pyramid

```
    E2E (10%)        - Full lifecycle
   Integration (20%) - Live cluster  
  Unit/Policy (70%)  - Fast validation
```

### 2. Use Namespaces for Isolation

**Test Namespaces:**

```bash
# Each test gets unique namespace
TEST_NS="test-$(date +%s)"
kubectl create namespace $TEST_NS
kubectl apply -f claim.yaml -n $TEST_NS
# ... test ...
kubectl delete namespace $TEST_NS
```

### 3. Cleanup After Tests

**Always Clean Up:**

```yaml
# Chainsaw test
spec:
  cleanup:
    skipDelete: false  # Always cleanup
  steps:
  - try: [...]
    catch:
    - delete: [...]  # Cleanup even on failure
```

## 📚 Documentation Standards

### 1. README Structure

```markdown
# {XRD Name}

## Purpose
One-line description

## Usage
Basic example

## Parameters
Table of all parameters

## Examples
Common scenarios

## Troubleshooting
Known issues and solutions
```

### 2. Inline Comments

**Comment Complex Logic:**

```yaml
patches:
# Size mapping follows Azure SKU naming
# B_ = Burstable, GP_ = General Purpose
- type: FromCompositeFieldPath
  fromFieldPath: spec.size
  toFieldPath: spec.forProvider.skuName
  transforms:
  - type: map
    map:
      small: "B_Standard_B1ms"   # 1 vCore, 2GB RAM
      medium: "GP_Standard_D2s_v3" # 2 vCore, 8GB RAM
```

### 3. Architecture Decision Records

**Track Major Decisions:**

```markdown
# ADR-001: Use Composition Functions for Complex Logic

## Status
Accepted

## Context
Patching alone is insufficient for conditional logic

## Decision
Use Composition Functions for complex transformations

## Consequences
+ More powerful
+ Better tested
- Requires Go knowledge
- More complex to debug
```

## 🔄 GitOps Integration

### 1. Repository Structure

```
infrastructure/
├── crossplane/
│   ├── providers/
│   ├── xrds/
│   ├── compositions/
│   └── claims/
│       ├── dev/
│       ├── staging/
│       └── prod/
└── argocd/
    └── applications/
```

### 2. ArgoCD Application

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: crossplane-xrds
spec:
  project: platform
  source:
    repoURL: https://github.com/org/infrastructure
    path: crossplane/xrds
    targetRevision: main
  destination:
    server: https://kubernetes.default.svc
  syncPolicy:
    automated:
      prune: false  # Don't auto-delete XRDs
      selfHeal: true
```

### 3. Progressive Rollout

**Canary Deployments:**

```yaml
# Deploy to dev first
spec:
  compositionSelector:
    matchLabels:
      environment: development
      version: v2

# Then staging
spec:
  compositionSelector:
    matchLabels:
      environment: staging
      version: v2

# Finally production  
spec:
  compositionSelector:
    matchLabels:
      environment: production
      version: v2
```

## 🚨 Common Pitfalls

### ❌ Pitfall 1: Too Generic XRDs

**Problem:**

```yaml
# Too generic - works for everything, optimal for nothing
kind: XGenericResource
```

**Solution:**

```yaml
# Specific XRDs for specific use cases
kind: XPostgreSQLDatabase
kind: XAzureStorageAccount
```

### ❌ Pitfall 2: Missing Deletion Policies

**Problem:**

```yaml
# Resources leak when claim is deleted
spec:
  resources:
  - name: database
    # No deletionPolicy!
```

**Solution:**

```yaml
spec:
  resources:
  - name: database
    base:
      spec:
        deletionPolicy: Delete
```

### ❌ Pitfall 3: Hardcoded Values

**Problem:**

```yaml
spec:
  forProvider:
    location: "westeurope"  # Hardcoded!
```

**Solution:**

```yaml
patches:
- type: FromCompositeFieldPath
  fromFieldPath: spec.region
  toFieldPath: spec.forProvider.location
```

### ❌ Pitfall 4: No Status Propagation

**Problem:**

```yaml
# Users can't see endpoints!
# No status information copied from managed resources
```

**Solution:**

```yaml
patches:
- type: ToCompositeFieldPath
  fromFieldPath: status.atProvider.endpoint
  toFieldPath: status.databaseEndpoint
```

### ❌ Pitfall 5: Ignoring Readiness

**Problem:**

```yaml
# How do we know when it's ready?
# No readiness checks
```

**Solution:**

```yaml
readinessChecks:
- type: MatchString
  fieldPath: status.atProvider.state
  matchString: "Ready"
```

## 🎓 Learning Resources

### Official Documentation

- [Crossplane Docs](https://docs.crossplane.io/)
- [Composition Functions](https://docs.crossplane.io/latest/concepts/composition-functions/)
- [Provider Azure](https://marketplace.upbound.io/providers/upbound/provider-azure/)

### Community Resources

- [Crossplane Slack](https://slack.crossplane.io/)
- [GitHub Discussions](https://github.com/crossplane/crossplane/discussions)
- [Upbound Blog](https://blog.upbound.io/)

### Example Repositories

- [Upbound Reference Platform](https://github.com/upbound/platform-ref-azure)
- [Crossplane Examples](https://github.com/crossplane/crossplane/tree/master/docs/snippets)

## 🎯 Quick Reference

### When to Create New XRD

✅ **Create New XRD When:**

- Different resource types (database vs storage)
- Different use cases (OLTP vs OLAP database)
- Different teams/ownership
- Different lifecycle

❌ **Don’t Create New XRD For:**

- Different sizes (use parameters)
- Different environments (use parameters)
- Different regions (use parameters)

### Composition vs Configuration

**Composition:**

- How resources are created
- Infrastructure patterns
- Platform team manages

**Configuration (Claims):**

- What users want
- Application requirements
- Developers manage

-----

**Remember:** Best practices evolve. What works for a 5-person team may not work for 50. Start simple, iterate based on feedback, and always optimize for your team’s needs.

**“Perfect is the enemy of good. Ship it, learn, improve.”** 🚀
