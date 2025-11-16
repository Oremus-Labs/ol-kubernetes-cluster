resource "azuread_group" "this" {
  for_each = var.group_names

  display_name     = each.value
  security_enabled = true
  members          = try(var.group_members[each.key], [])
}
