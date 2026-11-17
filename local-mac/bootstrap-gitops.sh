#!/usr/bin/env bash
# ==============================================================================
# Script: bootstrap-gitops.sh
# Purpose: Bootstrap ArgoCD on local Kind cluster with IDP Core Stack in local-mac/apps
# ==============================================================================
set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
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
kubectl patch cm argocd-cmd-params-cm -n argocd --type merge -p '{"data": {"server.insecure": "true"}}' || true

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

# Pre-apply local applications directly so initial sync is immediate
echo -e "${GREEN}[INFO] Pre-applying IDP Core Platform applications...${NC}"
kubectl create namespace alloy --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace backstage --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f local-mac/secrets/grafana-cloud-secret.yaml 2>/dev/null || true
kubectl apply -f local-mac/apps/ingress-nginx.yaml || true
kubectl apply -f local-mac/apps/external-secrets.yaml || true
kubectl apply -f local-mac/apps/crossplane.yaml || true
kubectl apply -f local-mac/apps/kyverno.yaml || true
kubectl apply -f local-mac/apps/argo-rollouts.yaml || true
kubectl apply -f local-mac/apps/grafana-alloy.yaml || true
kubectl apply -f local-mac/apps/backstage.yaml || true
kubectl apply -f local-mac/manifests/backstage/all.yaml || true
kubectl apply -f local-mac/apps/argocd-ingress.yaml || true
kubectl apply -f local-mac/manifests/argocd/ingress.yaml || true
kubectl apply -f local-mac/policies/idp-guardrails.yaml || true

echo -e "${GREEN}${BOLD}========================================================================${NC}"
echo -e "${GREEN}${BOLD}  ArgoCD Local IDP Core Bootstrap Completed!${NC}"
echo -e "${GREEN}${BOLD}========================================================================${NC}"
echo -e " 🚀 ArgoCD UI:       ${YELLOW}http://argocd.local${NC} (o http://localhost:30080)"
echo -e " 🧭 Backstage UI:    ${YELLOW}http://backstage.local${NC} (o http://localhost)"
echo -e " 👤 Username:        ${YELLOW}admin${NC}"
echo -e " 🔑 Password:        ${YELLOW}${ADMIN_PASS}${NC}"
echo -e " 📦 Monitored Repo:  ${YELLOW}${GITOPS_REPO}${NC}"
echo -e " 📁 Apps Path:       ${YELLOW}local-mac/apps${NC}"
echo -e "${CYAN}${BOLD}------------------------------------------------------------------------${NC}"
echo -e "${CYAN}${BOLD}  IDP Core Platform Stack Managed via GitOps:${NC}"
echo -e "  ✔ Ingress-Nginx    (Local Gateway / Ports 80 & 443)"
echo -e "  ✔ Backstage Portal (Developer Portal / http://localhost/portal)"
echo -e "  ✔ External-Secrets (Secrets Management & Zero Secret in Git)"
echo -e "  ✔ Crossplane       (Infrastructure Control Plane & Self-Service API)"
echo -e "  ✔ Kyverno          (Policy as Code & Security Guardrails)"
echo -e "  ✔ Argo Rollouts    (Progressive Delivery: Canary & Blue/Green)"
echo -e "  ✔ Grafana Alloy    (OpenTelemetry Collector for Grafana Cloud)"
echo -e "${GREEN}${BOLD}========================================================================${NC}"
