output "group_ids" {
  description = "Map of group keys to object IDs."
  value       = { for k, g in azuread_group.this : k => g.id }
}

output "group_display_names" {
  description = "Map of group keys to display names."
  value       = { for k, g in azuread_group.this : k => g.display_name }
}
