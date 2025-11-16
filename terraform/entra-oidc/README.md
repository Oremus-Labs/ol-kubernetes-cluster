# Terraform: Entra OIDC App for Headlamp / MicroK8s

This module provisions an Azure Entra (Azure AD) application for Headlamp and configures:
- Web redirect URIs (ID/Access tokens enabled).
- Optional claims for `upn`, `email`, and `preferred_username` (add `groups` if you want group-based RBAC).
- A client secret.
- Optionally an Application ID URI and a scope (`app.full`) if you set `identifier_uri`.

## Usage

### Quickstart
```
cd terraform/entra-oidc
# ensure backend.tf points at your remote state (MinIO/S3-compatible)
terraform init
terraform plan  -var-file=envs/prod.tfvars
# terraform apply -var-file=envs/prod.tfvars
```

Outputs:
- `application_id` (client ID)
- `client_secret` (sensitive)
- `redirect_uris`
- `tenant_id`

### MicroK8s apiserver OIDC flags
- Set on each control-plane node (persist in `/var/snap/microk8s/current/args/kube-apiserver`):
  - `--oidc-issuer-url=https://login.microsoftonline.com/<tenant-id>/v2.0`
  - `--oidc-client-id=af4fe910-bb07-4613-a3ba-5f51540aadad`
  - `--oidc-username-claim=email`   ← use `email` because the ID token does not include `upn`
  - `--oidc-groups-claim=groups`
- Restart kubelite after editing: `sudo systemctl restart snap.microk8s.daemon-kubelite.service`

### Structure
- `main.tf` / `variables.tf` / `outputs.tf` / `providers.tf`: core app definition (Entra application + secret).
- `backend.tf`: remote state (currently MinIO/S3-compatible).
- `envs/prod.tfvars`: environment-specific inputs (tenant ID, app name, redirects). Add more env files as needed.
- Add future resources (e.g., additional apps, service principals, federated credentials) alongside the existing resources. Keep app-specific inputs in env tfvars.

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
