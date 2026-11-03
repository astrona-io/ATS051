---
draft: true
exam_objectives:
- Configuring Alerting rules
---
# Alert Expressions, Pending State And Stable Labels

An alerting rule evaluates a PromQL expression and maintains alert state for the returned series. It should represent a condition requiring an operational response rather than merely mirror every unusual metric. Understanding presence, persistence and identity helps explain why a rule is pending, firing or unexpectedly quiet.

## Expression Results Create Instances

A filtering comparison such as error_ratio > 0.05 returns the series satisfying the threshold. Each resulting label set identifies an alert instance. An empty result does not create an instance. A returned sample whose value is zero can still be present, so using a bool comparison without an additional filter can produce behavior different from the intended condition.

The expression needs a defined population and unit. A ratio should use compatible numerator and denominator series, and a rate should handle counters before aggregation. Missing data may remove results rather than produce a high or low value. Design coverage or absence checks separately where that state requires attention.

## Pending And Firing Are Different

An alert without a persistence requirement can fire when its expression produces the condition. With for configured, an instance remains pending until the condition has continued for the specified duration. If the expression stops returning that instance, continuity can reset. The duration is not the scrape interval or the notification repeat interval.

Persistence can reduce noise from brief fluctuations, but an excessively long duration can delay response to serious user impact. A long rate window and a long for duration can combine to hide fast deterioration. Choose both according to the operational objective and expected evidence rather than apply a universal default.

## Labels Define Continuity And Routing

The rule's result labels and configured labels identify alert instances and support routing. A changing value placed into an identifying label can create a new instance on each evaluation. That can prevent the same instance from remaining pending long enough to fire and can generate unnecessary notification churn.

Annotations provide explanatory text such as the observed value, affected operation and response context. They can change without redefining the alert identity in the same way. Preserve useful ownership and environment labels, while keeping volatile numerical detail in explanatory annotations where appropriate.

## Collection And Evaluation Can Fail Separately

A failed scrape can produce collection evidence such as up equal to zero, while a missing application series may make another condition disappear. Rule evaluation errors or delays can also interrupt the path. A quiet application alert therefore does not prove healthy collection or successful rule evaluation.

Recording rules used by an alert introduce another stage and schedule. Confirm that the recorded series has the intended labels and remains current. A dashboard querying a different expression or time window may show a symptom that the actual rule does not evaluate.

## Firing Does Not Prove Delivery

Prometheus sends active alerts to the configured Alertmanager path. Grouping, silences, inhibition and receiver failures can affect notifications downstream. A rule can be firing while no message is delivered. Investigate rule state first, then follow notification routing and suppression evidence rather than weaken the original expression to compensate for a delivery problem.

Useful rules describe an actionable symptom, ownership and response expectation. Review threshold, traffic volume, persistence and missing-data behavior together so an alert is meaningful under normal operation, failure and maintenance.

## The Rule Fields

An alerting rule has a fixed set of fields.

- `alert` is the name. It becomes the `alertname` label of every instance.
- `expr` is the PromQL expression. Series it returns are the active alert instances.
- `for` is the optional persistence time. Without it, an instance is firing as soon as the expression returns it.
- `keep_firing_for` is an optional time that keeps an instance in the firing state after the expression stops returning it. It reduces flapping when a condition briefly disappears.
- `labels` adds or overrides labels on every instance.
- `annotations` adds descriptive text on every instance.

The expression is evaluated at every tick of the rule group interval. The tick is the only moment when state changes. If the interval is two seconds and `for` is four seconds, the instance needs the condition at the first tick and still at the tick four seconds later.

## The State Machine

Each instance moves through states at evaluation ticks.

1. Inactive. The expression does not return the instance. No alert exists for it.
2. Pending. The expression returns the instance, and the time since `activeAt` is shorter than `for`. Prometheus does not send a pending instance to Alertmanager.
3. Firing. The instance has been returned continuously for at least `for`. Prometheus sends it to Alertmanager and keeps resending it at each evaluation.
4. Back to inactive. If the expression stops returning the instance, a pending instance is dropped and its timer is lost. A firing instance is marked resolved and Prometheus tells Alertmanager the end time.

The key point is that the timer is reset by a single tick with no result. A flapping metric that crosses the threshold every few seconds never accumulates enough continuous time if `for` is longer than the shortest gap.

## How The Pieces Interact

Four durations interact and each is set in a different place.

- The scrape interval decides how often new samples arrive.
- The range window of `rate` decides how many seconds of samples feed each value.
- The group interval decides how often the expression is evaluated.
- The `for` duration decides how long the condition must hold.

Worst case detection time is roughly the time for the rate window to reflect the change, plus up to one group interval, plus `for`. A ten second window and a one hour `for` therefore delay a serious incident by more than an hour, even when the expression is correct.

## Checking State

The alerts API lists every instance that is pending or firing with its labels, annotations, state, `activeAt` time and value. The rules API lists every rule with its health. An alert that is not in the alerts API is inactive, which means the expression returned nothing at the last evaluation. Run the expression in the query API at the same time to see whether it returns data. If the query returns data but the alert is absent, check that the query was run against the same Prometheus and the same time window as the rule.

## Worked Reading Of One Rule

```yaml
- alert: ProbeErrorRatioHigh
  expr: sum(rate(lab_requests_total{status="500"}[10s])) / sum(rate(lab_requests_total[10s])) > 0.05
  for: 4s
  labels:
    severity: critical
```

Read the rule from the inside out. The inner `rate` calls turn each counter into a per-second value. Each `sum` removes all labels, so the division returns one element with an empty label set. The comparison keeps that element only when the ratio is above 0.05. The alert therefore has one instance with the labels `alertname` and `severity`. If the traffic stops completely, the denominator is empty, the division returns nothing, and the alert becomes inactive. That is why an alert on a ratio cannot report a service that no longer receives requests.

## Common pitfalls

> [!WARNING]
> Returned series activate alert instances even when a bool result is zero. Volatile labels can reset continuity, and firing state does not establish notification delivery.
