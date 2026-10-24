#!/usr/bin/env bash
# Destroy the stand completely
set -euo pipefail
for name in k8s-master00 k8s-master01 k8s-master02 k8s-worker00; do
  limactl delete --force "$name" 2>/dev/null || true
done
