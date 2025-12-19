# Deploying a High Available Kubernetes Cluster

Ansible-based automation for deploying production-ready HA Kubernetes clusters.

## Component Versions

| Component | Version |
|-----------|---------|
| Kubernetes | 1.31.4 |
| ETCD | v3.5.20 |
| Containerd | 1.7.24 |
| Calico CNI | 3.29.1 |
| HAProxy | 3.0.7 |

## Features

- Dynamic master count (3, 5, 7+ nodes)
- External ETCD cluster with TLS (ECDSA certificates)
- HAProxy load balancer for API server
- Calico CNI networking
- Secure token handling (24h TTL)

## Quick Start

```bash
git clone https://github.com/rjeka/k8s-easy-ha-cluster.git
cd k8s-easy-ha-cluster
vim hosts.ini
ansible-playbook -i hosts.ini install_kubernetes_cluster.yml
```

## Available Playbooks

| Playbook | Description |
|----------|-------------|
| `install_kubernetes_cluster.yml` | Full cluster installation |
| `add_kubernetes_node.yml` | Add new worker/ingress nodes |
| `reset-cluster.yml` | Teardown cluster |
| `deploy-ntp.yml` | Configure NTP |
| `copy-masters-certs.yml` | Distribute master certificates |

## Installation

Full cluster (all components):

```bash
ansible-playbook -i hosts.ini install_kubernetes_cluster.yml
```

## Tags

Run specific components only:

```bash
ansible-playbook -i hosts.ini install_kubernetes_cluster.yml -t etcd
ansible-playbook -i hosts.ini install_kubernetes_cluster.yml -t containerd
ansible-playbook -i hosts.ini install_kubernetes_cluster.yml -t kubelet
ansible-playbook -i hosts.ini install_kubernetes_cluster.yml -t kube_masters
ansible-playbook -i hosts.ini install_kubernetes_cluster.yml -t kube_workers
ansible-playbook -i hosts.ini install_kubernetes_cluster.yml -t haproxy
```

## Inventory Groups

- `kube_masters` - Control plane nodes
- `kube_workers` - Worker nodes
- `kube_ingress` - Ingress nodes with HAProxy
- `k8s` - All cluster nodes



