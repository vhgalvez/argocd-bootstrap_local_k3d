📦 ArgoCD – Instalación local en K3d
Este repositorio automatiza el despliegue y la eliminación de ArgoCD en un clúster Kubernetes local (k3d) usando Helm.

✅ Instalación
bash
Copiar
Editar
chmod +x install_argocd_local_k3d.sh
./install_argocd_local_k3d.sh
Esto:

Crea el namespace argocd

Instala ArgoCD vía Helm con puertos HTTP (32080) y HTTPS (32443)

Muestra el usuario y contraseña de acceso

Expondrá la UI en:

arduino
Copiar
Editar
http://localhost:32080
https://localhost:32443
❌ Desinstalación
Si deseas eliminar completamente ArgoCD del clúster, puedes ejecutar:

bash
Copiar
Editar
# 1. Desinstalar si fue instalado con Helm
helm uninstall argocd -n argocd

# 2. Eliminar PVCs (almacenamiento persistente)
kubectl delete pvc --all -n argocd --ignore-not-found

# 3. Eliminar el namespace
kubectl delete namespace argocd --ignore-not-found
O si lo instalaste con manifiestos YAML planos:

bash
Copiar
Editar
# 1. Eliminar recursos creados por el manifiesto oficial
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 2. Borrar el namespace
kubectl delete namespace argocd --ignore-not-found
🔍 Verificación y limpieza adicional
bash
Copiar
Editar
kubectl get all -n argocd
kubectl get pvc -n argocd
