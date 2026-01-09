# Shlink Terraform Azure - Configuration Template
# Copy this file and edit with your values

# Resource Group (default: rg-shlink-terraform-2026)
# resource_group_name = "rg-shlink-terraform-2026"

# Azure Region (default: eastus2)
# location = "eastus2"

# PostgreSQL Admin Password (REQUIRED - min 8 characters, use strong password)
postgres_admin_password = "CHANGE_ME_Strong_Password_123!"

# Shlink Default Domain (REQUIRED - your custom domain or use the ACA FQDN)
# Example: "shlink.tudominio.cl" or leave as the Container App URL
shlink_default_domain = "your-domain.com"

# MaxMind GeoLite2 License Key (OPTIONAL - for geolocation features)
# Get free key at: https://www.maxmind.com/en/geolite2/signup
geolite_license_key = ""

# Your Public IP Address (REQUIRED - for PostgreSQL firewall)
# Get your IP: curl https://ifconfig.me
# Example: "203.0.113.45"
allowed_ip_address = "0.0.0.0"
