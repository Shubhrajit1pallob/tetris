resource "azurerm_log_analytics_workspace" "tetris" {
  name                = "${var.project_name}-law"
  location            = azurerm_resource_group.tetris-project.location
  resource_group_name = azurerm_resource_group.tetris-project.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_kubernetes_cluster" "tetris" {
  name                = var.aks_cluster_name
  location            = azurerm_resource_group.tetris-project.location
  resource_group_name = azurerm_resource_group.tetris-project.name
  dns_prefix          = var.aks_dns_prefix

  default_node_pool {
    name       = "system"
    node_count = var.aks_node_count
    vm_size    = var.aks_node_vm_size
  }

  identity {
    type = "SystemAssigned"
  }

  linux_profile {
    admin_username = "azureuser"
    ssh_key {
      key_data = var.ssh_public_key
    }
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.tetris.id
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
  }

  role_based_access_control_enabled = true

  tags = {
    project = var.project_name
  }
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.tetris.kubelet_identity[0].object_id
}
