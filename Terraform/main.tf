resource "azurerm_resource_group" "tetris-project" {
  name     = "example-resources"
  location = var.region
}