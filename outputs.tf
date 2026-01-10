output "container_app_url" {
  description = "Shlink Container App URL"
  value       = "https://${azurerm_container_app.shlink.ingress[0].fqdn}"
}

output "web_client_url" {
  description = "Shlink Web Client URL (Admin Interface)"
  value       = "https://${azurerm_container_app.shlink_web.ingress[0].fqdn}"
}

output "container_app_fqdn" {
  description = "Container App FQDN (for CNAME records)"
  value       = azurerm_container_app.shlink.ingress[0].fqdn
}

output "shlink_api_key" {
  description = "Shlink Initial API Key"
  value       = random_password.shlink_api_key.result
  sensitive   = true
}

output "postgres_host" {
  description = "PostgreSQL Server FQDN"
  value       = azurerm_postgresql_flexible_server.shlink.fqdn
}

output "postgres_database" {
  description = "PostgreSQL Database Name"
  value       = azurerm_postgresql_flexible_server_database.shlink.name
}

output "container_app_environment_static_ip" {
  description = "Static IP address of the Container Apps Environment"
  value       = azurerm_container_app_environment.shlink.static_ip_address
}

output "container_app_verification_id" {
  description = "Verification ID for Custom Domain validation (TXT record value)"
  value       = azurerm_container_app.shlink.custom_domain_verification_id
  sensitive   = true
}

output "deployment_instructions" {
  description = "Post-deployment instructions"
  value       = <<-EOT
  
  ✅ Shlink deployed successfully!
  
  🔗 Access your Shlink instance:
     ${azurerm_container_app.shlink.ingress[0].fqdn}
  
  🔑 API Key (save this securely):
     Run: terraform output -raw shlink_api_key

  🖥️ Admin Interface (Web Client):
     ${azurerm_container_app.shlink_web.ingress[0].fqdn}
  
  📝 Test your deployment:
     curl -X POST https://${azurerm_container_app.shlink.ingress[0].fqdn}/rest/v3/short-urls \
       -H "X-Api-Key: $(terraform output -raw shlink_api_key)" \
       -H "Content-Type: application/json" \
       -d '{"longUrl": "https://github.com"}'
  
  🌐 Custom Domain Setup:
     Add CNAME record: shlink.tudominio.cl -> ${azurerm_container_app.shlink.ingress[0].fqdn}
  
  💰 Cost: $0/month (scale-to-zero + Azure free tier)
  
  EOT
}
