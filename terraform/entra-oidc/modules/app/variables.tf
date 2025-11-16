variable "app_name" {
  description = "Display name for the Entra application."
  type        = string
}

variable "redirect_uris" {
  description = "List of redirect URIs for the Web platform."
  type        = list(string)
}

variable "public_redirect_uris" {
  description = "List of redirect URIs for the public client (PKCE/device flows)."
  type        = list(string)
  default     = ["http://localhost:8000/"]
}

variable "spa_redirect_uris" {
  description = "List of redirect URIs for single-page application flows."
  type        = list(string)
  default     = []
}

variable "group_membership_claims" {
  description = "Requested group membership claims (e.g., SecurityGroup)."
  type        = list(string)
  default     = ["SecurityGroup"]
}

variable "identifier_uri" {
  description = "Optional Application ID URI to expose an API. Leave empty to skip."
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
  default     = true
}

variable "secret_end_date" {
  description = "RFC3339 timestamp for when the client secret should expire."
  type        = string
  default     = ""
}
