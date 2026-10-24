# Variables

Cluster-wide settings live in `inventory/<cluster>/group_vars/all.yml`. Role defaults (prefixed
with the role name) can be overridden there too. Any variable can also be set per host in
`hosts.yml` or `host_vars/`.

## Cluster

| Variable | Default | Description |
| --- | --- | --- |
| `k8s_version` | `1.37.1` | Kubernetes version. Packages come from `pkgs.k8s.io/core:/stable:/v<minor>` and are held. Change it only together with `upgrade.yml`: `site.yml` refuses to move an existing node to another version. |
| `k8s_cluster_name` | `kubernetes` | `clusterName` in the kubeadm configuration. |
| `k8s_vip` | none | Virtual IP of the API server. Must be a free address in the nodes' L2 network that no node uses. |
| `k8s_vip_interface` | none | Interface on the control plane nodes where kube-vip binds the VIP. |
| `k8s_api_port` | `6443` | API server port, on the nodes and on the VIP. |
| `k8s_node_ip` | `{{ ansible_host }}` | Address the kubelet, the API server and etcd use on this node. Set it per host when Ansible connects over another network. |
| `k8s_pod_subnet` | `10.244.0.0/16` | Pod network. kubeadm splits it into per-node ranges that Cilium uses. |
| `k8s_service_subnet` | `10.96.0.0/12` | Service network. |
| `k8s_kubeconfig_local_path` | `{{ inventory_dir }}/artifacts/admin.conf` | Where the admin kubeconfig is fetched on the machine running Ansible. |

## Container runtime

| Variable | Default | Description |
| --- | --- | --- |
| `containerd_version` | `2.4.2` | containerd release from GitHub. The archive is checked against its published sha256. |
| `containerd_runc_version` | `1.5.2` | runc release from GitHub. |
| `containerd_download_dir` | `/var/cache/k8s-downloads` | Download cache on the nodes. |

## kube-vip

| Variable | Default | Description |
| --- | --- | --- |
| `kube_vip_version` | `v1.3.1` | kube-vip image tag. |
| `kube_vip_image` | `ghcr.io/kube-vip/kube-vip:{{ kube_vip_version }}` | Full image reference, for a private registry. |

## Cilium and Gateway API

| Variable | Default | Description |
| --- | --- | --- |
| `cilium_version` | `1.20.4` | Cilium Helm chart version. |
| `cilium_kube_proxy_replacement` | `true` | Cilium replaces kube-proxy and kubeadm skips its kube-proxy addon. Decide before the first deploy: switching it on a running cluster is not handled. |
| `cilium_gateway_api_enabled` | `true` | Install the Gateway API standard CRDs and enable the Cilium Gateway controller. |
| `cilium_gateway_api_version` | `1.6.3` | Gateway API release. |
| `cilium_gateway_api_crds_sha256` | pinned | sha256 of `standard-install.yaml` for that release. Update it together with the version. |
| `cilium_helm_version` | `4.3.1` | Helm binary installed on the first control plane node. |

## Addons

| Variable | Default | Description |
| --- | --- | --- |
| `addon_metrics_server_enabled` | `true` | Install metrics-server (`kubectl top`). |
| `addons_metrics_server_chart_version` | `3.14.0` | metrics-server chart version. |
| `addons_metrics_server_kubelet_insecure_tls` | `true` | kubeadm kubelets serve self-signed certificates. Turn this off once kubelet serving certificates are signed by the cluster CA. |
| `addon_cert_manager_enabled` | `false` | Install cert-manager with its CRDs. |
| `addons_cert_manager_version` | `1.21.3` | cert-manager chart version. |

## Nodes

| Variable | Default | Description |
| --- | --- | --- |
| `common_ntp_servers` | `[]` | chrony servers. Empty keeps the distribution pool; set your own when the nodes have no internet access. |
| `common_packages` | see defaults | Base packages installed on every node. |
| `common_kernel_modules` | `overlay`, `br_netfilter` | Modules loaded now and on boot. |
| `common_sysctl` | IP forwarding and bridge netfilter | Written to `/etc/sysctl.d/99-k8s.conf`. |

## Upgrades

| Variable | Default | Description |
| --- | --- | --- |
| `upgrade_workers_batch` | `1` | How many workers `upgrade.yml` upgrades at once. A number or a percentage. |
| `upgrade_drain_timeout` | `5m` | Timeout for `kubectl drain`. |

## Playbook switches

| Variable | Playbook | Description |
| --- | --- | --- |
| `reset_confirm` | `reset.yml` | Must be `true` to wipe the cluster. |
