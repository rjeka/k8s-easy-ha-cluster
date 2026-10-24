# Troubleshooting

## Looking around on a node

```sh
sudo crictl ps -a                         # all containers, including static pods
sudo crictl logs <container-id>
sudo journalctl -u kubelet -b --no-pager | tail -50
sudo journalctl -u containerd -b --no-pager | tail -50
ls /etc/kubernetes/manifests              # static pods kubelet runs on this node
kubectl get nodes -o wide                 # works for ansible_user on control plane nodes
```

etcd members and their health, on any control plane node:

```sh
sudo crictl exec $(sudo crictl ps -q --name etcd) etcdctl \
  --cacert /etc/kubernetes/pki/etcd/ca.crt \
  --cert /etc/kubernetes/pki/etcd/server.crt \
  --key /etc/kubernetes/pki/etcd/server.key \
  member list -w table
```

Which node holds the VIP:

```sh
kubectl -n kube-system get lease plndr-cp-lock -o jsonpath='{.spec.holderIdentity}{"\n"}'
ip -br addr show dev <k8s_vip_interface>   # on the node, the VIP shows up as an extra /32
```

## kubectl says "connection to the server localhost:8080 was refused"

kubectl has no kubeconfig. On your machine set
`KUBECONFIG=inventory/<cluster>/artifacts/admin.conf`. On a control plane node, run kubectl as
`ansible_user` (it has `~/.kube/config`) or as root with `--kubeconfig /etc/kubernetes/admin.conf`.
Workers have no admin credentials by design.

## The VIP does not answer

- Check that `k8s_vip` is free: no other host, no DHCP lease, no cloud reservation.
- Check that `k8s_vip_interface` exists on every control plane node and carries the node address.
- Cloud networks and many virtual switches drop ARP for addresses they did not assign (Hetzner
  private networks, most public clouds). kube-vip ARP mode does not work there; use the provider's
  load balancer in front of the API servers instead.
- Look at the kube-vip logs: `sudo crictl logs $(sudo crictl ps -q --name kube-vip)`.

## etcd rejects a member or a join hangs at etcd

The usual cause is a node with two addresses in the same network, for example a second DHCP
address next to a static one. etcd then sees connections from an address that is not in the peer
certificate. Make sure each node has exactly one address in the cluster network and that
`k8s_node_ip` is that address.

If `site.yml` fails with "etcd member ... uses ..., but k8s_node_ip is ...", a node's address has
changed or `k8s_node_ip` is wrong. Fix the variable (or the node's address) rather than resetting the
node; the check is there to avoid wiping a healthy member.

## A join failed halfway

Run `site.yml` again. A control plane node without a started etcd member, or a worker without a
Node object, is reset and joined again. Healthy nodes are not touched. If the first control plane
node itself failed during `kubeadm init`, run `reset.yml` and deploy from scratch.

## Nodes stay NotReady

The nodes become Ready only after Cilium is running. Check the Cilium pods:

```sh
kubectl -n kube-system get pods -l k8s-app=cilium -o wide
kubectl -n kube-system logs ds/cilium --tail=50
```

Cilium reaches the API through the VIP, so a VIP problem shows up here as well.

## `kubectl top` returns an error

metrics-server needs a minute after the deploy to collect the first metrics. If it keeps failing,
check `kubectl -n kube-system logs deploy/metrics-server`. With
`addons_metrics_server_kubelet_insecure_tls: false` the kubelets need serving certificates signed by
the cluster CA.

## `site.yml` says "run upgrade.yml to change the cluster version"

`k8s_version` differs from the version installed on a node. Either revert `k8s_version` or run
`upgrade.yml`, see [upgrade.md](upgrade.md).

## An upgrade stopped and a node is cordoned

This is intended. The error message names the failed task. Fix the cause and run `upgrade.yml`
again, or `kubectl uncordon <node>` to keep the node as it is. A re-run skips nodes whose kubelet
is already upgraded, so a node that failed at the very end has to be uncordoned by hand. kube-vip is restored even on failure;
check that `/etc/kubernetes/manifests/kube-vip.yaml` exists on the control plane nodes.

## Starting over

```sh
ansible-playbook -i inventory/<cluster>/hosts.yml reset.yml -e reset_confirm=true
ansible-playbook -i inventory/<cluster>/hosts.yml site.yml
```
