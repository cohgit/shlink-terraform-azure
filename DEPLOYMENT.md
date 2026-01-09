# ✅ Shlink Terraform Azure - Deployment Complete!

## 🎉 Deployment Summary

Your Shlink URL shortener has been successfully deployed to Azure Container Apps!

### 📍 Repository

**GitHub**: https://github.com/cohgit/shlink-terraform-azure

### 🔗 Access Information

| Resource | Value |
|----------|-------|
| **Shlink URL** | https://ca-shlink.greenstone-7ec642b8.eastus2.azurecontainerapps.io |
| **FQDN** | ca-shlink.greenstone-7ec642b8.eastus2.azurecontainerapps.io |
| **API Key** | `kTmpy8WGDHP7w0hkGkD9jHqXMWRVjSXo` |
| **PostgreSQL Host** | psql-shlink-none.postgres.database.azure.com |
| **Database** | shlink |

### 🏗️ Deployed Resources

- ✅ Resource Group: `rg-shlink-terraform-2026` (eastus2)
- ✅ PostgreSQL Flexible Server: `psql-shlink-none` (Standard_B1ms)
- ✅ Database: `shlink`
- ✅ Firewall Rules: User IP (186.104.177.156) + Azure Services
- ✅ Log Analytics Workspace: `law-shlink-none`
- ✅ Container App Environment: `cae-shlink`
- ✅ Container App: `ca-shlink` (shlinkio/shlink:stable, scale 0-5)

## 🧪 Testing Your Deployment

### Create a Short URL

```bash
curl -X POST https://ca-shlink.greenstone-7ec642b8.eastus2.azurecontainerapps.io/rest/v3/short-urls \
  -H "X-Api-Key: kTmpy8WGDHP7w0hkGkD9jHqXMWRVjSXo" \
  -H "Content-Type: application/json" \
  -d '{"longUrl": "https://github.com"}'
```

**Expected Response**:
```json
{
  "shortUrl": "https://ca-shlink.greenstone-7ec642b8.eastus2.azurecontainerapps.io/abc123",
  "longUrl": "https://github.com"
}
```

### List All Short URLs

```bash
curl https://ca-shlink.greenstone-7ec642b8.eastus2.azurecontainerapps.io/rest/v3/short-urls \
  -H "X-Api-Key: kTmpy8WGDHP7w0hkGkD9jHqXMWRVjSXo"
```

### Get Visit Stats

```bash
curl https://ca-shlink.greenstone-7ec642b8.eastus2.azurecontainerapps.io/rest/v3/short-urls/abc123/visits \
  -H "X-Api-Key: kTmpy8WGDHP7w0hkGkD9jHqXMWRVjSXo"
```

## 🌐 Custom Domain Setup (Optional)

To use your own domain (e.g., `shlink.tudominio.cl`):

1. **Add CNAME record** in your DNS provider:
   ```
   shlink.tudominio.cl → ca-shlink.greenstone-7ec642b8.eastus2.azurecontainerapps.io
   ```

2. **Update terraform.tfvars**:
   ```hcl
   shlink_default_domain = "shlink.tudominio.cl"
   ```

3. **Redeploy**:
   ```bash
   git add terraform.tfvars
   git commit -m "Update domain"
   git push
   ```

## 💰 Cost Breakdown

| Resource | Configuration | Estimated Cost |
|----------|--------------|----------------|
| Container Apps | Consumption (0-5 replicas) | **$0** (180,000 vCPU-sec/month free) |
| PostgreSQL B1ms | Flexible Server | **~$0-12/month** (idle when not in use) |
| Log Analytics | PerGB2018 | **$0** (5GB/month free) |
| **Total** | | **~$0/month** for low traffic |

## 🔧 Management Commands

### View Terraform Outputs

```bash
cd /Users/ecoh8002/dev/shlink-terraform-azure
terraform output
```

### Get API Key

```bash
terraform output -raw shlink_api_key
```

### Check Container App Status

```bash
az containerapp show --name ca-shlink --resource-group rg-shlink-terraform-2026 \
  --query "{fqdn:properties.configuration.ingress.fqdn, state:properties.provisioningState, status:properties.runningStatus}"
```

### View Container Logs

```bash
az containerapp logs show --name ca-shlink --resource-group rg-shlink-terraform-2026 --follow
```

## 🐛 Troubleshooting

### DNS Not Resolving

> **Note**: DNS propagation can take 5-10 minutes after deployment.

Check status:
```bash
nslookup ca-shlink.greenstone-7ec642b8.eastus2.azurecontainerapps.io
```

If still not resolving after 10 minutes, verify the Container App:
```bash
az containerapp show --name ca-shlink --resource-group rg-shlink-terraform-2026
```

### Container Not Starting

Check logs:
```bash
az containerapp logs show --name ca-shlink --resource-group rg-shlink-terraform-2026 --tail 100
```

### Database Connection Issues

Verify PostgreSQL firewall rules:
```bash
az postgres flexible-server firewall-rule list \
  --resource-group rg-shlink-terraform-2026 \
  --name psql-shlink-none -o table
```

Update your IP if changed:
```bash
# Get current IP
curl https://ifconfig.me

# Update terraform.tfvars with new IP
# Then redeploy
git add terraform.tfvars && git commit -m "Update IP" && git push
```

## 📚 Shlink API Documentation

Full API docs: https://shlink.io/documentation/api-docs/

Common endpoints:
- `POST /rest/v3/short-urls` - Create short URL
- `GET /rest/v3/short-urls` - List all short URLs
- `GET /rest/v3/short-urls/{shortCode}` - Get short URL details
- `DELETE /rest/v3/short-urls/{shortCode}` - Delete short URL
- `GET /rest/v3/short-urls/{shortCode}/visits` - Get visit stats

## 🔄 Redeployment

Any push to `main` branch triggers automatic deployment via GitHub Actions:

```bash
# Make changes to terraform files
git add .
git commit -m "Update configuration"
git push origin main

# Monitor deployment
gh run watch
```

## 🎯 What Was Accomplished

1. ✅ Created complete Terraform infrastructure code
2. ✅ Configured GitHub Actions with Azure OIDC authentication
3. ✅ Registered Microsoft.App resource provider
4. ✅ Deployed PostgreSQL Flexible Server with database
5. ✅ Created Container App Environment
6. ✅ Deployed Shlink container with scale-to-zero
7. ✅ Configured all environment variables
8. ✅ Set up firewall rules for database access
9. ✅ Generated secure API key
10. ✅ Pushed repository to GitHub

## 📝 Next Steps

1. **Wait 5-10 minutes** for DNS propagation
2. **Test the API** with the curl commands above
3. **Set up custom domain** (optional)
4. **Configure GeoLite2** for geolocation (optional):
   - Get free key: https://www.maxmind.com/en/geolite2/signup
   - Update `terraform.tfvars` with `geolite_license_key`
   - Push changes

## 🎊 Success!

Your Shlink URL shortener is now live and ready to use!

- **Repository**: https://github.com/cohgit/shlink-terraform-azure
- **Shlink URL**: https://ca-shlink.greenstone-7ec642b8.eastus2.azurecontainerapps.io
- **API Key**: `kTmpy8WGDHP7w0hkGkD9jHqXMWRVjSXo`

---

**Made with ❤️ for DevOps Chile** 🇨🇱
