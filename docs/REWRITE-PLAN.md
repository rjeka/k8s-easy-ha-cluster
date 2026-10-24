# Rewrite plan (work in progress)

Branch `ansible-rewrite`. The previous version is tagged `legacy-2024`.

## Decisions

- Ansible + kubeadm (`v1beta4` config), packages from `pkgs.k8s.io`, version pinned and held.
- 3 control plane nodes by default (odd number enforced), any number of workers.
- Stacked etcd via `kubeadm init --upload-certs` / `kubeadm join --control-plane`
  (replaces the old external etcd role and cfssl).
- kube-vip (static pod, ARP mode) is the only API endpoint option
  (replaces HAProxy on every node and the kubelet.conf sed hack).
- containerd with systemd cgroup driver.
- Cilium is the only CNI; Gateway API through Cilium replaces ingress-nginx (retired).
- Optional addons behind flags: cert-manager, metrics-server.
- Ubuntu 22.04/24.04 and Debian 12, amd64 and arm64.

## Steps

1. [x] Tag legacy, clean the repo
2. [x] Skeleton: ansible.cfg, inventory/example, group_vars, preflight in site.yml
3. [ ] Role `common`: swap off, kernel modules, sysctl, time sync
4. [ ] Role `containerd`
5. [ ] Role `kubeadm`: packages, hold
6. [ ] Role `kube_vip`
7. [ ] Role `control_plane`: init first node, join the rest
8. [ ] Role `workers`: join
9. [ ] Role `cilium` with Gateway API
10. [ ] Addons: cert-manager, metrics-server
11. [ ] Playbooks `upgrade.yml` (node by node) and `reset.yml`
12. [ ] Tests: ansible-lint, molecule, local VM stand (3 control plane + 1 worker)
13. [ ] English docs: README, architecture diagram (archify), quickstart, variables, upgrade, troubleshooting
14. [ ] Claude files: project CLAUDE.md, agents (ansible dev, reviewer, stand tester), skills (stand up, checks, k8s upgrade)

## Test stand

- Main stand: local VMs on the Mac (Apple Silicon, arm64) via Lima or Vagrant, real L2 so kube-vip ARP works.
- Hetzner Cloud as an optional second stand: billed even when powered off, so destroy instead of stop;
  private networks drop ARP for foreign IPs, so kube-vip ARP will not work there (use Hetzner LB).

## Later

- Talos Linux on the same stand for comparison (no Ansible/kubeadm, `talosctl`).
- Flatcar as a possible second platform.
