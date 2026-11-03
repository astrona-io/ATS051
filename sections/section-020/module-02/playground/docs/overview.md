---
draft: true
exam_objectives:
- Configuring Alerting rules
---
# Playground

This private kind cluster holds a `probe` Deployment, a `traffic` Deployment that sends it requests (about one in ten fails with status 500) and a Prometheus server that scrapes the probe every two seconds and evaluates rules every two seconds. The rule file starts empty.

Select the cluster before you start:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-051-playground-020-02)"
test "$(kubectl config current-context)" = "kind-astro-ats-051-playground-020-02" || exit 1
```

Run the commands of each reading page in this cluster. Nothing here is graded.
