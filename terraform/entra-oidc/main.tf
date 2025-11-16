locals {
  expose_api = length(trim(var.identifier_uri)) > 0
}

resource "azuread_application" "oidc_app" {
  display_name = var.app_name

  # Configure Web platform with redirect URIs and enable ID/Access tokens.
  web {
    redirect_uris = var.redirect_uris
    implicit_grant {
      access_token_issuance_enabled = true
      id_token_issuance_enabled     = true
    }
  }

  optional_claims {
    id_token {
      name = "upn"
    }
    id_token {
      name = "email"
    }
    access_token {
      name = "email"
    }
    access_token {
      name = "preferred_username"
    }
    dynamic "access_token" {
      for_each = var.include_groups ? [true] : []
      content {
        name = "groups"
      }
    }
    dynamic "id_token" {
      for_each = var.include_groups ? [true] : []
      content {
        name = "groups"
      }
    }
  }

  dynamic "api" {
    for_each = local.expose_api ? [1] : []
    content {
      requested_access_token_version = 2
      oauth2_permission_scope {
        admin_consent_description  = var.api_scope_admin_consent_description
        admin_consent_display_name = var.api_scope_admin_consent_display_name
        enabled                    = true
        id                         = uuid()
        type                       = "User"
        value                      = var.api_scope_name
      }
    }
  }

  dynamic "identifier_uri" {
    for_each = local.expose_api ? [var.identifier_uri] : []
    content  = identifier_uri.value
  }
}

resource "azuread_application_password" "oidc_app" {
  application_object_id = azuread_application.oidc_app.object_id
  display_name          = "terraform-managed"
  end_date              = var.secret_end_date != "" ? var.secret_end_date : null
}
