---
name: stand-up
description: Create, start, inspect or delete the local Lima test stand (k8s-master00..02 and k8s-worker00 on 192.168.105.0/24) and deploy the cluster on it. Use when a task needs a running cluster to test against, or the user asks to bring the stand up or down.
---

# Lima stand

macOS on Apple silicon with Lima 2.x and socket_vmnet in `/opt/socket_vmnet` (sudoers file from
`limactl sudoers`). The VMs use about 16 GiB of RAM together.

| Node | Address |
| --- | --- |
| k8s-master00..02 | 192.168.105.201..203 |
| k8s-worker00 | 192.168.105.211 |
| API VIP | 192.168.105.200 on `lima0` |

## Up

```sh
stand/up.sh                                    # create missing VMs, start stopped ones, wait for SSH
ansible-playbook -i inventory/lima/hosts.yml site.yml
export KUBECONFIG=$PWD/inventory/lima/artifacts/admin.conf
kubectl get nodes -o wide
```

`stand/test.sh` does the deploy and the checks in one go; `stand/test.sh --fresh` recreates the VMs
first.

## Look around

```sh
limactl list
limactl shell k8s-master00                     # shell on a node; kubectl works there for your user
kubectl -n kube-system get lease plndr-cp-lock -o jsonpath='{.spec.holderIdentity}{"\n"}'
```

## Down

```sh
limactl stop k8s-master00 k8s-master01 k8s-master02 k8s-worker00   # keep the VMs
stand/down.sh                                                      # delete them
```

## Known stand issues

- A VM sometimes loses outbound TCP after the host sleeps: `limactl stop <vm> && limactl start <vm>`.
- `stand/node.yaml` disables DHCP on `lima0` and Lima's bundled containerd; a second address on
  `lima0` breaks etcd peer certificates. VMs created from an older template must be recreated.
- Ubuntu 22.04 cannot run on M4 hosts (kernel 5.15 crashes Python cryptography); CI covers it.
