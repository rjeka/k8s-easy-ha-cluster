# k8s-easy-ha-cluster

Ansible playbooks for a highly available Kubernetes cluster on bare metal or VMs (amd64 and arm64):
kubeadm, containerd, stacked etcd, kube-vip for the API endpoint and Cilium as CNI with Gateway API.

Work in progress. The previous version (Kubernetes 1.27, external etcd, HAProxy on every node)
is kept under the `legacy-2024` tag.
