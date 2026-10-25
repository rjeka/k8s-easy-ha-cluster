---
name: checks
description: Run the repository checks - yamllint, ansible-lint, syntax checks of all playbooks and, for role changes, the Lima stand integration test with the idempotence check. Use before every commit and when asked whether a change is ready.
---

# Checks

## Static (always)

```sh
yamllint .
ansible-lint
for p in site.yml upgrade.yml reset.yml tests/node-roles.yml; do
  ansible-playbook --syntax-check "$p"
done
```

These are the same checks as the `lint` job in `.github/workflows/ci.yml`. If ansible-lint cannot
find the collections, install them into the project: `ansible-galaxy collection install -r
requirements.yml -p collections`.

## Stand (role, template or playbook changes)

```sh
stand/up.sh
stand/test.sh            # add --fresh when the change affects a first deploy
```

`stand/test.sh` fails unless the second `site.yml` run reports `changed=0` on every host, all nodes
are Ready, three etcd members are started, the cilium GatewayClass is Accepted and `kubectl top
nodes` works.

## CI

After a push, CI repeats the static checks and applies the node roles twice on ubuntu-22.04,
ubuntu-24.04 and ubuntu-24.04-arm runners:

```sh
gh run list --branch "$(git branch --show-current)" --limit 1
gh run watch <run-id> --exit-status
```

Report each check with PASS or FAIL and the first error lines of any failure.
