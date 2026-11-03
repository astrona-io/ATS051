---
draft: true
exam_objectives:
- Configuring Alerting rules
---
# Labels, Annotations And Templates

An alerting rule produces two kinds of metadata for every alert instance: labels and annotations. They look alike in YAML, but Prometheus and Alertmanager treat them differently. Labels identify the alert and decide where it goes. Annotations carry text for the person who receives it. Choosing the wrong place for a piece of information is one of the most common causes of broken routing and of alerts that restart their pending period.

## Where Alert Labels Come From

The label set of an alert instance is built from three sources, in this order.

1. The labels of the series returned by the expression. If the expression is `sum by (service) (rate(lab_requests_total{status="500"}[10s])) > 0`, each returned series carries only the `service` label, because the aggregation removed every other label. Labels that the expression drops are not available to the alert.
2. The `alertname` label, which Prometheus adds and sets to the rule name.
3. The labels written under `labels:` in the rule. If a configured label has the same name as a label from the expression, the configured value replaces it.

The metric name is never part of the alert labels. A comparison filter keeps the labels of the left side, so an expression that ends in a comparison keeps the same label set as the value expression before the comparison.

```yaml
- alert: ProbeErrorsByService
  expr: sum by (service) (rate(lab_requests_total{status="500"}[10s])) > 0
  for: 4s
  labels:
    severity: warning
    team: starfleet
```

The alert instances produced by this rule carry `alertname`, `service`, `severity` and `team`. Two instances exist when two services return a result, and each one has its own pending timer.

## Labels Identify, Annotations Describe

The full label set is the identity of an alert instance. Prometheus keeps pending state per identity, and Alertmanager groups, silences and inhibits by label values. If a label value changes, the old instance disappears and a new instance starts at the beginning of its pending period.

Annotations are not part of the identity. They are attached to the instance and sent with it. Their value can change on every evaluation without creating a new instance. This is why the current numeric value belongs in an annotation. A label such as `value: "0.12"` would create a new instance every time the ratio moved, and the alert would never stay pending long enough to fire.

Typical label names are `severity`, `team`, `service` and `environment`, because routing trees and silences match on them. Typical annotation names are `summary`, `description` and `runbook_url`, because notification templates print them.

## Templating

Both label values and annotation values are Go templates. Prometheus expands them each time the alert is evaluated. Three variables are available.

| Variable | Content |
| --- | --- |
| `$labels` | The labels of the instance, read as `$labels.service` or `index $labels "service"` |
| `$value` | The numeric value of the sample the expression returned for this instance |
| `$externalLabels` | The `external_labels` from the Prometheus configuration |

`$value` is the value of the expression after the comparison filter. For an expression ending in `> 0.05`, the value is the ratio itself, not a boolean. When the expression uses the `bool` modifier, the value is `1`, which makes `$value` useless for explaining the size of the problem.

```yaml
annotations:
  summary: "High error ratio for {{ $labels.service }}"
  description: "Error ratio is {{ $value | humanizePercentage }} over 10 seconds"
```

## Template Functions

Prometheus adds formatting functions to the standard Go template functions.

- `humanize` formats a number with metric prefixes such as k or M.
- `humanizePercentage` formats a ratio of 0.12 as a percentage.
- `humanizeDuration` formats a number of seconds as a readable duration.
- `printf` formats a value with a format string, for example `{{ printf "%.2f" $value }}`.
- `query` runs an instant query and returns the result vector, so a template can read a second metric.

Functions are chained with a pipe, and the value on the left becomes the last argument of the function on the right. `$value` is a float, so `humanizePercentage` accepts it directly.

## Errors In Templates

A template with a syntax error makes the rule fail to load. A template that is valid but refers to a label the instance does not have expands to an empty string for `$labels.name`. The alert still fires, but the text is incomplete. An annotation that still shows the text `{{ $value }}` in the alert means the text was not expanded, which usually means it was quoted so that a different system printed it literally, or that it was read from the rule file instead of from the alerts API.

When the rule file is written inside a YAML string, the quote characters and braces must survive both YAML and Go template parsing. Use a block scalar with `|` for the file contents and single quotes around annotation values that contain double quotes.

## Keeping Identity Stable

Follow these rules when you choose labels.

- Put ownership and routing data in labels: team, service, environment, severity.
- Put anything that changes with the measurement in annotations: the value, a duration, a count.
- Do not copy a high-cardinality label into the alert only to display it. Each distinct value is a separate instance with its own notification.
- Aggregate away labels that you do not need before the comparison, so one problem produces one instance.

## Severity As A Label Convention

Prometheus does not interpret `severity`. It is only a label that your routing tree and your team agree to use. The names `warning` and `critical` are common, but any consistent set works. Routing and inhibition rules then match on that label, so a rule that omits it falls into the default route and may reach the wrong receiver or none at all.

## Reading Labels And Annotations From The API

The alerts API returns each active alert with its `labels`, its `annotations`, its `state` and its `value`. The annotations in that response are already expanded, so it shows what a receiver would see. The rules API returns the unexpanded templates, because they belong to the rule rather than to an instance. Comparing the two is a quick way to check whether a template did what you intended.

Prometheus also exposes active alerts as time series named `ALERTS`. Each series has the alert labels plus `alertstate`, which is `pending` or `firing`, and its value is always 1. Annotations are not part of the `ALERTS` series. A companion series `ALERTS_FOR_STATE` stores the time the alert became active so that pending state can survive a restart.

## Common pitfalls

> [!WARNING]
> A label that holds a changing number resets pending state on every evaluation. An aggregation that drops a label also removes it from the alert. Template text that is quoted wrongly is stored literally and shows up unexpanded.
