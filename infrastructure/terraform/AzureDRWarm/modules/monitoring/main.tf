# Azure Monitoring Module - Log Analytics, Application Insights

resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.name_prefix}-logs"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                = "PerGB2018"
  retention_in_days   = var.log_retention_days

  tags = var.common_tags
}

resource "azurerm_application_insights" "main" {
  name                = "${var.name_prefix}-insights"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"

  tags = var.common_tags
}