# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ansible-based automation for deploying highly available Kubernetes clusters with external ETCD, HAProxy load balancing, and Calico CNI.

**Stack:** Ansible, Kubernetes 1.31.4, ETCD v3.5.20, Containerd 1.7.24, HAProxy 3.0.7, Calico 3.29.1

## Common Commands

```bash
# Full cluster installation
ansible-playbook -i hosts.ini install_kubernetes_cluster.yml

# Run specific components using tags
ansible-playbook -i hosts.ini install_kubernetes_cluster.yml -t etcd
ansible-playbook -i hosts.ini install_kubernetes_cluster.yml -t containerd
ansible-playbook -i hosts.ini install_kubernetes_cluster.yml -t kubelet
ansible-playbook -i hosts.ini install_kubernetes_cluster.yml -t kube_masters
ansible-playbook -i hosts.ini install_kubernetes_cluster.yml -t kube_workers
ansible-playbook -i hosts.ini install_kubernetes_cluster.yml -t haproxy

# Add new worker/ingress nodes to existing cluster
ansible-playbook -i hosts.ini add_kubernetes_node.yml

# Reset/teardown cluster
ansible-playbook -i hosts.ini reset-cluster.yml

# Deploy NTP for time synchronization
ansible-playbook -i hosts.ini deploy-ntp.yml

# Copy master certificates between nodes
ansible-playbook -i hosts.ini copy-masters-certs.yml
```

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    Ansible Control Machine                    │
└──────────────────────────────────────────────────────────────┘
                              │
          ┌───────────────────┼───────────────────┐
          ▼                   ▼                   ▼
    ┌───────────┐       ┌───────────┐       ┌───────────┐
    │  Master 0 │◄─────►│  Master 1 │◄─────►│  Master 2 │
    │ ETCD+API  │       │ ETCD+API  │       │ ETCD+API  │
    └───────────┘       └───────────┘       └───────────┘
          │                   │                   │
          └─────────┬─────────┴─────────┬─────────┘
                    │ ETCD Cluster (TLS)│
                    └─────────┬─────────┘
                              │
    ┌─────────────────────────┼─────────────────────────┐
    │           HAProxy (on workers/ingress)            │
    │      Load balances API requests to masters        │
    └─────────────────────────┬─────────────────────────┘
                              │
          ┌───────────────────┼───────────────────┐
          ▼                   ▼                   ▼
    ┌───────────┐       ┌───────────┐       ┌───────────┐
    │  Workers  │       │  Ingress  │       │    ...    │
    │(HAProxy)  │       │ (HAProxy) │       │           │
    └───────────┘       └───────────┘       └───────────┘
```

**Deployment Flow:**
1. First master generates all certs (ETCD TLS + Kubernetes PKI)
2. Certs fetched to control machine (`/tmp/k8s/`, `/tmp/etcd/certs/`)
3. Certs distributed to other masters before initialization
4. Workers join via token generated on first master

## Ansible Roles

| Role | Purpose |
|------|---------|
| `etcd` | Dynamic ETCD cluster with TLS (peer + client auth) using CFSSL |
| `containerd` | Container runtime with systemd cgroup driver |
| `kubelet` | Kubernetes node agent, kubeadm, kubectl |
| `kube_masters` | Master initialization, join token, Calico CNI deployment |
| `kube_workers` | Worker node join using token from master |
| `haproxy` | API load balancer (TCP 6443) with health checks |

## Key Files

- `group_vars/k8s.yml` - Version pinning, CIDR, tokens
- `hosts.ini` / `stage-leaseweb.ini` - Inventory files defining node groups
- `roles/*/templates/*.j2` - Jinja2 templates for configs (kubeadm, ETCD, HAProxy)

## Inventory Groups

- `kube_masters` - Control plane nodes (3 for HA)
- `kube_workers` - Worker nodes
- `kube_ingress` - Edge nodes running HAProxy
- `k8s` - Parent group containing all cluster nodes

## Certificate Locations

**On Masters:**
- `/etc/ssl/etcd/` - ETCD certificates
- `/etc/kubernetes/pki/` - Kubernetes PKI

**On Control Machine (temporary):**
- `/tmp/k8s/` - Kubernetes certs and tokens
- `/tmp/etcd/certs/` - ETCD certificates
