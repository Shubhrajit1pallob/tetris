resource "azurerm_cosmosdb_account" "tetris" {
  name                = var.cosmos_account_name
  location            = var.cosmos_region
  resource_group_name = azurerm_resource_group.tetris-project.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level = "Session"
  }

  capabilities {
    name = "EnableServerless"
  }

  geo_location {
    location          = var.cosmos_region
    failover_priority = 0
  }

  tags = {
    project = var.project_name
  }
}

resource "azurerm_cosmosdb_sql_database" "tetris" {
  name                = var.cosmos_database_name
  resource_group_name = azurerm_resource_group.tetris-project.name
  account_name        = azurerm_cosmosdb_account.tetris.name
}

resource "azurerm_cosmosdb_sql_container" "scores" {
  name                = var.cosmos_container_name
  resource_group_name = azurerm_resource_group.tetris-project.name
  account_name        = azurerm_cosmosdb_account.tetris.name
  database_name       = azurerm_cosmosdb_sql_database.tetris.name
  partition_key_paths = ["/monthBucket"]

  indexing_policy {
    indexing_mode = "consistent"

    included_path {
      path = "/*"
    }

    excluded_path {
      path = "/\"_etag\"/?"
    }
  }
}
