# Quick start

## Requirements

Nodes:

- Ubuntu 22.04 or 24.04 (Debian 12 is accepted but not tested yet), amd64 or arm64.
- An odd number of control plane nodes (3 is the usual choice) and any number of workers.
- 2 CPU and 2 GiB of RAM at least per node; 4 GiB is more comfortable.
- All nodes in one L2 network: kube-vip announces the API address with ARP.
- SSH access with a user that can `sudo` (without a password, or add `--ask-become-pass`).
- Internet access to pkgs.k8s.io, github.com (with its release download hosts), get.helm.sh, ghcr.io,
  registry.k8s.io, quay.io and the Helm chart repositories (no offline mode yet).

One free address in the same network for the API endpoint (`k8s_vip`). It must not belong to any
node and must be outside the DHCP range.

Machine running Ansible: ansible-core 2.16 or newer and the collections from `requirements.yml`:

```sh
ansible-galaxy collection install -r requirements.yml
```

## Inventory

Copy the example and adjust it:

```sh
cp -r inventory/example inventory/mycluster
```

`inventory/mycluster/hosts.yml` lists the nodes in two groups, `control_plane` and `workers`:

```yaml
all:
  vars:
    ansible_user: ubuntu
  children:
    k8s_cluster:
      children:
        control_plane:
          hosts:
            cp1: {ansible_host: 10.0.0.11}
            cp2: {ansible_host: 10.0.0.12}
            cp3: {ansible_host: 10.0.0.13}
        workers:
          hosts:
            worker1: {ansible_host: 10.0.0.21}
```

The inventory hostname becomes the Kubernetes node name. `group_vars/all.yml` from the example holds
every required variable; keep them all and adjust at least:

```yaml
k8s_vip: 10.0.0.10          # free address for the API server
k8s_vip_interface: eth1     # interface that carries the node addresses on the control plane nodes
```

`k8s_node_ip` is `{{ ansible_host }}` in the example. Set it per host if Ansible reaches the nodes over a
different network than the one the cluster should use. All variables are described in
[variables.md](variables.md).

## Deploy

```sh
ansible-playbook -i inventory/mycluster/hosts.yml site.yml
```

The playbook prepares all nodes, initialises the first control plane node, joins the others one at a
time, joins the workers in parallel and installs Cilium and the addons. Re-running it is safe: on a
healthy cluster it reports no changes.

The admin kubeconfig is fetched to `inventory/mycluster/artifacts/admin.conf` (mode 0600). It points to
the VIP, so it keeps working when any one control plane node is down:

```sh
export KUBECONFIG=$PWD/inventory/mycluster/artifacts/admin.conf
kubectl get nodes -o wide
kubectl -n kube-system get pods
```

The same kubeconfig is placed in `~/.kube/config` of `ansible_user` on every control plane node.
It grants full cluster-admin: never commit or share it (`inventory/*/artifacts/` is git-ignored) and
create less privileged kubeconfigs for daily work.

## Add nodes

Add the host to `hosts.yml` and run `site.yml` again. New control plane nodes join with a fresh
certificate key, workers with a fresh token. Keep the number of control plane nodes odd.

## Remove the cluster

```sh
ansible-playbook -i inventory/mycluster/hosts.yml reset.yml -e reset_confirm=true
```

This runs `kubeadm reset`, deletes the cluster state, reboots the nodes to drop the Cilium datapath
and removes the local `artifacts/admin.conf`. Packages and containerd stay, so the next `site.yml` run is faster.

## Local stand on Lima

The repository includes a stand for macOS on Apple silicon: three control plane nodes and one
worker as Lima VMs with Ubuntu 24.04 on a shared network (192.168.105.0/24, VIP 192.168.105.200).

Prerequisites: [Lima](https://lima-vm.io) 2.x and [socket_vmnet](https://github.com/lima-vm/socket_vmnet)
installed to `/opt/socket_vmnet` with the sudoers file from `limactl sudoers`. The VMs need about
16 GiB of RAM together.

```sh
stand/up.sh                 # create or start k8s-master00..02 and k8s-worker00
stand/test.sh               # deploy, check idempotence, nodes, etcd members, Gateway API, metrics
stand/test.sh --fresh       # the same on newly created VMs
limactl shell k8s-master00  # log into a node
stand/down.sh               # delete the VMs
```

The stand inventory is `inventory/lima`. It reads the SSH user from `$USER` and the key from
`~/.lima/_config/user`.
