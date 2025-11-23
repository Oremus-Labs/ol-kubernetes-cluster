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

### 2. Build and Push Docker Image

The model-manager Docker image must be built and pushed to GHCR:

```bash
cd ~/source/repos/ol-model-manager
docker build -t ghcr.io/oremus-labs/ol-model-manager:0.1.6 .
docker push ghcr.io/oremus-labs/ol-model-manager:0.1.6
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
1. **manager** - FastAPI application exposing model management HTTP API
2. **git-sync** - Sidecar that continuously syncs the model catalog from Git

The manager reads model configurations and creates/updates KServe InferenceServices named `active-llm` based on API requests.
