variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "rg-shlink-terraform-2026"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus2"
}

variable "postgres_admin_password" {
  description = "PostgreSQL administrator password (min 8 characters)"
  type        = string
  sensitive   = true
}

variable "shlink_default_domain" {
  description = "Default domain for Shlink URL shortener (e.g., shlink.tudominio.cl)"
  type        = string
}

variable "geolite_license_key" {
  description = "MaxMind GeoLite2 license key for geolocation (get free at https://www.maxmind.com/en/geolite2/signup)"
  type        = string
  default     = ""
}

variable "allowed_ip_address" {
  description = "Your public IP address to allow PostgreSQL access (get from https://ifconfig.me)"
  type        = string
}
