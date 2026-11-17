# ==============================================================================
# IDP Local Mac - Comandos Rápidos
# ==============================================================================

# 1. Iniciar Docker Desktop y tener kind
open -a Docker
brew install kind

# 2. Levantar todo el entorno local (Kind 4 nodos + ArgoCD + IDP Core Stack)
make up-local

# 3. Sincronizar cambios en Git (para que ArgoCD tome los nuevos componentes)
git add .
git commit -m "feat: add kyverno, argo-rollouts, grafana-alloy and github actions"
git push origin main

# 4. Verificar estado del clúster y componentes IDP
kubectl get nodes --show-labels
kubectl get applications -n argocd
kubectl get clusterpolicies
kubectl get pods -n argo-rollouts
kubectl get pods -n alloy

# ------------------------------------------------------------------------------
# Configuración de Dominios Locales (ejecutar una sola vez en Mac):
# sudo sh -c 'echo "127.0.0.1 backstage.local argocd.local" >> /etc/hosts'
# ------------------------------------------------------------------------------
# Accesos locales:
# ------------------------------------------------------------------------------
# Backstage Developer Portal:
#   URL: http://backstage.local (o http://localhost vía Ingress)
#   O directo sin Ingress:
#   kubectl port-forward svc/backstage -n backstage 7007:7007 (en http://localhost:7007)
#
# ArgoCD UI:
#   URL: http://argocd.local (vía Ingress en puerto 80)
#   O directo vía NodePort: http://localhost:30080
#   Usuario: admin
#   Password: Se imprime al final de 'make up-local' o recuperar con:
#   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
#
# Argo Rollouts Dashboard (Canary / Blue-Green UI):
#   kubectl argo rollouts dashboard -n argo-rollouts (acceso en http://localhost:3100)
#
# Grafana Alloy (Prometheus Remote Write a Grafana Cloud):
#   Edita tus credenciales en local-mac/secrets/grafana-cloud-secret.yaml y aplica:
#   kubectl apply -f local-mac/secrets/grafana-cloud-secret.yaml
# ------------------------------------------------------------------------------

# 5. Destruir clúster local cuando termines
make down-local
