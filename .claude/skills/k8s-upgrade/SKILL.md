---
name: k8s-upgrade
description: Bump the Kubernetes version in this repository and prove the upgrade on the Lima stand with zero API downtime, or run upgrade.yml against a cluster. Use when a new Kubernetes patch or minor release should be adopted, or the user asks to upgrade a cluster.
---

# Kubernetes upgrade

User-facing procedure: `docs/upgrade.md`. kubeadm moves one minor version at a time.

## Adopt a new release in the repository

1. Read the release notes and the kubeadm upgrade notes for the target version. Check that the
   pinned Cilium, kube-vip and containerd versions support it.
2. Set `k8s_version` in `inventory/example/group_vars/all.yml` and `inventory/lima/group_vars/all.yml`,
   and update the version in `docs/architecture.md` and `docs/variables.md`.
3. Prove it on the stand (below), then run the `checks` skill.

## Prove the upgrade on the stand

Deploy the previous version on fresh VMs, then upgrade while probing the API through the VIP:

```sh
stand/down.sh && stand/up.sh
ansible-playbook -i inventory/lima/hosts.yml site.yml -e k8s_version=<previous>
export KUBECONFIG=$PWD/inventory/lima/artifacts/admin.conf

( ok=0; fail=0; while [ ! -f /tmp/k8s-upgrade-done ]; do
    if curl -sk --max-time 2 https://192.168.105.200:6443/readyz >/dev/null; then ok=$((ok+1)); else fail=$((fail+1)); fi
    sleep 1
  done; echo "api probes failed: $fail of $((ok+fail))" ) &

ansible-playbook -i inventory/lima/hosts.yml upgrade.yml
touch /tmp/k8s-upgrade-done; wait; rm -f /tmp/k8s-upgrade-done

kubectl get nodes                                  # every node on the new version, Ready
ansible-playbook -i inventory/lima/hosts.yml site.yml   # converges the kubeadm config once
stand/test.sh                                       # then changed=0 and the cluster checks
```

The upgrade passes when every node reports the new version, no node is cordoned and the probe loop
reports 0 failed probes.

## Upgrade a real cluster

Only on the user's explicit request, with their inventory. Take an etcd backup first
(`docs/upgrade.md#etcd-backup`), then `ansible-playbook -i <inventory> upgrade.yml`. If a node fails
it stays cordoned on purpose; report the failed task and do not uncordon without the user.
