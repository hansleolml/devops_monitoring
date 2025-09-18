Conectarse a kubernetes
    az account set --subscription 1b98b6af-d67a-425e-9787-c993bb283d9e
    az aks get-credentials --resource-group rg-dmc-dev-eastus2-01 --name aks-dmc-dev-eastus2-01 --overwrite-existing


Crear Namespace para monitoreo
    kubectl create namespace monitoring
Instalar Prometheus
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 
    helm repo update
    helm install prometheus prometheus-community/prometheus --namespace monitoring
Exponer con LoadBalancer
    kubectl patch svc prometheus-server -n monitoring -p '{"spec": {"type": "LoadBalancer"}}'


Instalar Grafana
    helm repo add grafana https://grafana.github.io/helm-charts 
    helm repo update
    helm install grafana grafana/grafana --namespace monitoring
Obtener la contraseña de Grafana
    kubectl get secret grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 --decode
Exponer con LoadBalancer
    kubectl patch svc grafana -n monitoring -p '{"spec": {"type": "LoadBalancer"}}'
Verificar las IPs asignadas:
    kubectl get svc -n monitoring



kubectl patch svc prometheus-server -n monitoring --patch-file patch.json
{
  "spec": {
    "type": "LoadBalancer"
  }
}