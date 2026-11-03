---
draft: true
exam_objectives:
- Understand and Use Alertmanager
---
# Alertmanager Capstone Solution

Select the private kubeconfig of the lab first:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-051-lab-030-cap-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-051-lab-030-cap-01" || exit 1
```

## Plan the configuration

Three mechanisms work together. The route tree decides the receiver: an alert goes to the first matching child route, and to the root receiver when no child matches. The `group_by` list decides which alerts share one notification: alerts with equal values for `alertname` and `service` are sent together. The inhibition rule decides which alerts are muted: warnings are muted while a critical alert with the same `service` is firing.

The critical alerts for instances `a` and `b` have the same `alertname` and `service`, so they form one group and one notification. The warning for service `probe` is muted by the inhibition rule. The warning for service `other` has a different `service` value, so it is not muted and it uses the root receiver.

## Write the configuration

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
      - service
      group_wait: 0s
      group_interval: 2s
      repeat_interval: 1m
      routes:
      - matchers:
        - severity="critical"
        receiver: pager
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
    - name: pager
      webhook_configs:
      - url: http://probe:8080/hooks
        send_resolved: true
```

Apply it and restart Alertmanager:

```sh
kubectl apply -f configmap-alertmanager-config.yaml
kubectl -n starfleet rollout restart deployment/alertmanager
kubectl -n starfleet rollout status deployment/alertmanager --timeout=180s
```

## Check the result

Read the loaded configuration and the alerts from the API:

```sh
kubectl -n starfleet exec shuttle -- python -c "import urllib.request; print(urllib.request.urlopen('http://alertmanager:9093/api/v2/status').read().decode())"
kubectl -n starfleet exec shuttle -- python -c "import urllib.request; print(urllib.request.urlopen('http://alertmanager:9093/api/v2/alerts').read().decode())"
```

The status shows the route tree, the `pager` receiver and the `inhibit_rules` block. Sent notifications appear at `http://probe:8080/hooks`, each with its `receiver` and `groupLabels`.

## Common pitfalls

> [!WARNING]
> A child route without `matchers` matches every alert. A `continue: true` setting would send an alert to the next matching route as well, which this task does not need. `group_by` must list `service`, or the grouping does not match the expected notification.
