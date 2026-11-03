---
draft: true
exam_objectives:
- Alerting basics (when, what, and why)
---
# Summary

- The burn rate is the error ratio divided by the error budget. The time to exhaustion is the SLO window divided by the burn rate.
- A burn-rate threshold comes from the budget you accept losing: `r = consumed * W / d`. The error-ratio threshold in the expression is `r * B`.
- A multi-window alert joins a long and a short window with `and`. The long window shows that the loss is significant and the short window shows that it still happens, so the alert resets quickly after a fix.
- Both windows use the same threshold and the same aggregation labels, or `and` returns nothing.
- A paging alert carries a `severity` label, a `summary` annotation and a `runbook_url` annotation.
- `promtool check rules` verifies syntax and `promtool test rules` checks alert behaviour on synthetic series without a running Prometheus.
- The pipeline has four stages: scrape, evaluation, notification and delivery. Metrics such as `up`, `prometheus_rule_evaluation_failures_total`, `prometheus_notifications_errors_total` and `alertmanager_notifications_failed_total` show each stage.
- A Watchdog alert with `vector(1)` always fires, so a missing notification shows that the pipeline is broken. `absent()` detects a metric that stopped appearing.

When the module is finished, remove the playground to free its resources.

<!-- astrona:playground:destroy -->
