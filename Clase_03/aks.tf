resource "azurerm_resource_group" "rg_01" {
  name     = "rg-hans-dev-eastus-01"
  location = "East US"
}

# resource "azurerm_log_analytics_workspace" "law_01" {
#   name                = "law-hans-dev-eastus-01"
#   location            = azurerm_resource_group.rg_01.location
#   resource_group_name = azurerm_resource_group.rg_01.name
#   sku                 = "PerGB2018"
#   retention_in_days   = 30
# }

resource "azurerm_kubernetes_cluster" "aks_01" {
  name                = "aks-hans-dev-eastus-01"
  location            = azurerm_resource_group.rg_01.location
  resource_group_name = azurerm_resource_group.rg_01.name
  dns_prefix          = "aksdns"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  # # 🔹 Habilitar Azure Monitor / Container Insights para logs
  # oms_agent {
  #   log_analytics_workspace_id = azurerm_log_analytics_workspace.law_01.id
  # }

  tags = {
    Environment = "Development"
  }
}

output "client_certificate" {
  value     = azurerm_kubernetes_cluster.aks_01.kube_config[0].client_certificate
  sensitive = true
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.aks_01.kube_config_raw
  sensitive = true
}

# output "log_analytics_workspace_id" {
#   value = azurerm_log_analytics_workspace.law_01.id
#   description = "ID del Log Analytics Workspace para verificar logs"
# }

# output "aks_monitoring_enabled" {
#   value = azurerm_kubernetes_cluster.aks_01.oms_agent[0].log_analytics_workspace_id
#   description = "Confirma que el monitoring está habilitado"
# }