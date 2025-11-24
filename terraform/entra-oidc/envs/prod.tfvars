tenant_id = "abfcbee8-658f-4ab3-97f5-9b357e0f8cda"
app_name  = "k8s.oremuslabs.app"
identifier_uri = "api://k8s.oremuslabs.app"
redirect_uris = [
  "https://argocd.oremuslabs.app/auth/callback",
  "https://auth.oremuslabs.app/oauth2/callback",
  "https://headlamp.oremuslabs.app/oidc-callback",
  "https://traefik.oremuslabs.app/oauth2/callback",
  "https://openwebui.oremuslabs.app/oauth/microsoft/callback"
]
public_redirect_uris = [
  "http://localhost:8000/",
  "http://localhost:8080/auth/callback",
  "http://localhost:8085/auth/callback"
]
group_members = {
  admins     = ["58113952-db02-4975-88e1-9dab68d40aff"]
  developers = ["58113952-db02-4975-88e1-9dab68d40aff"]
  readonly   = ["58113952-db02-4975-88e1-9dab68d40aff"]
}
