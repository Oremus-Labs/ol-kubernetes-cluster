output "application_id" {
  description = "Client ID of the Entra application."
  value       = azuread_application.this.client_id
}

output "object_id" {
  description = "Object ID of the Entra application."
  value       = azuread_application.this.id
}

output "client_secret" {
  description = "Client secret for the application (sensitive)."
  value       = azuread_application_password.this.value
  sensitive   = true
}

output "redirect_uris" {
  description = "Configured redirect URIs."
  value       = var.redirect_uris
}
