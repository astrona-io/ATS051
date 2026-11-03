---
draft: true
exam_objectives:
- Understand and Use Alertmanager
---
# Routing, Grouping And Silences

Prometheus evaluates alerting rules and sends the resulting alert instances to Alertmanager. Alertmanager does not scrape anything and does not evaluate PromQL. It receives alerts, decides which receiver each alert belongs to, combines related alerts into notification groups, delays and repeats notifications on timers, and drops notifications that a silence covers. This module follows one alert through those stages in order.

## Learning Goals

- Match an alert to a receiver by walking the routing tree, including the effect of `continue`.
- Choose `group_by` labels and explain what `group_wait`, `group_interval` and `repeat_interval` each delay.
- Create a silence from matchers and a time window, and explain what a silence does and does not change.
- Read the Alertmanager API to see which alerts are active, suppressed or silenced.

## Before You Start

The playground for this module is a kind cluster. A kind cluster is a Kubernetes cluster that runs inside containers on your machine. It contains an instrumented `probe` service, a traffic generator that makes one request in ten fail, Prometheus, and an Alertmanager that posts notifications to a webhook on the `probe` service. The webhook endpoint stores every body it receives, so you can read back what Alertmanager sent.

The hands-on steps only read state or submit fixture alerts and silences directly to Alertmanager. They do not change the application.

## Reading Order

1. Routing Trees And Matchers
2. Grouping And Notification Timing
3. Silences
4. Guided Practice
5. Summary

<!-- astrona:playground -->
