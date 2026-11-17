# ==============================================================================
# IDP Local Mac - Comandos Rápidos
# ==============================================================================

# 1. Iniciar Docker Desktop y tener kind
open -a Docker
brew install kind

# 2. Levantar todo el entorno local (Kind 4 nodos + ArgoCD + App of Apps)
make up-local

# 3. Verificar estado de los nodos
kubectl get nodes --show-labels

# 4. Verificar aplicaciones de ArgoCD
kubectl get applications -n argocd

# ------------------------------------------------------------------------------
# Accesos locales:
# ------------------------------------------------------------------------------
# ArgoCD UI:
#   URL: http://localhost:30080
#   Usuario: admin
#   Password: Se imprime al final de 'make up-local' o recuperar con:
#   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
#
# Demo Ingress:
#   URL: http://localhost/hello
# ------------------------------------------------------------------------------

# 5. Destruir clúster local cuando termines
make down-local
