locals {
  expose_api = length(trim(var.identifier_uri)) > 0
}

resource "azuread_application" "headlamp" {
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
    # Add groups if you plan to use group-based RBAC.
    # access_token { name = "groups" }
    # id_token     { name = "groups" }
  }

  dynamic "api" {
    for_each = local.expose_api ? [1] : []
    content {
      requested_access_token_version = 2
      oauth2_permission_scope {
        admin_consent_description  = "Access Headlamp API"
        admin_consent_display_name = "Access Headlamp API"
        enabled                    = true
        id                         = uuid()
        type                       = "User"
        value                      = "app.full"
      }
    }
  }

  dynamic "identifier_uri" {
    for_each = local.expose_api ? [var.identifier_uri] : []
    content  = identifier_uri.value
  }
}

resource "azuread_application_password" "headlamp" {
  application_object_id = azuread_application.headlamp.object_id
  display_name          = "terraform-managed"
  end_date              = var.secret_end_date != "" ? var.secret_end_date : null
}
