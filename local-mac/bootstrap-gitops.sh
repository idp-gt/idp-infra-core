#!/usr/bin/env bash
# ==============================================================================
# Script: bootstrap-gitops.sh
# Purpose: Bootstrap ArgoCD on local Kind cluster with App of Apps in local-mac/apps
# ==============================================================================
set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}${BOLD}==> [IDP Local] Bootstrapping ArgoCD (GitOps Engine)...${NC}"

# Verify cluster connection
if ! kubectl cluster-info >/dev/null 2>&1; then
  echo -e "${RED}[ERROR] Cannot connect to Kubernetes cluster. Make sure Kind is running.${NC}"
  echo -e "Run: ${YELLOW}make up-local${NC}"
  exit 1
fi

ARGOCD_VERSION="v2.11.3"

# Auto-detect git remote URL or use default
AUTO_REPO=$(git config --get remote.origin.url 2>/dev/null || true)
if [ -z "$AUTO_REPO" ]; then
  GITOPS_REPO_DEFAULT="https://github.com/idp-gt/idp-infra-core.git"
else
  # Convert git@github.com:org/repo.git to https://github.com/org/repo.git for anonymous ArgoCD access
  GITOPS_REPO_DEFAULT=$(echo "$AUTO_REPO" | sed -E 's|^git@github.com:|https://github.com/|')
fi

GITOPS_REPO="${1:-$GITOPS_REPO_DEFAULT}"

echo -e "${GREEN}[INFO] Creating argocd namespace...${NC}"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

echo -e "${GREEN}[INFO] Applying ArgoCD manifests (${ARGOCD_VERSION})...${NC}"
kubectl apply -n argocd -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml"

echo -e "${BLUE}[INFO] Waiting for ArgoCD server deployment to be ready...${NC}"
kubectl rollout status deployment/argocd-server -n argocd --timeout=180s

echo -e "${BLUE}[INFO] Patching argocd-server service to NodePort for local access (Port 30080)...${NC}"
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort", "ports": [{"port": 80, "targetPort": 8080, "nodePort": 30080}]}}' || true

# Wait for initial admin secret
echo -e "${BLUE}[INFO] Retrieving initial admin password...${NC}"
sleep 3
ADMIN_PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d 2>/dev/null || echo "admin")

# Create Root Application (App of Apps pattern) targeting local-mac/apps
echo -e "${GREEN}[INFO] Registering Root Application targeting ${GITOPS_REPO} (path: local-mac/apps)...${NC}"
cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: idp-local-root
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: '${GITOPS_REPO}'
    targetRevision: HEAD
    path: local-mac/apps
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF

# Pre-apply local applications directly so Ingress Nginx starts immediately without waiting for git sync
echo -e "${GREEN}[INFO] Deploying local apps (Ingress-Nginx & Demo)...${NC}"
kubectl apply -f local-mac/apps/ingress-nginx.yaml || true
kubectl apply -f local-mac/apps/demo-hello.yaml || true
kubectl apply -f local-mac/apps/manifests/demo-hello/all.yaml || true

echo -e "${GREEN}${BOLD}========================================================================${NC}"
echo -e "${GREEN}${BOLD}  ArgoCD Local GitOps Bootstrap Completed!${NC}"
echo -e "${GREEN}${BOLD}========================================================================${NC}"
echo -e " 🚀 ArgoCD UI:       ${YELLOW}http://localhost:30080${NC}"
echo -e " 👤 Username:        ${YELLOW}admin${NC}"
echo -e " 🔑 Password:        ${YELLOW}${ADMIN_PASS}${NC}"
echo -e " 📦 Monitored Repo:  ${YELLOW}${GITOPS_REPO}${NC}"
echo -e " 📁 Apps Path:       ${YELLOW}local-mac/apps${NC}"
echo -e " 🌐 Test Ingress:    ${YELLOW}http://localhost/hello${NC}"
echo -e "${GREEN}${BOLD}========================================================================${NC}"
