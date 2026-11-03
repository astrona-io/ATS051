---
draft: true
exam_objectives:
- Configuring Alerting rules
---
# Rule Groups And Evaluation

Prometheus does not evaluate rules one by one at arbitrary times. It loads rule files, divides their content into groups, and evaluates each group on its own timer. Understanding groups explains rule order, the delay between data and alert, and why some failures affect several rules at once.

## Rule Files And Groups

The main configuration lists rule files under `rule_files`. Each entry is a path or a glob pattern. Prometheus reads every matching file when it starts and when it reloads.

```yaml
rule_files:
  - /rules/*.yaml
```

A rule file contains a top-level `groups` list. A group has a `name`, an optional `interval`, and a list of `rules`. Alerting rules and recording rules can share a group.

```yaml
groups:
- name: lab
  interval: 2s
  rules:
  - record: service:lab_requests:rate10s
    expr: sum by (service, status) (rate(lab_requests_total[10s]))
  - alert: ProbeErrorRatioHigh
    expr: sum(service:lab_requests:rate10s{status="500"}) / sum(service:lab_requests:rate10s) > 0.05
    for: 4s
```

The group name must be unique inside its file. The same name in two different files creates two separate groups.

## The Evaluation Interval

If a group has no `interval`, it uses the global `evaluation_interval` from the main configuration, which defaults to one minute. A group with its own `interval` overrides the global value for that group only. A short interval makes alerts react sooner and creates more query load.

The interval is not related to the scrape interval. An evaluation reads the newest samples available at that moment. If the interval is shorter than the scrape interval, several evaluations in a row see identical data.

Prometheus spreads group start times with a deterministic offset based on the group, so groups with the same interval do not all start at the same instant.

## Order Inside A Group

A group evaluates its rules one after another, in file order, in one goroutine. Samples that a recording rule wrote are visible to the rules after it in the same cycle. Placing the consumer before the producer makes the consumer read the previous cycle.

Different groups run concurrently. There is no ordering between groups, so a rule must not depend on a series recorded in another group within the same cycle.

## What One Evaluation Does

For each rule in order, Prometheus runs these steps.

1. Evaluate the expression as an instant query at the evaluation time.
2. For a recording rule, write the resulting vector as new samples with the evaluation timestamp.
3. For an alerting rule, compare the returned label sets with the active instances. New label sets become pending or firing, existing ones update their value, and missing ones are resolved.
4. Record the evaluation time and any error on the rule.

A recording rule writes its samples after the query has finished. The expression never sees its own output in the same cycle.

## Slow Evaluations

If a group takes longer than its interval, Prometheus skips the evaluation ticks that were missed and counts them. The metric `prometheus_rule_group_iterations_missed_total` increases, and the alert state updates less often than configured. The `for` timer is based on timestamps, so a few missed cycles do not reset pending state, but they delay it.

Related metrics include `prometheus_rule_group_last_duration_seconds` for the last evaluation time of a group, `prometheus_rule_group_interval_seconds` for the configured interval, and `prometheus_rule_evaluation_failures_total` for expressions that returned an error.

## Group Limit

A group can set `limit`. It caps the number of alert instances an alerting rule may create, or the number of series a recording rule may write. A rule that exceeds the limit fails the evaluation with an error rather than writing a partial result. A value of zero means no limit.

## Loading And Reloading

Prometheus reads the rule files at startup. To load changed files without a restart, send it a reload. There are two ways.

- Send the SIGHUP signal to the process.
- Send an HTTP POST to `/-/reload`, which works only when the server runs with `--web.enable-lifecycle`.

A reload parses the main configuration and all rule files. If any file fails to parse, the reload is rejected as a whole and the previous rules stay active. The metric `prometheus_config_last_reload_successful` shows whether the last attempt worked. After a successful reload, groups whose content did not change keep their state, and changed groups are replaced.

When the rule file is a ConfigMap mounted into a pod, an update to the ConfigMap reaches the file after a delay, and Prometheus does not notice it by itself. Either send a reload after the file has changed or restart the Deployment, which reads the current file at start.

## State Across Restarts

Pending state would be lost at a restart, so Prometheus stores when each alert became active in the `ALERTS_FOR_STATE` series and restores it after a restart, using a grace period set by `--rules.alert.for-grace-period`. A restart can still delay a pending alert because evaluation is paused while Prometheus starts.

## Reading Group State From The API

The rules API groups its answer by file and group. For every group it reports the name, the file, the interval, the time of the last evaluation and its duration. For every rule it reports the name, the query, the type, the health and the last error. This is the view of what Prometheus actually loaded, which can differ from what you intended to load.

Compare three things when a rule behaves strangely: the file path in the API against the path you edited, the interval in the API against the one you wrote, and the order of the rules in the group against the order you expected.

## Common pitfalls

> [!WARNING]
> A consumer placed before its producer reads the previous cycle. A group longer than its interval misses ticks. A rejected reload keeps the old rules silently loaded, so always check the reload result.
