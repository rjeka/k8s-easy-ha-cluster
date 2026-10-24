# Architecture

![Architecture](architecture.png)

An interactive version is in [architecture.html](architecture.html); its source is
[architecture.json](architecture.json), rendered with [archify](https://github.com/tt-a1i/archify).

## Nodes

Every node runs containerd, kubelet and the Cilium agent. Control plane nodes also run the static
pods that kubeadm creates (kube-apiserver, kube-controller-manager, kube-scheduler, etcd) and a
kube-vip static pod. Workers run only workloads.

etcd is stacked: each control plane node runs one etcd member next to its API server. Three
control plane nodes survive the loss of one, five survive the loss of two. That is why the
inventory must contain an odd number of control plane nodes.

## API endpoint

All clients, including kubelets, Cilium and the fetched admin kubeconfig, reach the API server
through `k8s_vip:k8s_api_port`. kubeadm writes the VIP as `controlPlaneEndpoint` and into the API
server certificate.

kube-vip runs on every control plane node in ARP mode with leader election through the
`kube-system/plndr-cp-lock` Lease. The leader binds the VIP to `k8s_vip_interface` and answers ARP
for it. If the leader dies, another node takes the Lease within about 15 seconds and sends
gratuitous ARP. Traffic is not balanced between API servers: the VIP sits on one node at a time.

Bootstrapping has a chicken-and-egg problem: kube-vip needs the API to hold the Lease, and the API
is reached through the VIP. On the first node kube-vip therefore starts with `super-admin.conf`
(Kubernetes 1.29 and later) and switches to `admin.conf` once the node is initialised.

## Network

Cilium is installed with Helm and replaces kube-proxy (`kubeProxyReplacement`), so kubeadm skips
its kube-proxy addon. Cilium talks to the API through the VIP because the `kubernetes` Service does
not route anything until Cilium itself is running. Pod addresses come from the per-node ranges that
kubeadm carves out of `k8s_pod_subnet` (IPAM mode `kubernetes`).

The Gateway API standard CRDs are applied before Cilium, which then registers the `cilium`
GatewayClass. Load balancer addresses for Gateways (LB IPAM, L2 announcements) are not set up yet.

## Deployment flow

`site.yml` runs in four plays:

1. All nodes: base packages, swap off, kernel modules and sysctl, chrony, containerd with runc,
   kubelet, kubeadm and kubectl from pkgs.k8s.io (pinned and held).
2. Control plane: kube-vip manifest, `kubeadm init --upload-certs` on the first node, then the other
   nodes join one at a time (`throttle: 1`) so etcd grows by one member at a time.
3. Workers: join in parallel and get the `node-role.kubernetes.io/worker` label.
4. On the first control plane node: Gateway API CRDs, Cilium, metrics-server and cert-manager.

## Re-runs and recovery

Whether a control plane node is part of the cluster is decided from the etcd member list, not
from local files or the Node object. A join that failed halfway can leave `admin.conf` and a Node
behind without a working etcd member. Such a node is cleaned up and joined again: `kubeadm reset`,
the stale Node and the unstarted etcd member are removed, a VIP left on its interface is dropped.
If etcd cannot be queried at all, the play fails instead of guessing, so a transient API error
never resets a healthy node.

A worker counts as joined when its Node object exists. Otherwise it is reset and joined again.

## Versions

| Component | Version | Variable |
| --- | --- | --- |
| Kubernetes | 1.37.1 | `k8s_version` |
| containerd | 2.4.2 | `containerd_version` |
| runc | 1.5.2 | `containerd_runc_version` |
| kube-vip | v1.3.1 | `kube_vip_version` |
| Cilium | 1.20.4 | `cilium_version` |
| Gateway API | 1.6.3 | `cilium_gateway_api_version` |
| Helm | 4.3.1 | `cilium_helm_version` |
| metrics-server chart | 3.14.0 | `addons_metrics_server_chart_version` |
| cert-manager | 1.21.3 | `addons_cert_manager_version` |
