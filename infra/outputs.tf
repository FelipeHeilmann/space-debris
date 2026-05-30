output "app_service_url" {
  value       = "https://${azurerm_linux_web_app.app.default_hostname}"
  description = "URL publica do App Service"
}

output "app_service_name" {
  value = azurerm_linux_web_app.app.name
}

output "key_vault_uri" {
  value       = azurerm_key_vault.kv.vault_uri
  description = "URI do Key Vault"
}

output "application_insights_key" {
  value     = azurerm_application_insights.ai.instrumentation_key
  sensitive = true
}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "role_assignment_info" {
  value       = "SP sp-spacedebris-githubactions (appId: b43524f4-1334-4639-9738-c52a33706e6f) com role Contributor na subscription"
  description = "Role assignment documentado - criado via az ad sp create-for-rbac"
}
