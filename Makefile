# ==============================================================================
# IDP Infra Core - Master Automation Makefile
# Platform Engineering standard workflows
# ==============================================================================

SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

# Colors for terminal output
BOLD    := \033[1m
GREEN   := \033[0;32m
BLUE    := \033[0;34m
YELLOW  := \033[1;33m
RED     := \033[0;31m
CYAN    := \033[0;36m
RESET   := \033[0m

DEV_ENV_DIR  := environments/01-dev-gcp-hybrid
PROD_ENV_DIR := environments/02-prod-multicloud-ha
ANSIBLE_DIR  := ansible

.PHONY: help
help: ## Show this help message and list of available targets
	@echo -e "${BOLD}${BLUE}========================================================================${RESET}"
	@echo -e "${BOLD}${BLUE}  Internal Developer Platform (IDP) - Infrastructure Core Commands     ${RESET}"
	@echo -e "${BOLD}${BLUE}========================================================================${RESET}"
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  ${CYAN}%-26s${RESET} %s\n", $$1, $$2}'
	@echo -e "${BOLD}${BLUE}========================================================================${RESET}"

# ------------------------------------------------------------------------------
# LOCAL DEVELOPMENT (macOS with Docker Desktop)
# ------------------------------------------------------------------------------
.PHONY: up-local
up-local: ## Launch local environment (Kind 4-node cluster on Docker Desktop + ArgoCD)
	@echo -e "${GREEN}==> Step 1: Checking Docker Desktop status...${RESET}"
	@docker info >/dev/null 2>&1 || { echo -e "${RED}[ERROR] Docker daemon is not running. Please start Docker Desktop with: open -a Docker${RESET}"; exit 1; }
	@echo -e "${GREEN}==> Step 2: Checking Kind CLI...${RESET}"
	@command -v kind >/dev/null 2>&1 || { echo -e "${RED}[ERROR] 'kind' is not installed. Install it with: brew install kind${RESET}"; exit 1; }
	@echo -e "${GREEN}==> Step 3: Creating Kind multi-node cluster (idp-local-core)...${RESET}"
	@if kind get clusters 2>/dev/null | grep -q "^idp-local-core$$"; then \
		echo -e "${YELLOW}Kind cluster 'idp-local-core' already exists. Skipping creation.${RESET}"; \
	else \
		kind create cluster --config local-mac/kind-config.yaml; \
	fi
	@echo -e "${GREEN}==> Step 4: Bootstrapping ArgoCD GitOps Engine...${RESET}"
	@./local-mac/bootstrap-gitops.sh

.PHONY: down-local
down-local: ## Tear down local Kind cluster
	@echo -e "${RED}==> Deleting Kind cluster 'idp-local-core'...${RESET}"
	@kind delete cluster --name idp-local-core || true
	@echo -e "${GREEN}Local environment cleaned up.${RESET}"

# ------------------------------------------------------------------------------
# ENVIRONMENT 2 & 3: DEV GCP HYBRID (Terragrunt Orchestration)
# ------------------------------------------------------------------------------
.PHONY: init-dev-gcp
init-dev-gcp: ## Initialize Terragrunt for 01-dev-gcp-hybrid (VPC, GKE, OnPrem GCE)
	@echo -e "${BLUE}==> Initializing Terragrunt for Dev GCP Hybrid...${RESET}"
	@terragrunt run-all init --terragrunt-working-dir $(DEV_ENV_DIR)

.PHONY: plan-dev-gcp
plan-dev-gcp: ## Run Terragrunt Plan for 01-dev-gcp-hybrid
	@echo -e "${BLUE}==> Planning Terragrunt for Dev GCP Hybrid...${RESET}"
	@terragrunt run-all plan --terragrunt-working-dir $(DEV_ENV_DIR)

.PHONY: up-dev-gcp
up-dev-gcp: ## Provision Dev GCP Hybrid via Terragrunt (resolves dependencies automatically)
	@echo -e "${GREEN}==> Applying Terragrunt for Dev GCP Hybrid...${RESET}"
	@terragrunt run-all apply --terragrunt-working-dir $(DEV_ENV_DIR) --terragrunt-non-interactive
	@echo -e "${GREEN}==> Infrastructure created! Ansible inventory generated at ansible/inventories/gce-onprem-sim/hosts.ini${RESET}"

.PHONY: destroy-dev-gcp
destroy-dev-gcp: ## Destroy 01-dev-gcp-hybrid infrastructure via Terragrunt
	@echo -e "${RED}==> Destroying Dev GCP Hybrid environment...${RESET}"
	@terragrunt run-all destroy --terragrunt-working-dir $(DEV_ENV_DIR) --terragrunt-non-interactive

# ------------------------------------------------------------------------------
# ANSIBLE & KUBESPRAY WORKFLOWS (Simulated On-Premises Bare-Metal)
# ------------------------------------------------------------------------------
.PHONY: ansible-bootstrap-onprem
ansible-bootstrap-onprem: ## Harden and prepare simulated bare-metal nodes (containerd, kernel modules, swapoff)
	@echo -e "${BLUE}==> Running OS bootstrap and hardening playbook...${RESET}"
	@ansible-playbook -i $(ANSIBLE_DIR)/inventories/gce-onprem-sim/hosts.ini $(ANSIBLE_DIR)/playbooks/bootstrap-nodes.yml

.PHONY: ansible-kubespray-onprem
ansible-kubespray-onprem: ## Deploy production-ready Kubernetes onto bare-metal nodes using Kubespray
	@echo -e "${BLUE}==> Deploying Kubernetes via Kubespray...${RESET}"
	@ansible-playbook -i $(ANSIBLE_DIR)/inventories/gce-onprem-sim/hosts.ini $(ANSIBLE_DIR)/playbooks/deploy-kubespray.yml

# ------------------------------------------------------------------------------
# ENVIRONMENT 4: PROD MULTI-CLOUD HA (Terragrunt Orchestration)
# ------------------------------------------------------------------------------
.PHONY: init-prod-hybrid
init-prod-hybrid: ## Initialize Terragrunt for 02-prod-multicloud-ha
	@echo -e "${BLUE}==> Initializing Terragrunt for Prod Multi-cloud HA...${RESET}"
	@terragrunt run-all init --terragrunt-working-dir $(PROD_ENV_DIR)

.PHONY: plan-prod-hybrid
plan-prod-hybrid: ## Run Terragrunt Plan for 02-prod-multicloud-ha
	@echo -e "${BLUE}==> Planning Terragrunt for Prod Multi-cloud HA...${RESET}"
	@terragrunt run-all plan --terragrunt-working-dir $(PROD_ENV_DIR)

.PHONY: up-prod-hybrid
up-prod-hybrid: ## Provision Prod Multi-cloud HA via Terragrunt (GKE, AWS EKS, HA VPN)
	@echo -e "${GREEN}==> Applying Terragrunt for Prod Multi-cloud HA...${RESET}"
	@terragrunt run-all apply --terragrunt-working-dir $(PROD_ENV_DIR) --terragrunt-non-interactive

.PHONY: destroy-prod-hybrid
destroy-prod-hybrid: ## Destroy 02-prod-multicloud-ha infrastructure via Terragrunt
	@echo -e "${RED}==> Destroying Prod Multi-cloud HA environment...${RESET}"
	@terragrunt run-all destroy --terragrunt-working-dir $(PROD_ENV_DIR) --terragrunt-non-interactive

# ------------------------------------------------------------------------------
# CODE QUALITY & FORMATTING
# ------------------------------------------------------------------------------
.PHONY: fmt
fmt: ## Format Terraform and Terragrunt HCL files across all modules and environments
	@echo -e "${BLUE}==> Formatting Terraform & Terragrunt files...${RESET}"
	@terraform fmt -recursive .
	@terragrunt hcl format

.PHONY: lint
lint: fmt ## Run linting checks across Terraform and Terragrunt
	@echo -e "${BLUE}==> Checking formatting...${RESET}"
	@terraform fmt -check -recursive .

