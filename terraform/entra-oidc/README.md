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
  app_name      = "k8s.oremuslabs.app"
  redirect_uris = [
    "https://headlamp.oremuslabs.app/oidc-callback",
    "http://localhost:8000", # common CLI/exec callback
  ]
  # identifier_uri = "api://k8s.oremuslabs.app" # optional audience if you want a custom API URI
  # include_groups = true                      # enable groups claim in tokens
}
```

Then:
```
cd terraform/entra-oidc
cp backend.tf.example backend.tf   # edit endpoint/bucket/key if needed
terraform init
terraform apply -var="tenant_id=<your-tenant-id>"
```

Outputs:
- `application_id` (client ID)
- `client_secret` (sensitive)
- `redirect_uris`
- `tenant_id`

## Remote state on MinIO
The included `backend.tf.example` is preconfigured for a MinIO backend at `https://minio.oremuslabs.app` with bucket `workspaces` and key `infra/entra-oidc/terraform.tfstate`. Export your MinIO creds before `terraform init`:
```
export AWS_ACCESS_KEY_ID=<minio-access-key>
export AWS_SECRET_ACCESS_KEY=<minio-secret-key>
cd terraform/entra-oidc
cp backend.tf.example backend.tf   # adjust if needed
terraform init
```

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
