# Shlink Terraform Azure 🚀

Auto-deploy [Shlink](https://shlink.io/) URL shortener to Azure Container Apps with **$0/month** cost using scale-to-zero and Terraform.

## 🏗️ Architecture

- **Azure Container Apps**: Shlink container (shlinkio/shlink:stable) with scale 0-5
- **PostgreSQL Flexible Server**: Standard_B1ms with public access
- **Terraform**: Infrastructure as Code
- **Terraform Cloud**: Remote state management (Free tier)
- **GitHub Actions**: Auto-deploy on push to main
- **Cost**: $0/month (scale-to-zero + Azure free tier)

## 📋 Prerequisites

- Azure subscription (VSTP1)
- GitHub account
- Azure CLI installed
- Terraform installed (optional, GitHub Actions handles deployment)

## 🔧 Setup Instructions

### 1. Fork/Clone Repository

```bash
git clone https://github.com/YOUR_USERNAME/shlink-terraform-azure.git
cd shlink-terraform-azure
```

### 2. Configure Terraform Variables

Edit `terraform.tfvars` with your values:

```hcl
# PostgreSQL Admin Password (REQUIRED)
postgres_admin_password = "YourStrongPassword123!"

# Shlink Default Domain (REQUIRED)
shlink_default_domain = "shlink.tudominio.cl"

# Your Public IP (REQUIRED - for PostgreSQL firewall)
# Get your IP: curl https://ifconfig.me
allowed_ip_address = "203.0.113.45"

# GeoLite License Key (OPTIONAL)
geolite_license_key = ""
```

### 3. Create Azure Service Principal with OIDC

Run these commands to create a federated credential for GitHub Actions:

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription "VSTP1"

# Create Service Principal
az ad sp create-for-rbac --name "sp-shlink-github-actions" \
  --role contributor \
  --scopes /subscriptions/$(az account show --query id -o tsv)/resourceGroups/shlink-terraform-azure

# Get the Application (Client) ID
APP_ID=$(az ad sp list --display-name "sp-shlink-github-actions" --query "[0].appId" -o tsv)

# Create federated credential for GitHub Actions
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-actions-shlink",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:YOUR_GITHUB_USERNAME/shlink-terraform-azure:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# Get required values for GitHub Secrets
echo "AZURE_CLIENT_ID: $APP_ID"
echo "AZURE_TENANT_ID: $(az account show --query tenantId -o tsv)"
echo "AZURE_SUBSCRIPTION_ID: $(az account show --query id -o tsv)"
```

**Important**: Replace `YOUR_GITHUB_USERNAME` with your actual GitHub username.

### 4. Configure GitHub Secrets

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Add these 4 secrets:

| Secret Name | Value |
|-------------|-------|
| `AZURE_CLIENT_ID` | Application (Client) ID from step 3 |
| `AZURE_TENANT_ID` | Tenant ID from step 3 |
| `AZURE_SUBSCRIPTION_ID` | Subscription ID from step 3 |
| `TF_API_TOKEN` | Terraform Cloud API token (already configured) |

### 5. Deploy to Azure

```bash
# Commit and push to trigger deployment
git add .
git commit -m "Initial Shlink deployment"
git push origin main
```

GitHub Actions will automatically:
1. Initialize Terraform
2. Plan infrastructure changes
3. Apply changes to Azure
4. Output Shlink URL and API key

### 6. Get Deployment Outputs

After deployment completes, check the **Actions** tab → Latest workflow run → **Deployment Summary**

You'll see:
- 🔗 Shlink URL
- 🔑 API Key
- 📝 Test command
- 🌐 Custom domain setup instructions

## 🧪 Testing Your Deployment

### Create a Short URL

```bash
# Replace with your actual URL and API key from GitHub Actions output
curl -X POST https://YOUR_CONTAINER_APP.azurecontainerapps.io/rest/v3/short-urls \
  -H "X-Api-Key: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"longUrl": "https://github.com"}'
```

Expected response:
```json
{
  "shortUrl": "https://YOUR_DOMAIN/abc123",
  "longUrl": "https://github.com"
}
```

### List Short URLs

```bash
curl https://YOUR_CONTAINER_APP.azurecontainerapps.io/rest/v3/short-urls \
  -H "X-Api-Key: YOUR_API_KEY"
```

## 🌐 Custom Domain Setup

1. Add CNAME record in your DNS provider:
   ```
   shlink.tudominio.cl → YOUR_CONTAINER_APP.azurecontainerapps.io
   ```

2. Update `terraform.tfvars`:
   ```hcl
   shlink_default_domain = "shlink.tudominio.cl"
   ```

3. Push changes to trigger redeployment

## 💰 Cost Breakdown

| Resource | SKU | Cost |
|----------|-----|------|
| Container Apps | Consumption (scale-to-zero) | $0 (free tier: 180,000 vCPU-seconds/month) |
| PostgreSQL Flexible Server | B1ms (idle when not in use) | ~$0-12/month |
| Log Analytics | PerGB2018 | $0 (free tier: 5GB/month) |

**Total**: $0/month for low-traffic usage

## 🔍 Troubleshooting

### PostgreSQL Connection Issues

If Shlink can't connect to PostgreSQL:

1. Verify your IP is whitelisted:
   ```bash
   curl https://ifconfig.me
   ```

2. Update firewall rule in Azure Portal or `terraform.tfvars`

### Container App Not Starting

Check logs in Azure Portal:
- Container Apps → ca-shlink → Revision Management → Logs

### API Key Not Working

Get the API key from Terraform outputs:
```bash
terraform output -raw shlink_api_key
```

Or check GitHub Actions workflow summary.

## 📚 Resources

- [Shlink Documentation](https://shlink.io/documentation/)
- [Azure Container Apps Docs](https://learn.microsoft.com/azure/container-apps/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

## 🤝 Contributing

Issues and PRs welcome!

## 📄 License

MIT License - See LICENSE file for details

---

**Made with ❤️ for DevOps Chile** 🇨🇱
