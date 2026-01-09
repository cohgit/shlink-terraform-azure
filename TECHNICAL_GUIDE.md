# Guía Técnica: Terraform Cloud con GitHub Actions y Azure OIDC

## 📋 Contexto del Problema

Al integrar **Terraform Cloud** como backend remoto con **GitHub Actions** y **Azure OIDC**, se presentan desafíos de autenticación porque:

1. Terraform Cloud ejecuta los planes en sus propios runners (remote execution)
2. Azure OIDC requiere tokens generados por GitHub Actions
3. Los runners de Terraform Cloud no tienen acceso a Azure CLI ni a los tokens OIDC de GitHub

## 🎯 Solución Implementada

**Configuración**: Terraform Cloud con **ejecución local** + **estado remoto**

- **Ejecución**: GitHub Actions (tiene acceso a OIDC)
- **Estado**: Terraform Cloud (almacenamiento centralizado)
- **Autenticación**: Azure OIDC desde GitHub Actions

## 🏗️ Arquitectura de la Solución

```
┌─────────────────────┐
│   GitHub Actions    │
│   (Runner)          │
│                     │
│  ┌──────────────┐   │
│  │ Terraform    │   │──────┐
│  │ CLI          │   │      │ OIDC Token
│  └──────────────┘   │      │
│         │           │      ▼
│         │ State     │  ┌─────────────┐
│         │ Push/Pull │  │   Azure     │
│         ▼           │  │   (OIDC)    │
│  ┌──────────────┐   │  └─────────────┘
│  │ TF Cloud API │◄──┤
│  └──────────────┘   │
└─────────────────────┘
         │
         ▼
┌─────────────────────┐
│  Terraform Cloud    │
│  (State Storage)    │
│                     │
│  • State Locking    │
│  • Version History  │
│  • Web UI           │
└─────────────────────┘
```

## 🔧 Configuración Paso a Paso

### 1. Backend Configuration (`backend.tf`)

```hcl
terraform {
  cloud {
    organization = "tu-organizacion"
    
    workspaces {
      name = "tu-workspace"
    }
  }
}
```

### 2. Azure Provider Configuration (`main.tf`)

**CRÍTICO**: Configurar el provider para usar OIDC explícitamente:

```hcl
provider "azurerm" {
  features {}
  
  use_oidc                   = true
  use_cli                    = false
  skip_provider_registration = false
}
```

**Por qué es necesario**:
- `use_oidc = true`: Fuerza el uso de OIDC
- `use_cli = false`: Desactiva el fallback a Azure CLI (que no existe en runners)
- `skip_provider_registration = false`: Permite registrar providers si es necesario

### 3. Terraform Cloud Workspace Configuration

**Configurar modo de ejecución local via API**:

```bash
TF_TOKEN="tu-token-aqui"
ORG="tu-organizacion"
WORKSPACE="tu-workspace"

# Obtener workspace ID
WORKSPACE_ID=$(curl -s \
  --header "Authorization: Bearer $TF_TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  "https://app.terraform.io/api/v2/organizations/$ORG/workspaces/$WORKSPACE" | \
  jq -r '.data.id')

# Configurar ejecución local
curl -s \
  --header "Authorization: Bearer $TF_TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  --request PATCH \
  --data '{
    "data": {
      "type": "workspaces",
      "attributes": {
        "execution-mode": "local"
      }
    }
  }' \
  "https://app.terraform.io/api/v2/workspaces/$WORKSPACE_ID"
```

**Alternativa**: Configurar manualmente en la UI:
- Settings → General → Execution Mode → Local

### 4. GitHub Actions Workflow

```yaml
name: Deploy Infrastructure

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  id-token: write
  contents: read

jobs:
  terraform:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4

      # Azure OIDC Login
      - name: Azure Login
        uses: azure/login@v1
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      # Terraform Setup con token de TF Cloud
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.6.0
          cli_config_credentials_token: ${{ secrets.TF_API_TOKEN }}

      # Terraform Init (conecta con TF Cloud)
      - name: Terraform Init
        run: terraform init
        env:
          ARM_USE_OIDC: true
          ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
          ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}

      - name: Terraform Plan
        run: terraform plan
        env:
          ARM_USE_OIDC: true
          ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
          ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}

      - name: Terraform Apply
        if: github.ref == 'refs/heads/main'
        run: terraform apply -auto-approve
        env:
          ARM_USE_OIDC: true
          ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
          ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
```

### 5. GitHub Secrets Requeridos

| Secret | Descripción | Cómo obtenerlo |
|--------|-------------|----------------|
| `AZURE_CLIENT_ID` | Application ID del Service Principal | `az ad sp list --display-name "sp-name" --query "[0].appId"` |
| `AZURE_TENANT_ID` | Tenant ID de Azure | `az account show --query tenantId` |
| `AZURE_SUBSCRIPTION_ID` | Subscription ID | `az account show --query id` |
| `TF_API_TOKEN` | Token de Terraform Cloud | Desde `~/.terraform.d/credentials.tfrc.json` |

### 6. Azure Service Principal con OIDC

```bash
# Crear Service Principal
az ad sp create-for-rbac \
  --name "sp-github-actions" \
  --role contributor \
  --scopes /subscriptions/$(az account show --query id -o tsv)

# Obtener Application ID
APP_ID=$(az ad sp list --display-name "sp-github-actions" --query "[0].appId" -o tsv)

# Crear federated credential para GitHub Actions
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-actions-oidc",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:USUARIO/REPOSITORIO:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

## ⚠️ Problemas Comunes y Soluciones

### Error: "could not configure AzureCli Authorizer"

**Causa**: El provider intenta usar Azure CLI en lugar de OIDC.

**Solución**: Agregar en el provider block:
```hcl
provider "azurerm" {
  use_oidc = true
  use_cli  = false
}
```

### Error: "no Authorizer could be configured"

**Causa**: Terraform Cloud está ejecutando en modo remoto sin acceso a credenciales OIDC.

**Solución**: Cambiar workspace a ejecución local:
```bash
# Via API (ver sección 3)
# O en UI: Settings → Execution Mode → Local
```

### Error: "Missing required scope 'read:org'"

**Causa**: Token de GitHub CLI sin permisos suficientes.

**Solución**: Generar nuevo token en https://github.com/settings/tokens con scopes:
- `repo`
- `read:org`
- `workflow`

### State Lock Issues

**Causa**: Múltiples ejecuciones concurrentes.

**Solución**: Terraform Cloud maneja el locking automáticamente en modo local.

## 📊 Comparación de Modos de Ejecución

| Característica | Remote Execution | Local Execution |
|----------------|------------------|-----------------|
| **Dónde corre Terraform** | Terraform Cloud runners | GitHub Actions runners |
| **Acceso a OIDC** | ❌ No | ✅ Sí |
| **State storage** | ✅ TF Cloud | ✅ TF Cloud |
| **State locking** | ✅ Automático | ✅ Automático |
| **Variables de entorno** | Solo las configuradas en TF Cloud | Desde GitHub Actions |
| **Costo** | Gratis (hasta 500 recursos) | Gratis (GitHub Actions minutes) |
| **Recomendado para OIDC** | ❌ No compatible | ✅ Sí |

## 🔐 Flujo de Autenticación

```
1. GitHub Actions inicia workflow
   │
2. Azure Login Action obtiene OIDC token
   │
3. Token se expone como variables de entorno:
   - ARM_USE_OIDC=true
   - ARM_CLIENT_ID
   - ARM_TENANT_ID
   - ARM_SUBSCRIPTION_ID
   │
4. Terraform CLI lee las variables
   │
5. azurerm provider usa OIDC para autenticar
   │
6. Terraform ejecuta plan/apply
   │
7. Estado se guarda en Terraform Cloud via API
```

## 📝 Checklist de Implementación

- [ ] Crear organización en Terraform Cloud
- [ ] Crear workspace en Terraform Cloud
- [ ] Configurar workspace en modo "Local execution"
- [ ] Crear Service Principal en Azure
- [ ] Configurar federated credentials OIDC
- [ ] Agregar secrets en GitHub (4 secrets)
- [ ] Crear `backend.tf` con configuración de TF Cloud
- [ ] Actualizar provider `azurerm` con `use_oidc=true`
- [ ] Crear workflow de GitHub Actions
- [ ] Ejecutar `terraform login` localmente
- [ ] Ejecutar `terraform init` para migrar estado
- [ ] Verificar que el workflow funcione

## 🎯 Prompt para IA

```
Necesito configurar Terraform Cloud como backend remoto para un proyecto que usa:
- GitHub Actions para CI/CD
- Azure como provider
- OIDC para autenticación sin secretos

Requisitos:
1. Estado centralizado en Terraform Cloud (gratis)
2. Ejecución en GitHub Actions (para acceso a OIDC)
3. Autenticación Azure via OIDC (sin client secrets)
4. State locking automático

Configuración necesaria:
- Terraform Cloud workspace en modo "local execution"
- Provider azurerm con use_oidc=true y use_cli=false
- GitHub Actions con azure/login@v1 para OIDC
- Federated credentials en Azure AD
- 4 secrets en GitHub: AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID, TF_API_TOKEN

El problema común es que Terraform Cloud en modo "remote execution" no tiene acceso
a los tokens OIDC de GitHub Actions. La solución es usar "local execution" donde
Terraform corre en GitHub Actions pero el estado se guarda en TF Cloud.
```

## 📚 Referencias

- [Terraform Cloud Execution Modes](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/settings#execution-mode)
- [Azure OIDC with GitHub Actions](https://learn.microsoft.com/azure/developer/github/connect-from-azure)
- [Terraform azurerm Provider OIDC](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_oidc)
- [GitHub Actions OIDC](https://docs.github.com/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)

## 💡 Mejores Prácticas

1. **Siempre usar OIDC** en lugar de client secrets para mayor seguridad
2. **Modo local** para Terraform Cloud cuando uses OIDC
3. **Separar workspaces** por ambiente (dev, staging, prod)
4. **Versionar el estado** usando Terraform Cloud (gratis hasta 500 recursos)
5. **Documentar** las variables de entorno requeridas en el README
6. **Validar** la configuración con `terraform validate` antes de push

## 🚀 Resultado Final

- ✅ Estado centralizado y versionado en Terraform Cloud
- ✅ Autenticación segura sin secretos (OIDC)
- ✅ CI/CD automatizado con GitHub Actions
- ✅ State locking para prevenir conflictos
- ✅ Costo $0 (dentro de tier gratuito)
- ✅ Historial completo de cambios en UI web

---

**Autor**: DevOps Chile  
**Fecha**: 2026-01-09  
**Stack**: Terraform Cloud + GitHub Actions + Azure OIDC
