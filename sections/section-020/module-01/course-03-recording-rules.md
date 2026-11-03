---
draft: true
exam_objectives:
- Configuring Alerting rules
---
# Recording Rules

A recording rule evaluates a PromQL expression on a schedule and stores the result as a new time series. Later queries, dashboards and alerting rules read the stored series instead of recomputing the expression. The rule does not change the source data. It adds derived data to the same time series database.

## What A Recording Rule Looks Like

A recording rule has a `record` field with the name of the new series, an `expr` field with the query, and optional `labels`.

```yaml
groups:
- name: lab
  interval: 2s
  rules:
  - record: service:lab_requests:rate10s
    expr: sum by (service, status) (rate(lab_requests_total[10s]))
    labels:
      source: recording
```

At each evaluation the result vector is written as samples of the series `service:lab_requests:rate10s`. Every returned element becomes one series with the labels of that element. Labels listed under `labels` are added to every series, and they replace a label of the same name from the expression.

## Why Use One

There are three reasons.

- Cost. An expensive expression, such as a rate over a long window aggregated over many series, runs once per interval instead of once per dashboard refresh or per alert evaluation.
- Reuse. Several alerts and panels can share one definition, so a change to the calculation happens in one place.
- Stability. A stored series has a fixed set of labels, so a consumer is protected from changes in how the raw metric is labelled.

The cost is storage and a delay. A recording rule adds series to the database, and consumers see the value as of the last evaluation, not the value at query time.

## Naming Convention

The common convention is `level:metric:operations`.

- `level` names the labels the series still has, such as `service` or `job`.
- `metric` is the source metric name, without `_total` when a rate removes the counter meaning.
- `operations` lists the functions applied, newest first, such as `rate10s` or `sum`.

The name `service:lab_requests:rate10s` therefore says: aggregated to `service`, built from `lab_requests`, a ten second rate. The colon is legal in metric names and is reserved by convention for recording rules, so instrumented applications should not use it.

## Order Of Operations

The rule expression should apply `rate` to the raw counter first and aggregate afterwards. The `rate` function needs the counter samples of each series to detect resets. A `sum` of counters before the rate merges series, and a reset in one series makes the summed value drop in a way that looks like a restart of the whole total. The correct form is `sum(rate(metric[window]))`.

The same rule explains why a recorded rate is safe to sum again. Summing recorded rates adds per-second values, which is valid. Averaging recorded ratios across groups is not valid unless the groups have equal traffic, so record the numerator and the denominator separately and divide the sums.

## Rules Inside One Group Run In Order

All rules of a group are evaluated sequentially in the order they appear in the file, at the group interval. A rule can therefore read a series written by an earlier rule of the same group, and it sees the sample from the current cycle.

Different groups are evaluated independently and can run at the same time. An alert in one group that reads a series recorded in another group has no ordering guarantee and may see the previous cycle's value. To make a pair of rules consistent, put the recording rule first and the alert second in the same group.

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
    labels:
      severity: critical
```

## Window And Interval

A rate over a window needs at least two samples inside the window. The recorded value is a ten second rate computed every two seconds, so consecutive recorded samples overlap and are not independent. The window should be several times longer than the scrape interval, and the group interval should not be shorter than the scrape interval because it would only recompute the same data.

## Missing Data

A recording rule produces no sample when its expression returns an empty result. The recorded series then has a gap, and queries on it will return nothing once the gap exceeds the lookback of five minutes by default. An alert that reads that series gets no instance, which is indistinguishable from a healthy state. Cover this with a separate alert on `absent` or on target health.

When a rule produces output with the same labels as another series, the writes conflict. Two recording rules with the same name and overlapping labels produce duplicate samples, and one of them is rejected. Keep each recorded name owned by one rule, or separate them with a distinguishing label.

## Checking A Recording Rule

The rules API lists each rule with `type` set to `recording`, a `health` field, the last error text and the evaluation time. A healthy rule with no output is possible, so also query the recorded series by name. If the series returns data, the rule produced samples. If the series is empty while the source metric has data, check the rule order, the group interval and the label names in the expression.

## Common pitfalls

> [!WARNING]
> Summing counters before applying rate breaks reset handling. A rule in another group may read the previous cycle's value. An empty expression result stores nothing and shows up as a missing series, not as an error.
