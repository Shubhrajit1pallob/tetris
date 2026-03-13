
resource "azurerm_container_registry" "acr" {
  name                = "tetrisacr"
  resource_group_name = azurerm_resource_group.tetris-project.name
  location            = azurerm_resource_group.tetris-project.location
  sku                 = "Basic"
  admin_enabled       = false
}