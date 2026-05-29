variable "location" {
  description = "Região Azure"
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Nome do Resource Group"
  default     = "rg-spacedebris-tracker"
}

variable "app_service_name" {
  description = "Nome do App Service"
  default     = "spacedebris-tracker-app"
}

variable "key_vault_name" {
  description = "Nome do Key Vault (globalmente único)"
  default     = "kv-spacedebris26"
}

variable "n2yo_api_key" {
  description = "Chave da API N2YO"
  type        = string
  sensitive   = true
}
