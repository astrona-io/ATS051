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

## Common pitfalls

> [!WARNING]
> Returned series activate alert instances even when a bool result is zero. Volatile labels can reset continuity, and firing state does not establish notification delivery.
