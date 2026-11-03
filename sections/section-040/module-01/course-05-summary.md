---
draft: true
exam_objectives:
- Alerting basics (when, what, and why)
---
# Summary

- An alert is actionable when the receiver knows who is affected, how bad it is, who owns it and what to do next. The last item is usually a runbook linked in an annotation.
- Symptoms describe what callers observe, such as failed requests or slow responses. Causes describe internal states, such as CPU use or queue length. Page on symptoms and keep causes for dashboards and diagnosis.
- A threshold does not decide urgency. Population, speed of change and reversibility do.
- The `severity` label states the response: `page` interrupts a person, `ticket` waits for working hours and `none` is for the pipeline itself.
- Alert fatigue happens when notifications that need no action teach people to ignore alerts. The `for` duration, rate windows, grouping, inhibition and routing reduce noise.
- An SLI is a measured proportion of good events. An SLO is a target for the SLI over a window. The error budget is one minus the target.
- The burn rate is the observed error ratio divided by the error budget. A burn rate of 1 spends the budget exactly over the full window.
- Low traffic makes ratios volatile and missing scrapes make threshold alerts silent. Use longer windows, volume conditions and an `absent()` rule.
- An always-firing Watchdog alert proves that rules, Alertmanager and the receiver work together.

When the module is finished, remove the playground to free its resources.

<!-- astrona:playground:destroy -->
