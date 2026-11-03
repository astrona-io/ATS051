---
draft: true
exam_objectives:
- Understand and Use Alertmanager
---
# Summary

Alertmanager receives alert instances from Prometheus and decides who is notified, how the alerts are combined and when the message leaves. It does not scrape metrics and does not evaluate PromQL. Everything it does is based on the labels the alert carries when it arrives.

Routing walks a tree from the root. The first matching child wins and the search continues inside it, unless `continue: true` lets later siblings match as well. An alert that no child matches goes to the root receiver. A route cannot match a label that the rule expression removed, so the label contract belongs in the rule.

Grouping builds one notification from all alerts that share the values of the `group_by` labels. The `group_wait` timer delays the first message of a group, `group_interval` spaces later messages about changes, and `repeat_interval` repeats an unchanged group. These timers start after the alert reaches Alertmanager and are separate from the `for` duration, which Prometheus applies before it sends the alert.

A silence is a set of matchers with a start time, an end time, an author and a comment. A matching alert is marked suppressed and its notification is dropped, but the alert still fires and Prometheus keeps evaluating it. A narrow silence with a short window is safe. A broad silence hides unrelated failures.

The Alertmanager API shows the result of each stage. The alert list shows the state and the silences that suppress an alert, and the webhook receiver shows which receiver got which grouped alerts.

<!-- astrona:playground:destroy -->
