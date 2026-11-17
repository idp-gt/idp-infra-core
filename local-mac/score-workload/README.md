# Demostración de Score en el IDP 🎯

Este directorio muestra cómo los desarrolladores interactúan con la plataforma mediante el estándar **Score (`score.yaml`)**.

---

## 💡 ¿Por qué Score no es un pod en el clúster?

* **ArgoCD, Crossplane, Kyverno y Backstage** son **servicios de infraestructura** (corren como pods en Kubernetes).
* **Score** **NO** es un servidor en el clúster. Es un **estándar de especificación CLI** (igual que un `Dockerfile` o un `docker-compose.yml`) que vive en el repositorio de cada aplicación del desarrollador.

---

## 🔄 El Flujo de Trabajo

```text
1. Desarrollador escribe 'score.yaml' (o Backstage lo genera desde una plantilla)
   │
2. En CI (GitHub Actions) se ejecuta:
   score-k8s generate score.yaml
   │
3. Produce manifiestos de Kubernetes estándar:
   - Deployment / Service
   - Claims de Crossplane (ej. PostgreSQLInstance)
   │
4. ArgoCD toma esos manifiestos generados y los despliega en el clúster.
   │
5. Crossplane detecta el Claim y aprovisiona la infraestructura real.
```

---

## 🛠️ Cómo Probarlo en Local

1. Instala el CLI de Score:
   ```bash
   brew install score-spec/tap/score-k8s
   ```
2. Ejecuta la generación:
   ```bash
   cd local-mac/score-workload
   ./generate-manifests.sh
   ```

