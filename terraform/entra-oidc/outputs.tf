output "application_id" {
  description = "Client ID of the Headlamp OIDC application."
  value       = module.entra_app.application_id
}

output "tenant_id" {
  description = "Tenant ID used for the application."
  value       = var.tenant_id
}

output "redirect_uris" {
  description = "Configured redirect URIs."
  value       = module.entra_app.redirect_uris
}

output "client_secret" {
  description = "Client secret for the application (sensitive)."
  value       = module.entra_app.client_secret
  sensitive   = true
}

output "group_ids" {
  description = "Map of group keys to Entra group object IDs."
  value       = module.entra_groups.group_ids
}

output "group_display_names" {
  description = "Map of group keys to Entra group display names."
  value       = module.entra_groups.group_display_names
}
