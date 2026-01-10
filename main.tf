terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  
  use_oidc                   = true
  use_cli                    = false
  skip_provider_registration = false
}

# Random API key for Shlink
resource "random_password" "shlink_api_key" {
  length  = 32
  special = false
}

# Resource Group
resource "azurerm_resource_group" "shlink" {
  name     = var.resource_group_name
  location = var.location
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "shlink" {
  name                   = "psql-shlink-${random_password.shlink_api_key.id}"
  resource_group_name    = azurerm_resource_group.shlink.name
  location               = azurerm_resource_group.shlink.location
  version                = "14"
  administrator_login    = "shlink_admin"
  administrator_password = var.postgres_admin_password

  sku_name   = "B_Standard_B1ms"
  storage_mb = 32768

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  zone = "1"
}

# PostgreSQL Firewall Rule - Allow user IP
resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_user_ip" {
  name             = "AllowUserIP"
  server_id        = azurerm_postgresql_flexible_server.shlink.id
  start_ip_address = var.allowed_ip_address
  end_ip_address   = var.allowed_ip_address
}

# PostgreSQL Firewall Rule - Allow Azure services
resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_postgresql_flexible_server.shlink.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# PostgreSQL Database
resource "azurerm_postgresql_flexible_server_database" "shlink" {
  name      = "shlink"
  server_id = azurerm_postgresql_flexible_server.shlink.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

# Container Apps Environment
resource "azurerm_container_app_environment" "shlink" {
  name                       = "cae-shlink"
  location                   = azurerm_resource_group.shlink.location
  resource_group_name        = azurerm_resource_group.shlink.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.shlink.id
}

# Log Analytics Workspace for Container Apps
resource "azurerm_log_analytics_workspace" "shlink" {
  name                = "law-shlink-${random_password.shlink_api_key.id}"
  location            = azurerm_resource_group.shlink.location
  resource_group_name = azurerm_resource_group.shlink.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Container App - Shlink
resource "azurerm_container_app" "shlink" {
  name                         = "ca-shlink"
  container_app_environment_id = azurerm_container_app_environment.shlink.id
  resource_group_name          = azurerm_resource_group.shlink.name
  revision_mode                = "Single"

  template {
    min_replicas = 0
    max_replicas = 5

    container {
      name   = "shlink"
      image  = "shlinkio/shlink:stable"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "DEFAULT_DOMAIN"
        value = var.shlink_default_domain
      }

      env {
        name  = "IS_HTTPS_ENABLED"
        value = "true"
      }

      env {
        name  = "DB_DRIVER"
        value = "postgres"
      }

      env {
        name  = "DB_HOST"
        value = azurerm_postgresql_flexible_server.shlink.fqdn
      }

      env {
        name  = "DB_PORT"
        value = "5432"
      }

      env {
        name  = "DB_NAME"
        value = azurerm_postgresql_flexible_server_database.shlink.name
      }

      env {
        name  = "DB_USER"
        value = azurerm_postgresql_flexible_server.shlink.administrator_login
      }

      env {
        name  = "DB_PASSWORD"
        value = var.postgres_admin_password
      }

      env {
        name  = "INITIAL_API_KEY"
        value = random_password.shlink_api_key.result
      }

      env {
        name  = "TIMEZONE"
        value = "America/Santiago"
      }

      env {
        name  = "GEOLITE_LICENSE_KEY"
        value = var.geolite_license_key
      }
    }

    http_scale_rule {
      name                = "http-scale"
      concurrent_requests = 10
    }
  }

  ingress {
    external_enabled = true
    target_port      = 8080
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}

# Container App - Shlink Web Client
resource "azurerm_container_app" "shlink_web" {
  name                         = "ca-shlink-web"
  container_app_environment_id = azurerm_container_app_environment.shlink.id
  resource_group_name          = azurerm_resource_group.shlink.name
  revision_mode                = "Single"

  template {
    min_replicas = 0
    max_replicas = 5

    container {
      name   = "shlink-web-client"
      image  = "shlinkio/shlink-web-client:stable"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "SHLINK_SERVER_URL"
        value = "https://${azurerm_container_app.shlink.ingress[0].fqdn}"
      }

      env {
        name  = "SHLINK_SERVER_API_KEY"
        value = random_password.shlink_api_key.result
      }
    }

    http_scale_rule {
      name                = "http-scale"
      concurrent_requests = 10
    }
  }

  ingress {
    external_enabled = true
    target_port      = 80
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}

# Custom Domain for Shlink
resource "azurerm_container_app_custom_domain" "shlink" {
  name                      = var.shlink_default_domain
  container_app_id          = azurerm_container_app.shlink.id
  certificate_binding_type  = "Disabled"
}
