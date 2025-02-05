// Tags
locals {
  tags = {
    owner        = var.tag_department
    region       = var.tag_region
    environment  = var.environment
    student_name = "jpalaci5"
  }
}

// Existing Resources

/// Subscription ID

data "azurerm_subscription" "current" {
}

// Random Suffix Generator

resource "random_integer" "deployment_id_suffix" {
  min = 100
  max = 999
}

// Resource Group

resource "azurerm_resource_group" "rg" {
  name     = "${var.class_name}-${var.student_name}-${var.environment}-${random_integer.deployment_id_suffix.result}-rg"
  location = var.location

  tags = local.tags
}


// Storage Account

resource "azurerm_storage_account" "storage" {
  name                     = "${var.class_name}${var.student_name}${var.environment}${random_integer.deployment_id_suffix.result}st"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = local.tags
}

resource "azurerm_application_insights" "example" {
  name                = "workspace-example-ai-jpalaci5"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
}

resource "azurerm_key_vault" "example" {
  name                = "jpalaci5-ws-vault-${random_integer.deployment_id_suffix.result}-kv"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_subscription.current.tenant_id
  sku_name            = "premium"
}


resource "azurerm_machine_learning_workspace" "example" {
  name                    = "ml-ws-jpalaci5-${random_integer.deployment_id_suffix.result}-ml"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  application_insights_id = azurerm_application_insights.example.id
  key_vault_id            = azurerm_key_vault.example.id
  storage_account_id      = azurerm_storage_account.storage.id

  identity {
    type = "SystemAssigned"
  }
}


resource "azurerm_cosmosdb_account" "db" {
  name                = "tfex-cosmos-db-${random_integer.deployment_id_suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  offer_type          = "Standard"
  kind                = "MongoDB"

  enable_automatic_failover = true

  capabilities {
    name = "EnableAggregationPipeline"
  }

  capabilities {
    name = "mongoEnableDocLevelTTL"
  }

  capabilities {
    name = "MongoDBv3.4"
  }

  capabilities {
    name = "EnableMongo"
  }

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 300
    max_staleness_prefix    = 100000
  }

  geo_location {
    location          = "eastus"
    failover_priority = 1
  }

  geo_location {
    location          = "westus"
    failover_priority = 0
  }
}

resource "azurerm_service_plan" "webapp_plan" {
  name                = "webapp-plan-jpalaci5"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku_name = "B1"
  os_type  = "Linux" # "Windows"
  #kind     = "Linux"

}

resource "azurerm_linux_web_app" "webapp" {
  name                = "jpalaci5-webapp-new-${random_integer.deployment_id_suffix.result}-app"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.webapp_plan.id

  site_config {}
}

output "webapp_url" {
  value = azurerm_linux_web_app.webapp.default_hostname
}


resource "azurerm_service_plan" "functionapp" {
  name                = "jpalaci5-functions-service-plan-${random_integer.deployment_id_suffix.result}-f"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku_name = "B1"
  os_type  = "Linux" # "Windows"

}

resource "azurerm_linux_function_app" "functionapp" {
  name                       = "jpalaci5-functions-${random_integer.deployment_id_suffix.result}-f-linux"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  service_plan_id            = azurerm_service_plan.functionapp.id
  storage_account_name       = azurerm_storage_account.storage.name
  storage_account_access_key = azurerm_storage_account.storage.primary_access_key

  site_config {}

}

