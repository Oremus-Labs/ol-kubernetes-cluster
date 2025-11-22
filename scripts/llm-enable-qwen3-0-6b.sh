#!/usr/bin/env bash
set -euo pipefail

NS="${QWEN_NS:-qwen}"
RELEASE="${QWEN_RELEASE:-qwen3-0-6b}"
HF_ITEM_PATH="${HF_ITEM_PATH:-vaults/fekk46izlezqrgocthhcn4xwp4/items/x7v2wiq2m7xwf6qguv4a3xxhb4}"
CHART_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHART_PATH="${CHART_ROOT}/apps/workloads/qwen-vllm/chart"

if ! kubectl get namespace "${NS}" >/dev/null 2>&1; then
  kubectl create namespace "${NS}"
fi

cat <<EOF | kubectl apply -f -
apiVersion: onepassword.com/v1
kind: OnePasswordItem
metadata:
  name: hf-token
  namespace: ${NS}
spec:
  itemPath: "${HF_ITEM_PATH}"
EOF

echo "Waiting for hf-token secret to be available in ${NS}..."
for attempt in $(seq 1 30); do
  if kubectl get secret -n "${NS}" hf-token >/dev/null 2>&1; then
    break
  fi
  sleep 5
  if [[ "${attempt}" -eq 30 ]]; then
    echo "hf-token secret not available after waiting. Check 1Password operator."
    exit 1
  fi
done

echo "Applying ${RELEASE} InferenceService into namespace ${NS}..."
helm template "${RELEASE}" "${CHART_PATH}" --namespace "${NS}" | kubectl apply -n "${NS}" -f -

echo "Waiting for InferenceService/${RELEASE} to become Ready..."
for attempt in $(seq 1 60); do
  status="$(kubectl get inferenceservice -n "${NS}" "${RELEASE}" -o jsonpath='{range .status.conditions[?(@.type=="Ready")]}{.status}{end}' 2>/dev/null || true)"
  if [[ "${status}" == "True" ]]; then
    echo "InferenceService is Ready."
    exit 0
  fi
  sleep 10
done

echo "InferenceService did not become Ready in time. Current status:"
kubectl get inferenceservice -n "${NS}" "${RELEASE}"
kubectl describe inferenceservice -n "${NS}" "${RELEASE}" || true
kubectl get pods -n "${NS}" -l serving.kserve.io/inferenceservice="${RELEASE}"
exit 1
