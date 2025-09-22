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

## 4. Instalar Grafana

```bash
helm repo add grafana https://grafana.github.io/helm-charts 
helm repo update
helm install grafana grafana/grafana --namespace monitoring
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

### Exponer Grafana con LoadBalancer

**Opción 1: Comando directo**
```bash
kubectl patch svc grafana -n monitoring -p '{"spec": {"type": "LoadBalancer"}}'
```

**Opción 2: Usando archivo patch**
```bash
kubectl patch svc grafana -n monitoring --patch-file patch.json
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
