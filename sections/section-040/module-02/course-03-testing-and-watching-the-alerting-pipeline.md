---
draft: true
exam_objectives:
- Alerting basics (when, what, and why)
---
# Testing And Watching The Alerting Pipeline

An alert that never fires looks the same as a healthy system. To trust a quiet pager, you need evidence that each stage of the pipeline works: the expression returns data, the rule is evaluated without errors, Prometheus reaches Alertmanager and Alertmanager delivers the notification. This part shows how to test each stage and how to alert on the pipeline itself.

## The stages

1. **Scrape.** Prometheus collects the metrics. The metric `up` is 1 for each target that was scraped successfully and 0 otherwise.
2. **Evaluation.** The rule group is evaluated at its interval. The result is an alert in the `inactive`, `pending` or `firing` state.
3. **Notification.** Prometheus sends firing alerts to Alertmanager on the address in its `alerting` configuration.
4. **Routing and delivery.** Alertmanager groups, routes and sends the alert to a receiver such as a webhook, email or paging service.

A failure at any stage produces the same visible result for the receiver: nothing arrives.

## Test rules before deployment

`promtool` is the command-line tool shipped with Prometheus. It checks rule files and runs unit tests.

```sh
promtool check rules rules.yaml
promtool test rules tests.yaml
```

`check rules` verifies the syntax and the expression. `test rules` runs a test file that supplies synthetic time series, advances the evaluation time and asserts which alerts exist at stated times. A test can show that the burn-rate rule stays silent for a short blip and fires for a sustained fault. Tests use `input_series`, `eval_time` and `alert_rule_test`. They need no running Prometheus.

## Watch rule health at runtime

Prometheus exposes the state of every rule through its HTTP API at `/api/v1/rules`. Read the `health` field, which is `ok` or `err`, and the `lastError` text. Metrics also describe evaluation, for example `prometheus_rule_evaluation_failures_total`, which counts failed evaluations, and `prometheus_rule_group_last_duration_seconds`, which shows how long the last evaluation of a group took. An alert on a growing failure counter detects broken rules.

The built-in series `ALERTS` records every pending and firing alert as a time series with the label `alertstate`. Querying `ALERTS{alertname="ErrorBudgetFastBurn"}` shows when an alert was active in the past, which is useful after an incident.

## Watch the connection to Alertmanager

Prometheus counts notification outcomes. Two useful counters are `prometheus_notifications_errors_total`, for failed sends to Alertmanager, and `prometheus_notifications_dropped_total`, for alerts dropped before sending. A rising value means alerts are generated but not delivered. The metric `prometheus_notifications_alertmanagers_discovered` shows how many Alertmanagers Prometheus knows. A value of zero means no notification can be sent.

Alertmanager has its own metrics. The counter `alertmanager_notifications_failed_total` counts failed deliveries per integration, such as `webhook` or `email`. A rising value means the receiver is unreachable or rejects the message.

## The Watchdog alert

A Watchdog is an alerting rule that always fires:

```yaml
- alert: Watchdog
  expr: vector(1)
  labels:
    severity: none
  annotations:
    summary: Always firing, proves the alerting pipeline works
```

`vector(1)` returns a single element with the value 1 on every evaluation, so the condition is always true. Alertmanager routes this alert to a dedicated receiver that expects a steady stream. An external dead man's switch service, which sends its own alert if no message arrives for some time, then detects any break in the chain: Prometheus down, rule evaluation stopped, connection broken or Alertmanager unable to deliver.

A Watchdog proves the pipeline end to end only if the alert travels the whole path, including delivery to a receiver outside the cluster.

## Detect missing targets

A threshold alert is silent when its metric disappears. To detect a target that is not scraped, use a rule on `up` or on the absence of a series:

```yaml
- alert: ProbeDown
  expr: absent(up{job="probe"} == 1)
  for: 10s
```

`absent()` returns a one-element vector with value 1 when its argument returns no series. Here the inner expression returns the successful scrapes of job `probe`. If there is none, `absent()` fires. If a successful scrape exists, the result is empty and the alert stays inactive.

## Try it in the playground

Send a test alert directly to Alertmanager or read what Prometheus holds. In the playground, read the active alerts from Prometheus:

<!-- astrona:playground:renew -->

```sh
export KUBECONFIG="$(astrona kubeconfig ats-051-playground-040-02)"
kubectl -n starfleet exec shuttle -- python -c "import urllib.request; print(urllib.request.urlopen('http://prometheus.starfleet.svc:9090/api/v1/alerts').read().decode())"
```

The response lists each active alert with its labels, annotations and state. An alert in `pending` has not yet finished its `for` duration.

## Maintenance and silences

Planned maintenance would normally trigger alerts for work that is expected. Use a silence with matchers that cover only the affected service and an end time. Do not disable the rule, and do not leave a silence without an end. After maintenance, check that the silence expired and that the rule is still evaluated.

## Common pitfalls

> [!WARNING]
> An alert that has never been triggered in a test has not been shown to work. Test both the firing and the silent case.

> [!WARNING]
> A Watchdog that only reaches a local receiver does not prove delivery outside the cluster.

> [!WARNING]
> `absent()` on a metric with a label filter fires if the labelled series is missing, even if other series of the metric exist.

> [!WARNING]
> Alertmanager can be healthy while the receiver rejects messages. Watch the delivery failure counter.
