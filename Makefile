# Makefile for Crossplane TDD
# Convenience wrapper for common tasks

.PHONY: help setup install-crossplane install-providers test test-unit test-integration test-e2e validate clean

# Default target
.DEFAULT_GOAL := help

## help: Display this help message
help:
	@echo "Crossplane TDD - Available Commands"
	@echo "===================================="
	@echo ""
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/## /  /' | column -t -s ':'
	@echo ""
	@echo "Examples:"
	@echo "  make setup              # Complete environment setup"
	@echo "  make test               # Run all tests"
	@echo "  make test-unit          # Run only unit tests"
	@echo "  make generate-xrd XRD=myapp  # Generate new XRD"

## setup: Complete environment setup (Minikube + Crossplane + Providers)
setup: setup-minikube install-crossplane install-providers
	@echo "✅ Environment setup complete!"
	@echo ""
	@echo "Next steps:"
	@echo "1. Configure Azure credentials"
	@echo "2. Apply XRD: make apply-xrd"
	@echo "3. Apply Composition: make apply-composition"
	@echo "4. Create a claim: make create-claim SIZE=small"

## setup-minikube: Start Minikube cluster
setup-minikube:
	@echo "🚀 Starting Minikube cluster..."
	./environments/minikube/setup.sh

## install-crossplane: Install Crossplane
install-crossplane:
	@echo "📦 Installing Crossplane..."
	./environments/minikube/crossplane-install.sh

## install-providers: Install Azure providers
install-providers:
	@echo "☁️ Installing Azure providers..."
	./environments/minikube/provider-install.sh

## test: Run all tests (unit + integration + e2e)
test: test-unit test-integration test-e2e
	@echo "✅ All tests complete!"

## test-unit: Run unit tests
test-unit:
	@echo "🧪 Running unit tests..."
	./scripts/test/run-unit-tests.sh

## test-integration: Run integration tests
test-integration:
	@echo "🔗 Running integration tests..."
	./scripts/test/run-integration-tests.sh developer-combo small

## test-e2e: Run end-to-end tests
test-e2e:
	@echo "🎬 Running E2E tests..."
	./scripts/test/run-e2e-tests.sh

## validate: Run policy validation
validate:
	@echo "🔍 Validating policies..."
	./scripts/validate/validate-policies.sh

## tdd: Run complete TDD workflow
tdd:
	@echo "🔴🟢🔵 Running TDD workflow..."
	./scripts/test/tdd-workflow.sh

## apply-xrd: Apply Developer Combo XRD
apply-xrd:
	@echo "📋 Applying XRD..."
	kubectl apply -f crossplane/xrds/developer-combo/xrd.yaml

## apply-composition: Apply Azure Composition
apply-composition:
	@echo "👨‍🍳 Applying Composition..."
	kubectl apply -f crossplane/compositions/developer-combo/azure-composition.yaml

## create-claim: Create a claim (usage: make create-claim SIZE=small)
create-claim:
	@echo "🛒 Creating claim (size: $(SIZE))..."
	@if [ -z "$(SIZE)" ]; then \
		echo "❌ Error: SIZE not specified"; \
		echo "Usage: make create-claim SIZE=small|medium|large"; \
		exit 1; \
	fi
	kubectl apply -f crossplane/xrds/developer-combo/examples/$(SIZE)-claim.yaml

## generate-xrd: Generate new XRD (usage: make generate-xrd XRD=myapp)
generate-xrd:
	@if [ -z "$(XRD)" ]; then \
		echo "❌ Error: XRD not specified"; \
		echo "Usage: make generate-xrd XRD=myapp"; \
		exit 1; \
	fi
	@echo "🏗️ Generating XRD: $(XRD)..."
	./scripts/generate/generate-xrd.sh $(XRD) example.com

## generate-composition: Generate new Composition (usage: make generate-composition COMP=myapp)
generate-composition:
	@if [ -z "$(COMP)" ]; then \
		echo "❌ Error: COMP not specified"; \
		echo "Usage: make generate-composition COMP=myapp"; \
		exit 1; \
	fi
	@echo "📝 Generating Composition: $(COMP)..."
	./scripts/generate/generate-composition.sh $(COMP) azure

## generate-claim: Generate new Claim (usage: make generate-claim APP=myapp ENV=dev SIZE=small)
generate-claim:
	@if [ -z "$(APP)" ] || [ -z "$(ENV)" ] || [ -z "$(SIZE)" ]; then \
		echo "❌ Error: Missing parameters"; \
		echo "Usage: make generate-claim APP=myapp ENV=dev SIZE=small"; \
		exit 1; \
	fi
	@echo "🎫 Generating Claim..."
	./scripts/generate/generate-claim.sh $(APP) $(ENV) $(SIZE)

## status: Check cluster and Crossplane status
status:
	@echo "📊 Cluster Status"
	@echo "================"
	@echo ""
	@echo "Minikube:"
	@minikube status -p crossplane-tdd || echo "Cluster not running"
	@echo ""
	@echo "Crossplane:"
	@kubectl get pods -n crossplane-system || echo "Crossplane not installed"
	@echo ""
	@echo "Providers:"
	@kubectl get providers || echo "No providers installed"
	@echo ""
	@echo "Claims:"
	@kubectl get developercombo --all-namespaces || echo "No claims found"

## logs: View Crossplane logs
logs:
	@echo "📜 Crossplane Logs"
	@echo "=================="
	kubectl logs -n crossplane-system deployment/crossplane --tail=100 -f

## clean: Delete all test claims
clean:
	@echo "🧹 Cleaning up test claims..."
	kubectl delete developercombo --all --all-namespaces || echo "No claims to delete"

## clean-cluster: Delete Minikube cluster
clean-cluster:
	@echo "⚠️  Deleting Minikube cluster..."
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		minikube delete -p crossplane-tdd; \
	fi

## install-tools: Install required tools (macOS only)
install-tools:
	@echo "🛠️ Installing tools (macOS)..."
	@command -v brew >/dev/null 2>&1 || { echo "❌ Homebrew not installed"; exit 1; }
	brew install yq kubectl helm minikube
	@echo "Installing conftest..."
	brew install conftest
	@echo "✅ Tools installed!"

## docs: Open documentation in browser
docs:
	@echo "📚 Opening documentation..."
	@open README.md || xdg-open README.md || echo "Please open README.md manually"

## fmt: Format YAML files
fmt:
	@echo "✨ Formatting YAML files..."
	@find crossplane -name "*.yaml" -exec yq eval -i '.' {} \;
	@echo "✅ Formatting complete!"

## lint: Lint YAML files
lint:
	@echo "🔍 Linting YAML files..."
	@find crossplane -name "*.yaml" -exec yq eval 'explode(.)' {} \; > /dev/null
	@echo "✅ All YAML files are valid!"
