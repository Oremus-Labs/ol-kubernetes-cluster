locals {
  expose_api = length(trimspace(var.identifier_uri)) > 0
}

resource "azuread_application" "this" {
  display_name = var.app_name
  fallback_public_client_enabled = true

  public_client {
    redirect_uris = var.public_redirect_uris
  }

  dynamic "single_page_application" {
    for_each = length(var.spa_redirect_uris) > 0 ? [1] : []
    content {
      redirect_uris = var.spa_redirect_uris
    }
  }

  group_membership_claims = var.group_membership_claims

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

  identifier_uris = local.expose_api ? [var.identifier_uri] : []
}

resource "azuread_application_password" "this" {
  application_id = azuread_application.this.id
  display_name   = "terraform-managed"
  end_date       = var.secret_end_date != "" ? var.secret_end_date : null
}
