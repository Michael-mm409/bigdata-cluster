#!/usr/bin/env bash
set -euo pipefail

if ! command -v nvidia-smi >/dev/null 2>&1; then
  echo '{"name":"gpu","addresses":[]}'
  exit 0
fi

mapfile -t gpu_ids < <(nvidia-smi --query-gpu=index --format=csv,noheader | tr -d ' ')
if [[ ${#gpu_ids[@]} -eq 0 ]]; then
  echo '{"name":"gpu","addresses":[]}'
  exit 0
fi

quoted_ids=()
for id in "${gpu_ids[@]}"; do
  quoted_ids+=("\"${id}\"")
done

IFS=,
printf '{"name":"gpu","addresses":[%s]}\n' "${quoted_ids[*]}"
