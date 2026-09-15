# Comandos para Configuración de Monitoreo en AKS

## 1. Conectarse a Kubernetes

```bash
az account set --subscription 1b98b6af-d67a-425e-9787-c993bb283d9e
az aks get-credentials --resource-group rg-dmc-dev-eastus2-01 --name aks-dmc-dev-eastus2-01 --overwrite-existing
```

## 2. Crear Namespace para Monitoreo

```bash
kubectl create namespace monitoring
```

## 3. Instalar Prometheus

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 
helm repo update
helm install prometheus prometheus-community/prometheus --namespace monitoring
```

### Exponer Prometheus con LoadBalancer

> **Nota:** Esto crea un load balancer con IP pública

**Opción 1: Comando directo**
```bash
kubectl patch svc prometheus-server -n monitoring -p '{"spec": {"type": "LoadBalancer"}}'
```

**Opción 2: Usando archivo patch**
```bash
kubectl patch svc prometheus-server -n monitoring --patch-file patch.json
```

## 4. Agregar los repositorios de Helm e instalar loki

```bash
helm repo add grafana https://grafana.github.io/helm-charts 
helm repo update
helm upgrade --install loki grafana/loki-stack --namespace monitoring --set grafana.enabled=false --set promtail.enabled=true --set loki.image.tag=2.9.8

helm upgrade --install grafana grafana/grafana --namespace monitoring --set service.type=LoadBalancer

```

### Obtener la Contraseña de Grafana

**Opción 1: Comando directo**
```bash
kubectl get secret grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 --decode
```

**Opción 2: Para Windows**
```bash
kubectl get secret grafana -n monitoring -o jsonpath="{.data.admin-password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
```
## 5. Verificar las IPs Asignadas

```bash
kubectl get svc -n monitoring
```

## Archivo patch.json

```json
{
  "spec": {
    "type": "LoadBalancer"
  }
}
```

## 6. Configurar Data Sources en Grafana

### 6.1. Añadir Prometheus

1. **URL:** `http://prometheus-server.monitoring.svc.cluster.local:80`
2. **Tipo:** Prometheus
3. **Acceso:** Server (default)

### 6.2. Añadir Loki

1. **URL:** `http://loki.monitoring.svc.cluster.local:3100`
2. **Tipo:** Loki
3. **Acceso:** Server (default)

## 7. Ejemplo de Prueba

Crear un namespace de prueba y un pod para generar logs:

```bash
kubectl create namespace dev
kubectl run test-logs -n dev --image=busybox --restart=Never -- /bin/sh -c "while true; do echo 'Log de prueba desde el pod $(date)'; sleep 5; done"
```

### Verificar los Logs

```bash
# Ver logs del pod
kubectl logs test-logs -n dev

# Ver logs en tiempo real
kubectl logs -f test-logs -n dev
```

## 8. Ejemplo: pintar 404 de Nginx en Loki

Nginx escribe el **access log** en stdout (incluye el código HTTP). Promtail lo envía a Loki y en Grafana puedes filtrar solo los `404`.

Usa el manifiesto `pods.yaml` (Nginx + Service LoadBalancer).

### 8.1. Desplegar Nginx

```bash
kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f pods.yaml -n dev
```

### 8.2. Esperar la IP pública

```bash
kubectl get svc nginx-service -n dev -w
```

Cuando `EXTERNAL-IP` deje de estar en `<pending>`, copia la IP.

### 8.3. Generar tráfico 200 y 404

```bash
export NGINX_IP=$(kubectl get svc nginx-service -n dev -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# 200: página de bienvenida de Nginx
for i in {1..20}; do curl -s -o /dev/null -w "%{http_code}\n" http://$NGINX_IP/; done

# 404: ruta que no existe
for i in {1..20}; do curl -s -o /dev/null -w "%{http_code}\n" http://$NGINX_IP/no-existe; done
```

### 8.4. Verificar el access log en el pod

Deberías ver líneas como `GET / HTTP/1.1" 200` y `GET /no-existe HTTP/1.1" 404`.

```bash
kubectl logs nginx-pod -n dev
kubectl logs -f nginx-pod -n dev
```

### 8.5. Ver los 404 en Grafana (Loki)

1. Entra a Grafana → **Explore** (o el dashboard **Loki Kubernetes Logs**).
2. Data source: **Loki**.
3. Consultas:

```logql
{namespace="dev"}
```

```logql
{namespace="dev"} |= "404"
```

```logql
{namespace="dev"} |= " 200 "
```

En el dashboard, elige `namespace = dev` y en **Search Query** escribe `404`. El panel de barras cuenta esos logs y el panel de logs los lista.

