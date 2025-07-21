#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="argocd"
RELEASE="argocd"
CHART="argo/argo-cd"
VALUES_FILE="$HOME/projects/argocd-bootstrap_local_k3d/argocd-values.yaml"

NODEPORT_HTTP=32080
NODEPORT_HTTPS=32443
LOCAL_PORT=9090  # Puerto fijo para port-forward

# 1. Verificar si el release ya está instalado
if helm status "$RELEASE" -n "$NAMESPACE" &>/dev/null; then
  echo "🗑️  Desinstalando release existente..."
  helm uninstall "$RELEASE" -n "$NAMESPACE"
  echo "🧼 Eliminando namespace y PVCs si existen..."
  kubectl delete pvc -n "$NAMESPACE" --all --ignore-not-found
  kubectl delete namespace "$NAMESPACE" --ignore-not-found
  sleep 5
fi

# 2. Crear namespace
echo "🚀 Creando namespace '$NAMESPACE'..."
kubectl create namespace "$NAMESPACE"

# 3. Agregar repo y actualizar charts
echo "📦 Añadiendo repo de ArgoCD Helm..."
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# 4. Desplegar con Helm + valores personalizados
echo "🚀 Instalando ArgoCD con Helm..."
helm upgrade --install "$RELEASE" "$CHART" \
  -n "$NAMESPACE" \
  -f "$VALUES_FILE" \
  --set server.service.type=NodePort \
  --set server.service.nodePortHttp=$NODEPORT_HTTP \
  --set server.service.nodePortHttps=$NODEPORT_HTTPS

# 5. Esperar pods
echo "⏳ Esperando a que ArgoCD esté listo..."
sleep 10
kubectl rollout status deployment/argocd-server -n "$NAMESPACE" --timeout=5m

# 6. Mostrar datos de acceso
PASSWORD=$(kubectl -n "$NAMESPACE" get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)

echo "✅ ArgoCD desplegado correctamente."

cat <<EOF

🌐 Acceso a ArgoCD UI:
    - NodePort:
        http://localhost:$NODEPORT_HTTP
        https://localhost:$NODEPORT_HTTPS

    - Port-Forward (manual, si prefieres):
        kubectl port-forward -n $NAMESPACE svc/$RELEASE $LOCAL_PORT:443
        https://localhost:$LOCAL_PORT

👤 Usuario: admin
🔐 Contraseña: $PASSWORD

📦 Namespace: $NAMESPACE
🛡️  Helm release: $RELEASE

EOF