# 1Password Connect: required secrets and setup

This guide explains which Kubernetes secrets you must create so the 1Password Connect server can authenticate to your 1Password account and how downstream apps fetch secrets.

Scope: production clusters with provider on-prem or cloud. Namespaces and names below match this repo: namespace `onepassword`, secret `op-credentials`, and service `onepassword-connect`.

## Overview

Deployment pattern: Helm chart (`1password/connect`) via Argo CD ApplicationSet, which can deploy both Connect and the Operator together (recommended by 1Password).

Auth directions:
- Upstream: Connect -> 1Password Cloud using Service Account credentials (`1password-credentials.json`).
- Downstream: Clients / Operator -> Connect using an Access Token stored in a Kubernetes Secret.

This repo uses a Helm-based ApplicationSet (`appsets/workloads/1password-connect-helm.yaml`). Manual Kustomize manifests were removed to simplify maintenance.

## Prerequisites
- A 1Password account with Secrets Automation enabled.
- A 1Password Service Account with access to the vaults/items you need.
- Downloaded `credentials.json` for that Service Account (from 1Password UI when creating the Service Account).

## Secret A: Service Account credentials for Connect (required)

Create a secret containing your Service Account credentials JSON. The deployment mounts this secret at `/home/opuser/.op/config`, where Connect looks for `1password-credentials.json` by default.

Option 1: CLI (replace path to your downloaded file):

```bash
kubectl create namespace onepassword --dry-run=client -o yaml | kubectl apply -f -
kubectl -n onepassword create secret generic op-credentials \
  --from-file=1password-credentials.json=/path/to/credentials.json
```

Option 2: YAML manifest (paste your credentials as base64; safer to apply via CLI above):

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: op-credentials
  namespace: onepassword
stringData:
  1password-credentials.json: |
    { "serviceAccountToken": "<redacted>", "accountUuid": "A...", ... }
```

The Helm chart expects a Secret (referenced via `existingSecret`) containing the credentials file; create `op-credentials` before first sync.

## Secret B: Connect Access Token for clients / Operator (recommended)

Clients (like External Secrets, or the 1Password Operator itself) authenticate to your Connect server using an Access Token. After Connect is running, create a token and store it as a Kubernetes Secret (`onepassword-connect-token`). The Helm chart can reference it with `operator.token.existingSecret`.

1) Port-forward to Connect (or reach it via cluster DNS):
```bash
kubectl -n onepassword port-forward deploy/onepassword-connect 8080:8080
```

2) Create a token (name it for the client):
```bash
curl -sX POST http://127.0.0.1:8080/v1/auth/tokens \
  -H "Content-Type: application/json" \
  -d '{"label":"external-secrets-operator"}'
# Response includes {"token":"<long-token>"}
```

3) Store the token in a Secret for the `onepassword` namespace (this secret is referenced by the Helm chart and by anything else that needs `OP_CONNECT_TOKEN`):
```bash
kubectl -n onepassword create secret generic onepassword-connect-token \
  --from-literal=token="<paste-token>"
```
If you prefer GitOps, mirror the token back into 1Password and create a `OnePasswordItem` for it, then point the Helm chart at that item just like the `cloudflare-api-token` and `argocd-admin-password` references (`op://oremuslabs.app/...`).

Clients will use this token as `OP_CONNECT_TOKEN` along with the Connect host.

## Using External Secrets Operator (ESO) with 1Password Connect

If you plan to use ESO, create a SecretStore referencing your Connect host and token:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: onepassword-connect
  namespace: onepassword
spec:
  provider:
    onepassword:
      connect:
        host: http://onepassword-connect.onepassword.svc.cluster.local:8080
        tokenSecretRef:
          name: onepassword-connect-token
          key: token
```

Then define ExternalSecrets pointing to items in 1Password. Example:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: example-app-secret
  namespace: my-app
spec:
  refreshInterval: 1h
  secretStoreRef:
    kind: SecretStore
    name: onepassword-connect
  target:
    name: example-app-secret
    creationPolicy: Owner
  data:
    - secretKey: api-key
      remoteRef:
        # See External Secrets 1Password provider docs for path format
        # Typically: vaults/<vault-id-or-name>/items/<item-id-or-title>
        key: vaults/my-vault/items/my-item
        property: password
```

## Using 1Password Kubernetes Operator (Helm)

Recommended install via ApplicationSet:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: onepassword-connect-helm
  namespace: argocd
spec:
  generators:
    - clusters: {}
  template:
    metadata:
      name: '{{name}}-1password-connect-helm'
    spec:
      project: workloads
      destination:
        server: '{{server}}'
        namespace: onepassword
      source:
        repoURL: https://1password.github.io/connect-helm-charts/
        chart: connect
        targetRevision: 2.0.0
        helm:
          values: |
            connect:
              enabled: true
              existingSecret: op-credentials
            operator:
              create: true
              token:
                existingSecret: onepassword-connect-token
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
```

Provider-specific overrides can live in `apps/workloads/1password-connect/helm-values/` and be loaded later via a matrix generator or valueFiles.

Operator Annotations Examples:
Add to a Deployment to auto-create a Secret from an item:
```yaml
metadata:
  annotations:
    operator.1password.io/item-path: "vaults/<vault>/items/<item>"
    operator.1password.io/item-name: "my-app-secret"
```

Enable auto restart at namespace scope:
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: my-app-namespace
  annotations:
    operator.1password.io/auto-restart: "true"
```

If you use `OnePasswordItem` CRs instead of annotations, create them explicitly. The Helm operator watches all namespaces unless limited by `WATCH_NAMESPACE`.

## Troubleshooting
- Connect pod CrashLoopBackOff: ensure the `op-credentials` Secret exists and the JSON content is valid, and that the secret key is named `1password-credentials.json`.
- 401 from Connect when clients fetch secrets: the client token is missing/invalid; recreate token and update the `onepassword-connect-token` Secret.
- DNS/host: verify the service name `onepassword-connect.onepassword.svc.cluster.local` resolves within the cluster.
- Permissions: the Service Account in 1Password must have access to the vaults/items you are requesting.

## Security notes
 - Never commit the credentials JSON or access tokens to Git.
- Prefer using your password manager for storage of the credentials file and create the K8s Secret via CLI at deploy time.
- Scope Service Account access to only required vaults.
