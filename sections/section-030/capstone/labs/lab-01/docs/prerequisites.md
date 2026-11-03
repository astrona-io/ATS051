---
draft: true
exam_objectives:
- Understand and Use Alertmanager
---
# Prerequisites

Use astrona, kubectl, kind, Python 3 and Podman. A kubeconfig identifies the cluster and credentials that kubectl, the Kubernetes command-line tool, uses.

Select the private kubeconfig of this environment before every command:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-051-lab-030-cap-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-051-lab-030-cap-01" || exit 1
```
