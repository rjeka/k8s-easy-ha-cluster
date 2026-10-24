#!/usr/bin/env bash
# Local test stand: 3 control plane + 1 worker on Lima (socket_vmnet shared,
# 192.168.105.0/24). Static addresses sit above the DHCP leases Lima hands out
# from .2 upwards.
set -euo pipefail
cd "$(dirname "$0")"

NODES="k8s-master00:192.168.105.201 k8s-master01:192.168.105.202 k8s-master02:192.168.105.203 k8s-worker00:192.168.105.211"

for node in $NODES; do
  name="${node%%:*}"
  ip="${node#*:}"
  if limactl list -q | grep -qx "$name"; then
    limactl start --tty=false "$name"
  else
    limactl start --tty=false --name "$name" --set ".param.StaticIP = \"$ip\"" node.yaml
  fi
done
limactl list
