# 📦 ArgoCD – Instalación local en K3d

Este repositorio automatiza el despliegue y la eliminación de ArgoCD en un clúster Kubernetes local (k3d) usando Helm.

## ✅ Instalación

```bash
chmod +x install_argocd_local_k3d.sh
./install_argocd_local_k3d.sh
```

Esto:

- Crea el namespace `argocd`.
- Instala ArgoCD vía Helm con puertos HTTP (`32080`) y HTTPS (`32443`).
- Muestra el usuario y contraseña de acceso.
- Expondrá la UI en:
  - [http://localhost:32080](http://localhost:32080)
  - [https://localhost:32443](https://localhost:32443)

## ❌ Desinstalación

Si deseas eliminar completamente ArgoCD del clúster, puedes ejecutar:

### Desinstalar si fue instalado con Helm

```bash
helm uninstall argocd -n argocd
kubectl delete pvc --all -n argocd --ignore-not-found
kubectl delete namespace argocd --ignore-not-found
```

### O si lo instalaste con manifiestos YAML planos

```bash
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl delete namespace argocd --ignore-not-found
```

## 🔍 Verificación y limpieza adicional

```bash
kubectl get all -n argocd
kubectl get pvc -n argocd
```

Para verificar que el servicio de ArgoCD está corriendo y accesible, puedes ejecutar:

```bash
kubectl get svc argocd-server -n argocd
kubectl get pods -n argocd
```


## 🔑 Acceso a la UI de ArgoCD


Para acceder a la interfaz de usuario de ArgoCD, puedes usar el siguiente comando para hacer un `port-forward`:

```bash
kubectl port-forward -n argocd svc/argocd-server 9090:443
```

Para obtener la contraseña inicial del usuario `admin`, puedes ejecutar:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```


