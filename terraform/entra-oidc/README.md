# Terraform: Entra OIDC App for Headlamp / MicroK8s

This module provisions an Azure Entra (Azure AD) application for Headlamp and configures:
- Web redirect URIs (ID/Access tokens enabled).
- Optional claims for `upn`, `email`, and `preferred_username` (add `groups` if you want group-based RBAC).
- A client secret.
- Optionally an Application ID URI and a scope (`app.full`) if you set `identifier_uri`.

## Usage

```hcl
provider "azuread" {
  tenant_id = var.tenant_id
}

module "headlamp_oidc" {
  source        = "./terraform/entra-oidc"
  tenant_id     = var.tenant_id
  app_name      = "Headlamp"
  redirect_uris = ["https://headlamp.oremuslabs.app/oidc-callback"]
  # identifier_uri = "api://a9c2b807-718a-4aff-ab9c-a683a27bf7f9" # optional
}
```

Then:
```
cd terraform/entra-oidc
terraform init
terraform apply -var="tenant_id=<your-tenant-id>"
```

Outputs:
- `application_id` (client ID)
- `client_secret` (sensitive)
- `redirect_uris`
- `tenant_id`

## MicroK8s API server flags (set on each control-plane)
- `--oidc-issuer-url=https://login.microsoftonline.com/<tenant-id>/v2.0`
- `--oidc-client-id=<application_id>`
- `--oidc-username-claim=upn` (or `preferred_username`)
- `--oidc-groups-claim=groups` (if you add groups claim)

## RBAC example
Bind your user (from the ID token `upn` or `preferred_username`) to a role:
```
kubectl create clusterrolebinding headlamp-admin \
  --clusterrole=cluster-admin \
  --user "<your-upn>"
```
