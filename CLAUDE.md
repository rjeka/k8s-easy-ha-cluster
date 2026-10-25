# k8s-easy-ha-cluster

Ansible playbooks for an HA Kubernetes cluster: kubeadm, containerd, stacked etcd, kube-vip (ARP)
for the API endpoint, Cilium with Gateway API. User docs are in `README.md` and `docs/`; read
`docs/architecture.md` before changing roles. `docs/REWRITE-PLAN.md` holds decisions and the backlog.

## Layout

- `site.yml` deploys or converges, `upgrade.yml` upgrades Kubernetes node by node, `reset.yml` wipes.
- Roles in play order: `common`, `containerd`, `kubeadm` (all nodes), `kube_vip`, `control_plane`,
  `workers`, `cilium`, `addons`; `upgrade` is used only by `upgrade.yml`.
- `inventory/example` is the template users copy; `inventory/lima` is the local stand.
- `stand/` creates the Lima VMs and runs the integration test; `tests/node-roles.yml` is what CI
  applies to GitHub runners.

## Rules

- Always pass `-i` to `ansible-playbook`. Without it ansible.cfg falls back to `inventory/example`,
  the template users copy. Agents run playbooks only against `inventory/lima/hosts.yml` unless the
  user explicitly names another inventory.
- Every role must be idempotent: a second `site.yml` run on a healthy cluster reports `changed=0`
  on every host. Give `command`/`shell` tasks a real `changed_when`.
- Role variables are prefixed with the role name (ansible-lint `var-naming`); cluster-wide
  variables start with `k8s_` and live in the inventory `group_vars/all.yml`. A new required
  variable goes into both `inventory/example` and `inventory/lima`, and into `docs/variables.md`.
- Versions are pinned. Downloads are verified with a checksum; never pipe a script from the network.
- Secrets (join tokens, certificate keys, rendered join configs) are handled with `no_log: true`.
- Control plane membership is decided from the etcd member list, never from local files or the
  Node object. Any change that can reset a node must fail closed when etcd cannot be queried.
- Upgrades must not drop the API: the VIP is moved off a control plane node before it is upgraded.
- Supported: Ubuntu 22.04/24.04, Debian 12; amd64 and arm64. Do not add distribution-specific
  branches without a way to test them.
- Docs and comments are in English. Keep `docs/` in sync with behaviour changes in the same commit.

## Checks

Run before every commit (CI runs the same):

```sh
yamllint .
ansible-lint
for p in site.yml upgrade.yml reset.yml tests/node-roles.yml; do ansible-playbook --syntax-check "$p"; done
```

Changes to roles are proven on the stand with `stand/test.sh` (see the `stand-up` and `checks`
skills). Ubuntu 22.04 cannot run on Apple M4 hosts (kernel 5.15); CI covers it.

## Agents and skills

- Agents in `.claude/agents`: `ansible-dev` writes role changes, `reviewer` reviews a diff,
  `stand-tester` proves a change on the Lima stand.
- Skills in `.claude/skills`: `stand-up`, `checks`, `k8s-upgrade`.
