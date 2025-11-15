variable "tenant_id" {
  description = "Azure AD tenant ID that owns the Headlamp OIDC app."
  type        = string
}

variable "app_name" {
  description = "Display name for the Headlamp OIDC application."
  type        = string
  default     = "Headlamp"
}

variable "redirect_uris" {
  description = "List of redirect URIs for the Web platform (e.g., Headlamp callback URLs)."
  type        = list(string)
  default     = ["https://headlamp.oremuslabs.app/oidc-callback"]
}

variable "identifier_uri" {
  description = "Optional Application ID URI to expose an API (e.g., api://<app-id>). Leave empty to skip exposing an API."
  type        = string
  default     = ""
}

variable "secret_end_date" {
  description = "RFC3339 timestamp for when the client secret should expire."
  type        = string
  default     = ""
}
