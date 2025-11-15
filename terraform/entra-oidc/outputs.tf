output "application_id" {
  description = "Client ID of the Headlamp OIDC application."
  value       = azuread_application.headlamp.application_id
}

output "tenant_id" {
  description = "Tenant ID used for the application."
  value       = var.tenant_id
}

output "redirect_uris" {
  description = "Configured redirect URIs."
  value       = var.redirect_uris
}

output "client_secret" {
  description = "Client secret for the application (sensitive)."
  value       = azuread_application_password.headlamp.value
  sensitive   = true
}
