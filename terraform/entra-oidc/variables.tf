variable "tenant_id" {
  description = "Azure AD tenant ID that owns the Headlamp OIDC app."
  type        = string
}

variable "app_name" {
  description = "Display name for the Headlamp OIDC application."
  type        = string
  default     = "k8s.oremuslabs.app"
}

variable "redirect_uris" {
  description = "List of redirect URIs for the Web platform (e.g., Headlamp callback URLs)."
  type        = list(string)
  default     = [
    "https://headlamp.oremuslabs.app/oidc-callback",
    "http://localhost:8000"
  ]
}

variable "identifier_uri" {
  description = "Optional Application ID URI to expose an API (e.g., api://<app-id>). Leave empty to skip exposing an API."
  type        = string
  default     = ""
}

variable "api_scope_name" {
  description = "Scope value to expose when identifier_uri is set."
  type        = string
  default     = "app.full"
}

variable "api_scope_admin_consent_display_name" {
  description = "Admin consent display name for the optional API scope."
  type        = string
  default     = "Access Kubernetes API"
}

variable "api_scope_admin_consent_description" {
  description = "Admin consent description for the optional API scope."
  type        = string
  default     = "Allow client to access the Kubernetes API via this application."
}

variable "include_groups" {
  description = "Whether to request groups claim in ID and access tokens."
  type        = bool
  default     = false
}

variable "secret_end_date" {
  description = "RFC3339 timestamp for when the client secret should expire."
  type        = string
  default     = ""
}
