# AI Model Manager

Knative Service for dynamically managing KServe InferenceServices based on model catalog configurations.

## Configuration Required

### 1. 1Password Item for Git Credentials

You must create a 1Password item with credentials to access the `ol-model-catalog` GitHub repository.

The item should contain:
- `username` field: Git username or "git"
- `token` field: GitHub Personal Access Token with `repo` read access

Update the `itemPath` in `values.yaml` with the correct vault and item IDs:
```yaml
onepassword:
  itemPath: "vaults/YOUR_VAULT_ID/items/YOUR_ITEM_ID"
```

### 2. Persistent State PVC

Async job metadata + history is stored in a BoltDB file mounted at `/app/state`. The chart provisions a small local PV (`model-manager-state`) that points at `/mnt/ai-model-cache/model-manager-state` on the **venus** node. Ensure the host path exists and has write permissions before syncing via Argo CD. You can adjust size, node, and host path via the `state` block in `values.yaml`.

### 3. API Token Secret

Mutating endpoints (installs, activation, deletion) are gated behind a bearer token. Populate the `model-manager-api-token` secret in the `ai` namespace (key `token`) or configure the `apiToken` block to sync from 1Password. The Knative Service refuses to start if the secret is missing when auth is enabled.

### 4. Build and Push Docker Image

The model-manager Docker image must be built and pushed to GHCR:

```bash
cd ~/source/repos/ol-model-manager
docker build -t ghcr.io/oremus-labs/ol-model-manager:0.4.4-go .
docker push ghcr.io/oremus-labs/ol-model-manager:0.4.4-go
```

## Components

- `ServiceAccount` - model-manager service account
- `Role` - Permissions to manage InferenceServices in the ai namespace
- `RoleBinding` - Binds role to service account
- `OnePasswordItem` - Creates secret for git-sync credentials
- `ServingRuntime` - vllm-runtime for ROCm-based vLLM inference
- `Service` (Knative) - model-manager application with git-sync sidecar

## Architecture

The Knative Service runs two containers:
1. **manager** - Go HTTP API exposing model management endpoints, using two PVCs (`venus-model-storage` for weights and `model-manager-state` for BoltDB state)
2. **git-sync** - Sidecar that continuously syncs the model catalog from Git

The manager reads model configurations and creates/updates KServe InferenceServices named `active-llm` based on API requests.
