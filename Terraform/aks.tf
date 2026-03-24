resource "azurerm_log_analytics_workspace" "tetris" {
  name                = "${var.project_name}-law"
  location            = azurerm_resource_group.tetris-project.location
  resource_group_name = azurerm_resource_group.tetris-project.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_kubernetes_cluster" "tetris" {
  #checkov:skip=CKV_AZURE_117:Temporary exception - DISK ENCRYPTION SET deferred for cost/complexity in non-prod
  #checkov:skip=CKV_AZURE_115:Temp exception - private cluster pending network landing zone
  #checkov:skip=CKV_AZURE_6:Temp exception - API server restricted by private endpoint roadmap
  #checkov:skip=CKV_AZURE_172:Temp exception - secrets store CSI rotation phase-2
  #checkov:skip=CKV_AZURE_171:Temp exception - upgrade channel decision pending ops sign-off
  name                = var.aks_cluster_name
  location            = azurerm_resource_group.tetris-project.location
  resource_group_name = azurerm_resource_group.tetris-project.name
  dns_prefix          = var.aks_dns_prefix

  default_node_pool {
    #checkov:skip=CKV_AZURE_227:Temp exception - host encryption deferred in non-prod
    #checkov:skip=CKV_AZURE_232:Temp exception - dedicated user pool not created yet
    #checkov:skip=CKV_AZURE_168:Temp exception - max_pods tuned lower for dev cost
    #checkov:skip=CKV_AZURE_226:Temp exception - ephemeral disks not supported on selected VM size
    name                        = "system"
    node_count                  = var.aks_node_count
    vm_size                     = var.aks_node_vm_size
    temporary_name_for_rotation = "systemtmp"
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

  azure_policy_enabled = true

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
  count                = var.enable_aks_acr_pull_role_assignment ? 1 : 0
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.tetris.kubelet_identity[0].object_id
}

resource "azurerm_kubernetes_cluster_node_pool" "monitoring" {
  count                 = var.enable_monitoring_node_pool ? 1 : 0
  name                  = "monitoring"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.tetris.id
  vm_size               = var.aks_node_vm_size
  node_count            = var.aks_node_count
  mode                  = "User"
  os_type               = "Linux"
  os_disk_size_gb       = 250
}
