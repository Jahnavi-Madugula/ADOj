terraform {
    backend "azurerm" {}
}
# Configure the Microsoft Azure Provider
provider "azurerm" {
    subscription_id = "f7b47845-d5bc-4233-bd62-1d9c2832b014"
    skip_provider_registration = "true"
    features {}
}
resource "azurerm_storage_account" "example" {
  name                     = "functionsapptestsa"
  resource_group_name      = "dcrresources"
  location                 = "westeurope"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
resource "azurerm_app_service_plan" "test" {
  name                = "jahtest-service-plan"
  location            = "westeurope"
  resource_group_name = "dcrresources"
  kind                = "FunctionApp"
  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}
resource "azurerm_application_insights" "test" {
  name                = "jahterraform-insights"
  location            = "westeurope"
  resource_group_name = "dcrresources"
  application_type    = "web"
}
resource "azurerm_function_app" "test" {
  name                      = "jah-terraform"
  location                  = "westeurope"
  resource_group_name       = "dcrresources"
  app_service_plan_id       = azurerm_app_service_plan.test.id
  storage_account_name       = azurerm_storage_account.example.name
  storage_account_access_key = azurerm_storage_account.example.primary_access_key
  app_settings = {
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.test.instrumentation_key
    FUNCTIONS_WORKER_RUNTIME = "powershell"
  }
}
