resource "azurerm_resource_group" "tetris-project" {
  name     = "tetris-${var.project_name}-rg"
  location = var.region
}