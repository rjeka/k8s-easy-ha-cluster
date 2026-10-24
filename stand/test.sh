#!/usr/bin/env bash
# Integration test on the Lima stand: deploy, prove idempotence, check the
# cluster. Pass --fresh to recreate the VMs first.
set -euo pipefail
cd "$(dirname "$0")/.."

INVENTORY=inventory/lima/hosts.yml
export KUBECONFIG=$PWD/inventory/lima/artifacts/admin.conf

if [ "${1:-}" = "--fresh" ]; then
  stand/down.sh
  stand/up.sh
fi

ansible-playbook -i "$INVENTORY" site.yml
ansible-playbook -i "$INVENTORY" site.yml | tee /dev/stderr | grep -E '^k8s-' > /tmp/k8s-stand-recap.$$
if grep -vqE 'changed=0 +unreachable=0 +failed=0' /tmp/k8s-stand-recap.$$; then
  echo "FAIL: second run changed something" >&2
  exit 1
fi
rm -f /tmp/k8s-stand-recap.$$

expected=$(ansible-inventory -i "$INVENTORY" --graph k8s_cluster | grep -c -- '--k8s-')
ready=$(kubectl get nodes --no-headers | awk '$2 == "Ready"' | wc -l | tr -d ' ')
[ "$ready" = "$expected" ] || { echo "FAIL: $ready of $expected nodes Ready" >&2; exit 1; }

members=$(limactl shell k8s-master00 -- sudo sh -c 'crictl exec $(crictl ps -q --name etcd) etcdctl \
  --cacert /etc/kubernetes/pki/etcd/ca.crt --cert /etc/kubernetes/pki/etcd/server.crt \
  --key /etc/kubernetes/pki/etcd/server.key member list' | grep -c ', started, ')
[ "$members" = 3 ] || { echo "FAIL: $members etcd members started" >&2; exit 1; }

kubectl wait --for=condition=Accepted gatewayclass/cilium --timeout=60s >/dev/null
kubectl top nodes >/dev/null

echo "PASS: $ready nodes Ready, $members etcd members, GatewayClass accepted"
