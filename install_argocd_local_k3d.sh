#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# deploy_argocd_render.sh
#   ▸ Despliega ArgoCD en K3d / K3s con Helm + configuración personalizada
#   ▸ Asigna puertos fijos y muestra credenciales al finalizar
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# ═══ 0. CONFIG Y VALIDACIÓN ═══════════════════════════════════════════════════
NAMESPACE="argocd"
RELEASE="argocd"
CHART="argo/argo-cd"
VALUES_FILE="$HOME/projects/argocd-bootstrap_local_k3d/argocd-values.yaml"
NODEPORT_HTTP=32080
NODEPORT_HTTPS=32443
LOCAL_PORT=9090  # Para port-forward manual (opcional)

for bin in helm kubectl base64; do
  command -v "$bin" >/dev/null || { echo "❌ Falta $bin"; exit 1; }
done

# ═══ 1. LIMPIEZA PREVIA ══════════════════════════════════════════════════════
if helm status "$RELEASE" -n "$NAMESPACE" &>/dev/null; then
  echo "🗑️  Desinstalando release existente..."
  helm uninstall "$RELEASE" -n "$NAMESPACE"
  echo "🧼 Eliminando namespace y PVCs si existen..."
  kubectl delete pvc -n "$NAMESPACE" --all --ignore-not-found
  kubectl delete namespace "$NAMESPACE" --ignore-not-found
  sleep 5
fi

# ═══ 2. CREACIÓN DEL NAMESPACE ════════════════════════════════════════════════
echo "🚀 Creando namespace '$NAMESPACE'..."
kubectl create namespace "$NAMESPACE"

# ═══ 3. REPO + INSTALACIÓN HELM ══════════════════════════════════════════════
echo "📦 Añadiendo repo de ArgoCD Helm..."
helm repo add argo https://argoproj.github.io/argo-helm >/dev/null 2>&1 || true
helm repo update >/dev/null

echo "🚀 Instalando ArgoCD con Helm..."
helm upgrade --install "$RELEASE" "$CHART" \
  -n "$NAMESPACE" \
  -f "$VALUES_FILE" \
  --set server.service.type=NodePort \
  --set server.service.nodePortHttp=$NODEPORT_HTTP \
  --set server.service.nodePortHttps=$NODEPORT_HTTPS

# ═══ 4. ESPERA DE LOS PODS ═══════════════════════════════════════════════════
echo "⏳ Esperando a que ArgoCD esté listo..."
kubectl rollout status deployment/argocd-server -n "$NAMESPACE" --timeout=5m

# ═══ 5. CREDENCIALES Y ACCESO ════════════════════════════════════════════════
PASSWORD=$(kubectl -n "$NAMESPACE" get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)

cat <<EOF

╭─────────────────────────────  ArgoCD Listo  ─────────────────────────────╮
│ 🌐 URL NodePort HTTP : http://localhost:$NODEPORT_HTTP                   │
│ 🌐 URL NodePort HTTPS: https://localhost:$NODEPORT_HTTPS                  │
│ 🔗 Port-forward     : kubectl port-forward -n $NAMESPACE svc/$RELEASE \
│                       $LOCAL_PORT:443                                    │
│ 👤 Usuario admin    : admin                                               │
│ 🔐 Contraseña       : $PASSWORD                                           │
│ 📦 Namespace        : $NAMESPACE                                          │
│ 🛡️  Helm release     : $RELEASE                                            │
╰──────────────────────────────────────────────────────────────────────────╯

EOF