# Qwen LLM Runtime (hf:// Storage + Manual Lifecycle)

This repository now treats high-cost LLM deployments as **manual** workloads:

- KServe is configured with a HuggingFace-aware storage initializer (`hf://` URI support) and a reusable vLLM serving stack.
- The `qwen-vllm` Helm chart renders everything needed for a single `InferenceService`, HTTPRoute, and (optionally) hostPath PV/PVC.
- Argo CD no longer keeps this workload permanently on – you opt in/out by running the helper scripts below.

## Prerequisites

1. **Hugging Face token** – Rider tokens are vaulted in 1Password item `x7v2wiq2m7xwf6qguv4a3xxhb4`.  
   - The KServe chart automatically syncs this item into the `kserve` namespace as secret `hf-token`.
   - The enable script (below) installs the same OnePasswordItem into the `qwen` namespace so the storage initializer can read it.

2. **Node placement** – GPU-capable node `venus` must stay Ready with the AMD device plugin registered.

## Enable the model

```bash
scripts/llm-enable-qwen3-0-6b.sh
```

What it does:

- Renders `apps/workloads/qwen-vllm/chart` with Helm and applies it to the `qwen` namespace.
- KServe’s storage initializer downloads `hf://Qwen/Qwen3-0.6B` into `/mnt/models`.
- vLLM (`rocm/vllm-dev:nightly`) runs on node `venus`, requesting `amd.com/gpu: 1`.
- Gateway API HTTPRoute exposes `https://qwen3-0-6b.oremuslabs.app` (OpenAI-compatible API).

## Disable / clean up

```bash
scripts/llm-disable.sh
```

This deletes the `InferenceService` and waits for all pods to vanish; DNS/Gateway entries are removed automatically because they belong to the same Helm chart.

## Testing the endpoint

Once the service reports `Ready=True`, send a sample OpenAI-style request:

```bash
curl -sk https://qwen3-0-6b.oremuslabs.app/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
        "model": "qwen3-0-6b",
        "messages": [{"role": "user", "content": "Say hello from venus"}],
        "max_tokens": 64
      }'
```

Expect JSON with `choices[0].message.content` replying from Qwen.

## Optional persistent cache

The chart keeps the old `venus-models` hostPath definitions but disables them by default. If you want to reuse the local PV for faster cold starts, set `storage.enabled=true` when invoking Helm (or edit `values.yaml`) before running the enable script.

## Troubleshooting tips

- `kubectl -n qwen describe inferenceservice qwen3-0-6b` – see Download / storage initializer progress.
- `kubectl -n qwen logs <pod> -c storage-initializer` – watch Hugging Face download output.
- Ensure `hf-token` secret exists in `qwen` prior to enabling the service if you rely on private models.
