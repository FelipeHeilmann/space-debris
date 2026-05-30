data "azurerm_client_config" "current" {}

# ─── Resource Group ───────────────────────────────────────────────────────────
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    projeto    = "SpaceDebris Tracker"
    disciplina = "SDTCC"
    semestre   = "GS2026"
  }
}

# ─── App Service Plan (Linux B1) ──────────────────────────────────────────────
resource "azurerm_service_plan" "asp" {
  name                = "asp-spacedebris"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "B1"
}

# ─── App Service ──────────────────────────────────────────────────────────────
resource "azurerm_linux_web_app" "app" {
  name                = var.app_service_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.asp.id
  https_only          = true

  site_config {
    application_stack {
      python_version = "3.11"
    }
    always_on = false
  }

  app_settings = {
    "SCM_DO_BUILD_DURING_DEPLOYMENT"        = "true"
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = azurerm_application_insights.ai.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.ai.connection_string
  }

  identity {
    type = "SystemAssigned"
  }
}

# ─── Log Analytics Workspace ──────────────────────────────────────────────────
resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-spacedebris"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# ─── Application Insights ─────────────────────────────────────────────────────
resource "azurerm_application_insights" "ai" {
  name                = "ai-spacedebris"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  workspace_id        = azurerm_log_analytics_workspace.law.id
  application_type    = "web"
}

# ─── Key Vault ────────────────────────────────────────────────────────────────
resource "azurerm_key_vault" "kv" {
  name                = var.key_vault_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Acesso para quem executa o Terraform (Service Principal do GitHub Actions)
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = ["Get", "List", "Set", "Delete", "Purge"]
  }

  # Acesso para o App Service via Managed Identity
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_linux_web_app.app.identity[0].principal_id

    secret_permissions = ["Get", "List"]
  }
}

# ─── Key Vault Secret (API N2YO) ──────────────────────────────────────────────
resource "azurerm_key_vault_secret" "n2yo_key" {
  name         = "n2yo-api-key"
  value        = var.n2yo_api_key
  key_vault_id = azurerm_key_vault.kv.id
}

# IAM: Role Assignment documentado
# O Service Principal sp-spacedebris-githubactions possui role Contributor
# na subscription, criado via: az ad sp create-for-rbac --role Contributor
# appId: b43524f4-1334-4639-9738-c52a33706e6f

# ─── Monitor: Action Group (e-mail) ───────────────────────────────────────────
resource "azurerm_monitor_action_group" "email_ag" {
  name                = "ag-spacedebris-email"
  resource_group_name = azurerm_resource_group.rg.name
  short_name          = "sdt-email"

  email_receiver {
    name          = "equipe-spacedebris"
    email_address = "nortex.techvision@gmail.com"
  }
}

# ─── Monitor: Alert Rule (HTTP 5xx > 5 em 5 min, severidade 2) ────────────────
resource "azurerm_monitor_metric_alert" "http5xx_alert" {
  name                = "alert-http5xx-spacedebris"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_linux_web_app.app.id]
  description         = "HTTP 5xx acima de 5 ocorrencias em 5 minutos"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "Http5xx"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 5
  }

  action {
    action_group_id = azurerm_monitor_action_group.email_ag.id
  }
}
