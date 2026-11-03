---
draft: true
exam_objectives:
- Dashboarding basics
---
# Prerequisites

Use astrona, kubectl, kind, Python 3 and Podman. A kubeconfig identifies the cluster and credentials that kubectl, the Kubernetes command-line tool, uses.

Select the private kubeconfig of this environment before every command:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-051-lab-010-02-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-051-lab-010-02-01" || exit 1
```
