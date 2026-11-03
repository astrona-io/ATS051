---
draft: true
exam_objectives:
- Understand and Use Alertmanager
---
# Inhibit Warnings While A Critical Alert Fires Solution

Select the private kubeconfig of the lab first:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-051-lab-030-02-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-051-lab-030-02-01" || exit 1
```

## Write the inhibition rule

An inhibition rule has a source and a target. While an alert that matches `source_matchers` is firing, Alertmanager mutes every alert that matches `target_matchers`. The `equal` list names labels that must have the same value on the source and on the target. Here `equal` holds `service`, so a critical alert for `probe` mutes only warnings for `probe`.

Save this as `configmap-alertmanager-config.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: alertmanager-config
  namespace: starfleet
data:
  alertmanager.yaml: |
    global:
      resolve_timeout: 1m
    route:
      receiver: default
      group_by:
      - alertname
      group_wait: 0s
      group_interval: 2s
      repeat_interval: 1m
    inhibit_rules:
    - source_matchers:
      - severity="critical"
      target_matchers:
      - severity="warning"
      equal:
      - service
    receivers:
    - name: default
      webhook_configs:
      - url: http://probe:8080/hooks
        send_resolved: true
```

Apply it and restart Alertmanager so that it loads the file:

```sh
kubectl apply -f configmap-alertmanager-config.yaml
kubectl -n starfleet rollout restart deployment/alertmanager
kubectl -n starfleet rollout status deployment/alertmanager --timeout=180s
```

## Check the result

Read the loaded configuration from the API:

```sh
kubectl -n starfleet exec shuttle -- python -c "import urllib.request; print(urllib.request.urlopen('http://alertmanager:9093/api/v2/status').read().decode())"
```

The `config.original` field contains the `inhibit_rules` block. When a critical and a warning alert for the same service are active, the API shows the warning with the state `suppressed` and a non-empty `inhibitedBy` list.

## Common pitfalls

> [!WARNING]
> Without `equal`, one critical alert mutes every warning of every service. A label name in `equal` that the alerts do not carry makes the rule match too much or nothing. An inhibited alert is still received by Alertmanager: it only skips the notification.
