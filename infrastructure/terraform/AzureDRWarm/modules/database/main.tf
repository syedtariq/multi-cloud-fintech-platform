# Azure Database Module - PostgreSQL, Redis, Storage

resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "${var.name_prefix}-postgres"
  resource_group_name    = var.resource_group_name
  location              = var.location
  version               = var.postgres_version
  delegated_subnet_id   = var.database_subnet_id
  administrator_login    = "postgres"
  administrator_password = random_password.postgres.result
  zone                  = "1"
  storage_mb            = var.storage_mb
  sku_name              = var.postgres_sku
  backup_retention_days = 30

  tags = var.common_tags
}

# Firewall rule for AWS DMS connection
resource "azurerm_postgresql_flexible_server_firewall_rule" "aws_dms" {
  name             = "aws-dms-access"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "10.0.0.0"  # AWS VPC CIDR start
  end_ip_address   = "10.0.255.255"  # AWS VPC CIDR end
}

resource "random_password" "postgres" {
  length  = 16
  special = true
}

resource "azurerm_redis_cache" "main" {
  name                = "${var.name_prefix}-redis"
  location            = var.location
  resource_group_name = var.resource_group_name
  capacity            = 2
  family              = "C"
  sku_name            = "Standard"
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"

  tags = var.common_tags
}

resource "azurerm_storage_account" "main" {
  name                     = "${replace(var.name_prefix, "-", "")}storage"
  resource_group_name      = var.resource_group_name
  location                = var.location
  account_tier            = "Standard"
  account_replication_type = "LRS"
  min_tls_version         = "TLS1_2"

  tags = var.common_tags
}