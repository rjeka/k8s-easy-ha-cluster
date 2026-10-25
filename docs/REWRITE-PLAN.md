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
11. [x] Playbooks `upgrade.yml` (node by node) and `reset.yml` (1.36.5 -> 1.37.1 verified with zero failed API probes: the VIP is handed to another node before each control plane node is upgraded)
12. [x] Tests: lint, stand integration test and CI (green on GitHub since 1c449fd)
    - `.github/workflows/ci.yml`: yamllint, ansible-lint, syntax-check, then node roles applied twice
      on GitHub runners (ubuntu-22.04, ubuntu-24.04, ubuntu-24.04-arm) via `tests/node-roles.yml`.
      Runners are real VMs with systemd and kernel modules, so this replaces molecule in containers.
    - `stand/test.sh [--fresh]`: full deploy on Lima, idempotence, nodes Ready, 3 etcd members, GatewayClass.
    - Ubuntu 22.04 cannot be tested on the M4 stand (kernel 5.15: Python cryptography dies with SIGILL),
      CI covers it on amd64. Debian 12 still untested.
13. [x] English docs: README, architecture diagram (archify), quickstart, variables, upgrade, troubleshooting
14. [x] Claude files: project CLAUDE.md, agents (ansible dev, reviewer, stand tester), skills (stand up, checks, k8s upgrade)

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

## Hardening backlog (from the security review)

- Pin sha256 per version and arch for containerd, runc and Helm instead of same-origin checksum files, or verify GPG signatures.
- Pin Helm charts and the kube-vip image by digest; pin the pkgs.k8s.io key fingerprint.
- Pin collection versions, CI pip packages and GitHub Actions by commit SHA.
- `reset.yml`: require `reset_confirm` to equal `k8s_cluster_name`; remove kubeadm join configs after joining.
- Audit log, Secret encryption at rest, Pod Security Admission, CA-signed kubelet serving certificates, scheduled etcd backups.

## Later

- Talos Linux on the same stand for comparison (no Ansible/kubeadm, `talosctl`).
- Flatcar as a possible second platform.
