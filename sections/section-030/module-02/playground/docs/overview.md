---
draft: true
exam_objectives:
- Understand and Use Alertmanager
---
# Playground

This private kind cluster holds a `probe` Deployment that also records every webhook notification it receives (read them at `/hooks`), a `traffic` Deployment, a Prometheus server and an Alertmanager. Alertmanager reads its configuration from the ConfigMap `alertmanager-config` and sends every alert to the probe webhook.

Select the cluster before you start:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-051-playground-030-02)"
test "$(kubectl config current-context)" = "kind-astro-ats-051-playground-030-02" || exit 1
```

Run the commands of each reading page in this cluster. Nothing here is graded.
