---
draft: true
exam_objectives:
- Understand and Use Alertmanager
---
# Understand and Use Alertmanager

This section covers how Alertmanager turns the alerts that Prometheus sends into notifications. It has two modules. The first follows an alert through routing, grouping and silences. The second covers inhibition, receivers, high-availability clustering and the tools used to operate Alertmanager.

Each module has a playground, a kind cluster with Prometheus, a probe service and Alertmanager, and one or more graded labs placed after the lesson they practise. The section ends with a capstone lab and a knowledge check.

## Learning Outcomes

- Trace alerts through the Alertmanager routing tree, including the effect of `continue`.
- Choose `group_by` labels and distinguish the grouping timers from the rule's `for` duration.
- Create a silence and explain that it suppresses notifications without changing the alert.
- Write an inhibition rule with source matchers, target matchers and an `equal` list.
- Configure receivers and explain how an Alertmanager cluster deduplicates notifications and where that stops.
- Read alert state and validate configuration with the v2 API and `amtool`.
