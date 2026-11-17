#!/usr/bin/env bash
# ==============================================================================
# Script: generate-manifests.sh
# Purpose: Demuestra cómo el CLI 'score-k8s' toma 'score.yaml' y genera manifiestos K8s
# ==============================================================================
set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}${BOLD}==> [Score CLI] Validando y generando manifiestos de Kubernetes...${NC}"

# Verificar si score-k8s está instalado
if ! command -v score-k8s >/dev/null 2>&1; then
  echo -e "${YELLOW}[INFO] 'score-k8s' no está instalado en tu Mac.${NC}"
  echo -e "Puedes instalarlo con:"
  echo -e "  ${GREEN}brew install score-spec/tap/score-k8s${NC}"
  echo -e "O descargarlo de: https://github.com/score-spec/score-k8s/releases"
  exit 0
fi

OUTPUT_DIR="manifests-generated"
mkdir -p "${OUTPUT_DIR}"

echo -e "${GREEN}[INFO] Traduciendo score.yaml a manifiestos de Kubernetes...${NC}"
score-k8s generate score.yaml --output "${OUTPUT_DIR}/manifests.yaml"

echo -e "${GREEN}${BOLD}==> [SUCCESS] Manifiestos generados exitosamente en ${OUTPUT_DIR}/manifests.yaml!${NC}"
cat "${OUTPUT_DIR}/manifests.yaml"

