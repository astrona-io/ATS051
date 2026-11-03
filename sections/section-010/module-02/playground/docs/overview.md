---
draft: true
exam_objectives:
- Dashboarding basics
---
# Playground

This private kind cluster holds a `probe` Deployment that exposes counters, a gauge and a histogram, a `traffic` Deployment that sends it requests, and a Prometheus server that scrapes the probe every two seconds. About one request in ten fails with status 500.

Select the cluster before you start:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-051-playground-010-02)"
test "$(kubectl config current-context)" = "kind-astro-ats-051-playground-010-02" || exit 1
```

Run the commands of each reading page in this cluster. Nothing here is graded.
