# Repository Organization Guide

> How to organize these 25 files into your GitHub repository structure

## 📁 Recommended Directory Structure

After cloning/creating your repository, organize files into this structure:

```
learning-crossplane-test-driven-development/
├── README.md                                    # Already created ✅
├── GETTING_STARTED.md                          # Already created ✅
├── FILE_INDEX.md                               # Already created ✅
├── SUMMARY.md                                  # Already created ✅
│
├── docs/
│   ├── 01-tdd-principles.md                   # To create (optional)
│   ├── 02-testing-strategy.md                 # To create (optional)
│   ├── 03-tooling.md                          # To create (optional)
│   └── 04-best-practices.md                   # To create (optional)
│
├── environments/
│   └── minikube/
│       ├── setup.sh                           # = minikube-setup.sh
│       ├── crossplane-install.sh              # Already created ✅
│       └── provider-install.sh                # Already created ✅
│
├── scripts/
│   ├── generate/
│   │   ├── generate-xrd.sh                    # Already created ✅
│   │   ├── generate-composition.sh            # Already created ✅
│   │   └── generate-claim.sh                  # Already created ✅
│   │
│   ├── validate/
│   │   └── validate-policies.sh               # Already created ✅
│   │
│   └── test/
│       ├── run-unit-tests.sh                  # Already created ✅
│       ├── run-integration-tests.sh           # Already created ✅
│       ├── run-e2e-tests.sh                   # Already created ✅
│       └── tdd-workflow.sh                    # Already created ✅
│
├── crossplane/
│   ├── providers/
│   │   └── providerconfig-azure.yaml          # Already created ✅
│   │
│   ├── xrds/
│   │   └── developer-combo/
│   │       ├── xrd.yaml                       # Already created ✅
│   │       └── examples/
│   │           └── small-claim.yaml           # From example-claims.yaml
│   │
│   └── compositions/
│       └── developer-combo/
│           └── azure-composition.yaml         # Already created ✅
│
├── templates/
│   ├── xrd-template.yaml                      # Already created ✅
│   └── composition-template.yaml              # Already created ✅
│
├── tests/
│   ├── unit/
│   │   └── policies/
│   │       └── crossplane.rego                # = crossplane-policies.rego
│   │
│   └── e2e/
│       └── chainsaw/
│           └── developer-combo-test.yaml      # Already created ✅
│
└── tools/
    ├── conftest/
    │   └── policy/
    │       └── crossplane.rego                # = crossplane-policies.rego
    │
    └── kyverno/
        └── policies/
            └── crossplane-policies.yaml       # = kyverno-policies.yaml
```

## 🔄 File Mapping

### Current → Target Location

```bash
# Documentation (keep at root)
README.md                    → ./README.md
GETTING_STARTED.md           → ./GETTING_STARTED.md
FILE_INDEX.md                → ./FILE_INDEX.md
SUMMARY.md                   → ./SUMMARY.md

# Environment Setup
minikube-setup.sh            → ./environments/minikube/setup.sh
crossplane-install.sh        → ./environments/minikube/crossplane-install.sh
provider-install.sh          → ./environments/minikube/provider-install.sh

# Generation Scripts
generate-xrd.sh              → ./scripts/generate/generate-xrd.sh
generate-composition.sh      → ./scripts/generate/generate-composition.sh
generate-claim.sh            → ./scripts/generate/generate-claim.sh

# Validation Scripts
validate-policies.sh         → ./scripts/validate/validate-policies.sh

# Test Scripts
run-unit-tests.sh            → ./scripts/test/run-unit-tests.sh
run-integration-tests.sh     → ./scripts/test/run-integration-tests.sh
run-e2e-tests.sh             → ./scripts/test/run-e2e-tests.sh
tdd-workflow.sh              → ./scripts/test/tdd-workflow.sh

# Crossplane Configurations
providerconfig-azure.yaml    → ./crossplane/providers/providerconfig-azure.yaml
xrd.yaml                     → ./crossplane/xrds/developer-combo/xrd.yaml
azure-composition.yaml       → ./crossplane/compositions/developer-combo/azure-composition.yaml
example-claims.yaml          → Split into ./crossplane/xrds/developer-combo/examples/
                               (small-claim.yaml, medium-claim.yaml, large-claim.yaml)

# Templates
xrd-template.yaml            → ./templates/xrd-template.yaml
composition-template.yaml    → ./templates/composition-template.yaml

# Policies
crossplane-policies.rego     → ./tools/conftest/policy/crossplane.rego
                               AND ./tests/unit/policies/crossplane.rego (copy)
kyverno-policies.yaml        → ./tools/kyverno/policies/crossplane-policies.yaml

# Tests
developer-combo-test.yaml    → ./tests/e2e/chainsaw/developer-combo-test.yaml
```

## 🚀 Organization Commands

### Option 1: Automated Script

Create and run this script in the repository root:

```bash
#!/bin/bash
# organize-repo.sh - Automatically organize repository structure

set -e

echo "📁 Creating directory structure..."

# Create directories
mkdir -p docs
mkdir -p environments/minikube
mkdir -p scripts/{generate,validate,test}
mkdir -p crossplane/{providers,xrds/developer-combo/examples,compositions/developer-combo}
mkdir -p templates
mkdir -p tests/{unit/policies,e2e/chainsaw}
mkdir -p tools/{conftest/policy,kyverno/policies}

echo "📦 Moving files to correct locations..."

# Documentation (already at root, no move needed)

# Environment setup
mv minikube-setup.sh environments/minikube/setup.sh 2>/dev/null || true
cp crossplane-install.sh environments/minikube/ 2>/dev/null || true
cp provider-install.sh environments/minikube/ 2>/dev/null || true

# Scripts
mv generate-*.sh scripts/generate/ 2>/dev/null || true
mv validate-*.sh scripts/validate/ 2>/dev/null || true
mv run-*.sh scripts/test/ 2>/dev/null || true
mv tdd-workflow.sh scripts/test/ 2>/dev/null || true

# Crossplane configs
mv providerconfig-azure.yaml crossplane/providers/ 2>/dev/null || true
mv xrd.yaml crossplane/xrds/developer-combo/ 2>/dev/null || true
mv azure-composition.yaml crossplane/compositions/developer-combo/ 2>/dev/null || true

# Split example-claims.yaml into separate files
if [ -f "example-claims.yaml" ]; then
  yq eval 'select(documentIndex == 0)' example-claims.yaml > crossplane/xrds/developer-combo/examples/small-claim.yaml
  yq eval 'select(documentIndex == 1)' example-claims.yaml > crossplane/xrds/developer-combo/examples/medium-claim.yaml
  yq eval 'select(documentIndex == 2)' example-claims.yaml > crossplane/xrds/developer-combo/examples/large-claim.yaml
  rm example-claims.yaml
fi

# Templates
mv *-template.yaml templates/ 2>/dev/null || true

# Policies
cp crossplane-policies.rego tools/conftest/policy/crossplane.rego 2>/dev/null || true
mv crossplane-policies.rego tests/unit/policies/crossplane.rego 2>/dev/null || true
mv kyverno-policies.yaml tools/kyverno/policies/crossplane-policies.yaml 2>/dev/null || true

# Tests
mv developer-combo-test.yaml tests/e2e/chainsaw/ 2>/dev/null || true

# Make scripts executable
chmod +x environments/minikube/*.sh
chmod +x scripts/**/*.sh

echo "✅ Repository organized!"
echo ""
echo "📊 Structure:"
tree -L 3 -I '.git'
```

### Option 2: Manual Organization

If you prefer manual organization:

```bash
# 1. Create directories
mkdir -p environments/minikube scripts/{generate,validate,test} \
  crossplane/{providers,xrds/developer-combo/examples,compositions/developer-combo} \
  templates tests/{unit/policies,e2e/chainsaw} \
  tools/{conftest/policy,kyverno/policies}

# 2. Move environment files
mv minikube-setup.sh environments/minikube/setup.sh
mv crossplane-install.sh environments/minikube/
mv provider-install.sh environments/minikube/

# 3. Move scripts
mv generate-*.sh scripts/generate/
mv validate-*.sh scripts/validate/
mv run-*.sh tdd-workflow.sh scripts/test/

# 4. Move Crossplane configs
mv providerconfig-azure.yaml crossplane/providers/
mv xrd.yaml crossplane/xrds/developer-combo/
mv azure-composition.yaml crossplane/compositions/developer-combo/

# 5. Split claims (if yq installed)
yq eval 'select(documentIndex == 0)' example-claims.yaml > crossplane/xrds/developer-combo/examples/small-claim.yaml
yq eval 'select(documentIndex == 1)' example-claims.yaml > crossplane/xrds/developer-combo/examples/medium-claim.yaml
yq eval 'select(documentIndex == 2)' example-claims.yaml > crossplane/xrds/developer-combo/examples/large-claim.yaml

# 6. Move templates
mv *-template.yaml templates/

# 7. Move policies
cp crossplane-policies.rego tools/conftest/policy/crossplane.rego
mv crossplane-policies.rego tests/unit/policies/crossplane.rego
mv kyverno-policies.yaml tools/kyverno/policies/crossplane-policies.yaml

# 8. Move tests
mv developer-combo-test.yaml tests/e2e/chainsaw/

# 9. Make executable
chmod +x environments/minikube/*.sh scripts/**/*.sh
```

## ✅ Verification

After organization, verify the structure:

```bash
# Check directory structure
tree -L 3

# Verify all scripts are executable
find . -name "*.sh" -type f -exec ls -lh {} \;

# Verify file count
find . -type f | wc -l  # Should be 25+

# Run quick validation
./scripts/test/run-unit-tests.sh
```

## 📝 Update Path References

After moving files, update these path references in scripts:

### In all test scripts:

```bash
# Old
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# New
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
```

### In generation scripts:

```bash
# Update OUTPUT_DIR paths
OUTPUT_DIR="${PROJECT_ROOT}/crossplane/xrds/${COMBO_NAME}"
OUTPUT_DIR="${PROJECT_ROOT}/crossplane/compositions/${COMBO_NAME}"
OUTPUT_DIR="${PROJECT_ROOT}/crossplane/xrds/developer-combo/examples"
```

### In documentation:

```bash
# Update all command examples in README.md and GETTING_STARTED.md
# Old: ./minikube-setup.sh
# New: ./environments/minikube/setup.sh

# Old: ./generate-xrd.sh
# New: ./scripts/generate/generate-xrd.sh
```

## 🔧 Quick Fixes

If scripts don’t work after moving:

```bash
# Option 1: Create convenience symlinks at root
ln -s environments/minikube/setup.sh minikube-setup.sh
ln -s scripts/test/run-unit-tests.sh run-unit-tests.sh

# Option 2: Add scripts to PATH
export PATH="${PWD}/scripts/generate:${PWD}/scripts/test:${PATH}"

# Option 3: Use make/task runner
# Create Makefile with common commands
```

## 📋 Final Checklist

- [ ] All directories created
- [ ] All files moved to correct locations
- [ ] Scripts are executable (`chmod +x`)
- [ ] Path references updated in scripts
- [ ] Documentation updated with new paths
- [ ] Tests run successfully
- [ ] README examples updated
- [ ] Git repository initialized
- [ ] .gitignore created (exclude .DS_Store, *.swp, etc.)
- [ ] Initial commit made

## 🎯 Ready for GitHub

Once organized:

```bash
# Initialize Git
git init

# Create .gitignore
cat > .gitignore <<EOL
.DS_Store
*.swp
*.log
.idea/
.vscode/
EOL

# Add all files
git add .

# Initial commit
git commit -m "Initial commit: Complete Crossplane TDD repository

- 25+ files covering TDD workflow
- Full test suite (unit, integration, E2E)
- YQ-based generation scripts
- Policy validation (Conftest + Kyverno)
- Complete documentation
- Fast Food Restaurant metaphor throughout"

# Add remote
git remote add origin https://github.com/vanHeemstraSystems/learning-crossplane-test-driven-development.git

# Push
git push -u origin main
```

-----

**Happy organizing! 🎉**
