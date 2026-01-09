# Shlink Terraform Azure - Configuration
# Edit these values before deploying

# Resource Group (default: rg-shlink-terraform-2026)
# resource_group_name = "rg-shlink-terraform-2026"

# Azure Region (default: eastus2)
# location = "eastus2"

# PostgreSQL Admin Password (REQUIRED - min 8 characters, use strong password)
# IMPORTANT: Change this to a secure password before deploying!
postgres_admin_password = "ChangeMe_SecurePass123!"

# Shlink Default Domain (REQUIRED)
# Use the Container App URL initially, then update with your custom domain
# After first deploy, you'll get the URL from outputs
shlink_default_domain = "temp-domain.com"

# MaxMind GeoLite2 License Key (OPTIONAL - for geolocation features)
# Get free key at: https://www.maxmind.com/en/geolite2/signup
# Leave empty to skip geolocation features
geolite_license_key = ""

# Your Public IP Address (REQUIRED - for PostgreSQL firewall)
# Current IP detected: 186.104.177.156
allowed_ip_address = "186.104.177.156"
