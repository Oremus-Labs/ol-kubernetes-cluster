#!/usr/bin/env bash
set -euo pipefail

NS="${QWEN_NS:-qwen}"
RELEASE="${QWEN_RELEASE:-qwen3-0-6b}"
CHART_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHART_PATH="${CHART_ROOT}/apps/workloads/qwen-vllm/chart"

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
