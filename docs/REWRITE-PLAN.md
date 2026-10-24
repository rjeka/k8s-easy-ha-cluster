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
3. [x] Role `common`: swap off, kernel modules, sysctl, time sync
4. [x] Role `containerd`
5. [x] Role `kubeadm`: packages, hold
6. [x] Role `kube_vip` (VIP itself is verified in step 7; control_plane must re-run kube_vip after init to switch the first node from super-admin.conf to admin.conf)
7. [x] Role `control_plane`: init first node, join the rest (VIP failover verified on the stand)
8. [x] Role `workers`: join
9. [x] Role `cilium` with Gateway API (kube-proxy replacement; LoadBalancer IPs for Gateways via Cilium LB IPAM + L2 announcements still to do)
10. [x] Addons: cert-manager, metrics-server (metrics-server uses --kubelet-insecure-tls until kubelet serving certs are CA-signed)
11. [ ] Playbooks `upgrade.yml` (node by node) and `reset.yml`
12. [ ] Tests: ansible-lint, molecule, local VM stand (3 control plane + 1 worker)
13. [ ] English docs: README, architecture diagram (archify), quickstart, variables, upgrade, troubleshooting
14. [ ] Claude files: project CLAUDE.md, agents (ansible dev, reviewer, stand tester), skills (stand up, checks, k8s upgrade)

## CI (to plan)

- On every PR: yamllint, ansible-lint, `--syntax-check`, molecule for single roles.
- Full playbook run (3 control plane + 1 worker) on real VMs: GitHub-hosted runners are too small
  for nested VMs, so either a self-hosted runner on the Mac stand or ephemeral Hetzner VMs
  created and destroyed by the job. Decide during step 12.

## Test stand

- Main stand: Lima on the Mac (arm64, Ubuntu 24.04), socket_vmnet shared network 192.168.105.0/24 for real L2 so kube-vip ARP works.
  `stand/up.sh` creates k8s-master00..02 and k8s-worker00, `stand/down.sh` deletes them, inventory `inventory/lima`.
- Hetzner Cloud as an optional second stand: billed even when powered off, so destroy instead of stop;
  private networks drop ARP for foreign IPs, so kube-vip ARP will not work there (use Hetzner LB).

## Later

- Talos Linux on the same stand for comparison (no Ansible/kubeadm, `talosctl`).
- Flatcar as a possible second platform.
