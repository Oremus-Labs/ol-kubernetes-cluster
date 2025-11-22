#!/usr/bin/env bash
set -euo pipefail

NS="${QWEN_NS:-qwen}"
RELEASE="${QWEN_RELEASE:-qwen3-0-6b}"

echo "Deleting InferenceService/${RELEASE} from namespace ${NS} (if present)..."
kubectl -n "${NS}" delete inferenceservice "${RELEASE}" --ignore-not-found

echo "Waiting for pods owned by ${RELEASE} to terminate..."
for attempt in $(seq 1 30); do
  count="$(kubectl -n "${NS}" get pods -l serving.kserve.io/inferenceservice="${RELEASE}" --no-headers 2>/dev/null | wc -l | xargs)"
  if [[ "${count}" == "0" ]]; then
    echo "All pods removed."
    exit 0
  fi
  sleep 5
done

echo "Pods for ${RELEASE} still present:"
kubectl -n "${NS}" get pods -l serving.kserve.io/inferenceservice="${RELEASE}"
exit 1
