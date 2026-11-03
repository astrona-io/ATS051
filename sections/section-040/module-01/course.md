---
draft: true
exam_objectives:
- Alerting basics (when, what, and why)
---
# Actionable Alerts, Symptoms And Error-Budget Reasoning

This module explains when to alert, what to alert on and why. It starts from the person who receives the notification and works back to the rule. You will separate symptoms from causes, choose between a page, a ticket and a dashboard, and connect alert thresholds to a service level objective and its error budget.

The playground for this module is a small kind cluster with one instrumented service named `probe`, a traffic generator that makes every tenth request fail, and Prometheus with an empty rule group. It is used in the guided practice at the end of the module.

## Learning Goals

- Define an alert's owner, impact and expected action.
- Distinguish urgent symptoms from diagnostic causes.
- Choose between a page, a ticket and a dashboard signal.
- Compute an error budget and a burn rate from an SLO and an error ratio.
- Evaluate low traffic, maintenance and monitoring failures.

## Before You Start

You need basic PromQL knowledge: selecting a counter, `rate()` and `sum()`. The lab uses a kind cluster, which is a Kubernetes cluster that runs inside containers on your machine.

## Reading Order

1. Actionable Alerts And Symptoms
2. Paging, Tickets And Alert Fatigue
3. SLIs, SLOs And Error Budgets
4. Guided Practice
5. Summary

<!-- astrona:playground -->
