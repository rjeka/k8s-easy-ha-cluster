# Upgrades

## Kubernetes

kubeadm moves one minor version at a time (1.36 to 1.37, not 1.35 to 1.37). Patch releases within a
minor version can be skipped.

1. Read the release notes and the [kubeadm upgrade guide](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/)
   for the target version.
2. Back up etcd (see below).
3. Set the new `k8s_version` in `group_vars/all.yml`.
4. Run the upgrade:

   ```sh
   ansible-playbook -i inventory/mycluster/hosts.yml upgrade.yml
   ```

5. Run `site.yml` once more. It records the new version in the kubeadm configuration on the first
   control plane node; after that it reports no changes.

`upgrade.yml` goes through the control plane nodes one at a time, the first one first, then through
the workers in batches of `upgrade_workers_batch` (1 by default). On each node it:

1. Checks that the target is at most one minor version ahead of the cluster.
2. Switches the apt repository to the new minor version and upgrades kubeadm.
3. On a control plane node, moves the VIP away: the kube-vip manifest is parked, the playbook waits
   until another node holds the Lease and drops the address from the interface. With more than one
   control plane node the API stays reachable through the VIP during the whole upgrade.
4. Runs `kubeadm upgrade apply` on the first control plane node and `kubeadm upgrade node` on the
   others.
5. Drains the node, upgrades kubelet and kubectl, holds the packages again and restarts kubelet.
6. Waits for the node to become Ready and uncordons it.
7. Puts the kube-vip manifest back, also when a step failed.

Nodes whose kubelet already runs the target version are skipped, so after a failure `upgrade.yml`
can be run again. A node that failed after its kubelet was upgraded (waiting for Ready or
uncordoning) is skipped on that re-run and stays cordoned: check it and run `kubectl uncordon <node>`.

If a step fails, the play stops on that node and reports which task failed. A drained node stays
cordoned on purpose, so that workloads do not land on a half-upgraded kubelet. Fix the cause and run
`upgrade.yml` again, or accept the node as it is with `kubectl uncordon <node>`.

`site.yml` refuses to run against nodes whose installed version differs from `k8s_version` and points
to `upgrade.yml`, so a version bump never slips into an ordinary deploy.

## Other components

`upgrade.yml` handles Kubernetes only. The rest is upgraded by changing the version in
`group_vars/all.yml` and running `site.yml`:

- Cilium, metrics-server, cert-manager and Gateway API CRDs are upgraded in place with Helm and
  server-side apply. Read the Cilium upgrade notes first; Cilium supports upgrades between
  adjacent minor versions. For Gateway API, update `cilium_gateway_api_crds_sha256` as well.
- containerd and runc binaries are replaced and containerd is restarted. Running containers keep
  running. `site.yml` does not drain; for a careful rollout drain each node yourself and run
  `ansible-playbook -i inventory/mycluster/hosts.yml site.yml --limit <node>`, then uncordon it.
- kube-vip: the static pod manifest is rewritten and kubelet restarts the pod. Upgrade one control
  plane node at a time with `--limit` (and `-i` for your inventory).

## etcd backup

Before any upgrade, take a snapshot on one control plane node:

```sh
sudo crictl exec $(sudo crictl ps -q --name etcd) etcdctl \
  --cacert /etc/kubernetes/pki/etcd/ca.crt \
  --cert /etc/kubernetes/pki/etcd/server.crt \
  --key /etc/kubernetes/pki/etcd/server.key \
  snapshot save /var/lib/etcd/snapshot.db
sudo install -o "$USER" -m 0600 /var/lib/etcd/snapshot.db ~/etcd-$(date +%F).db
```

Copy the snapshot and `/etc/kubernetes/pki` off the node. Scheduled backups are not part of the
playbooks yet.
