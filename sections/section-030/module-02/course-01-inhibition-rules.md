---
draft: true
exam_objectives:
- Understand and Use Alertmanager
---
# Inhibition Rules

When a whole service is down, many alerts fire at once: the availability alert, the latency alert, the error alert. The responder needs the first one. Inhibition lets Alertmanager suppress the notifications for alerts that are consequences of a more important alert that is already firing. The alerts are still received and still firing. Only their notifications are held back.

## The Parts Of A Rule

Inhibition rules are listed under `inhibit_rules` at the top level of the configuration. Each rule has four parts.

- `source_matchers` select the alerts that cause suppression. These are the source alerts.
- `target_matchers` select the alerts that can be suppressed. These are the target alerts.
- `equal` is a list of label names. A target is suppressed only when a source alert exists and has the same value as the target for every label in this list.
- The matcher syntax is the one used in routes: `=`, `!=`, `=~` and `!~`.

```yaml
inhibit_rules:
- source_matchers:
  - severity="critical"
  target_matchers:
  - severity="warning"
  equal:
  - service
```

This rule says that while an alert with severity `critical` is active, every alert with severity `warning` that has the same `service` value is suppressed. A warning for another service is not touched.

## How Alertmanager Evaluates It

For each alert, Alertmanager checks every inhibition rule. If the alert matches the rule's target matchers, Alertmanager looks for an active source alert that matches the source matchers and has equal values for all `equal` labels. If such an alert exists, the target is marked inhibited. In the API the alert's `status.state` is `suppressed` and the `inhibitedBy` list holds the fingerprint of each source alert.

Inhibition is checked when the notification is built, in the same stage as silences. A suppressed target is removed from its group. When the source alert resolves, the target becomes active again and notifies on the normal timers if it still fires.

## The equal List

Without `equal`, a critical alert anywhere in the system would suppress every warning everywhere. The `equal` list narrows the relationship to alerts that describe the same thing. Common choices are `service`, `cluster`, `namespace` or `instance`.

A label that is missing on both alerts counts as equal, because both values are the empty string. If neither alert has a `service` label, the rule applies to them. This helps when you omit labels on purpose and surprises you when a rule forgot to set one. A label missing on only one side does not match.

## An Alert Cannot Inhibit Itself

If an alert matches both the source and the target matchers of one rule, it does not inhibit itself. Alertmanager skips an alert as its own source. Write the matchers so that sources and targets are different severities or different alert names.

## Chains And Dependencies

Alertmanager does not follow chains. If alert A inhibits B and B inhibits C, then C is inhibited only if A or B is active and matches. A source alert that is itself inhibited still counts as a source while it is firing. Design rules with a small number of levels, such as critical over warning, or a cluster-wide outage over the alerts of the services inside it.

## Silences And Inhibition Compared

| | Silence | Inhibition |
| --- | --- | --- |
| Created by | A person or tool through the API | The configuration file |
| Condition | A time window and matchers | An active source alert |
| Ends | At `endsAt` or when expired | When the source alert resolves |
| Visible as | `silencedBy` | `inhibitedBy` |

Use a silence for a planned or known event. Use inhibition for a dependency that always holds.

## Testing In The Playground

The playground Alertmanager reads the `alertmanager.yaml` key of the `alertmanager-config` ConfigMap. Save the rule above in a file, add it under `inhibit_rules` in that ConfigMap, then restart the Deployment so the file is read again.

<!-- astrona:playground:renew -->

```sh
kubectl -n starfleet edit configmap alertmanager-config
kubectl -n starfleet rollout restart deployment alertmanager
kubectl -n starfleet rollout status deployment alertmanager
```

Alertmanager can also reload the file without a restart through its reload endpoint, but a ConfigMap update takes time to reach the pod, so a restart is more predictable here.

Submit three alerts to `/api/v2/alerts`: a critical alert for service `probe`, a warning for service `probe` and a warning for service `other`. Then read `/api/v2/alerts`. The warning for `probe` has `inhibitedBy` set and the state `suppressed`. The other two are `active`.

## Reading The Result

After the three alerts are submitted, compare the alert list with the webhook bodies stored on the `probe` service. The stored bodies list the alerts that were actually sent. The suppressed warning for `probe` is missing from every body, while the alert list still contains it. This difference between the two views is the evidence that the alert was inhibited and not resolved.

## Common Mistakes

- Omitting `equal`, which makes the rule global.
- Using `equal` with a label the alerts do not carry.
- Matching the same severity on both sides.
- Confusing inhibition with a route. An inhibited alert is still grouped and still counts as active.
- Testing with a source alert that has already expired. The source must be firing at the time the target is evaluated.

## Common pitfalls

> [!WARNING]
> An overly broad rule hides real incidents. Always keep `equal` and name the labels that define the shared failure. Do not rely on inhibition to replace a good rule expression, because the suppressed alert still exists and still appears in the alert list.
