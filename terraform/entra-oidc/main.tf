module "entra_app" {
  source = "./modules/app"

  app_name                           = var.app_name
  redirect_uris                      = var.redirect_uris
  public_redirect_uris               = var.public_redirect_uris
  identifier_uri                     = var.identifier_uri
  api_scope_name                     = var.api_scope_name
  api_scope_admin_consent_display_name = var.api_scope_admin_consent_display_name
  api_scope_admin_consent_description  = var.api_scope_admin_consent_description
  include_groups                     = var.include_groups
  secret_end_date                    = var.secret_end_date
}

module "entra_groups" {
  source = "./modules/groups"

  group_names   = var.group_names
  group_members = var.group_members
}
