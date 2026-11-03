---
draft: true
exam_objectives:
- Configuring Alerting rules
---
# Alert Expressions, Pending State And Stable Labels

This module explains how Prometheus turns a query result into an alert instance, how that instance moves from pending to firing, which labels and annotations it carries, and how a recording rule can feed an alert.

## Learning Goals

- Explain when an expression creates an alert instance.
- Distinguish inactive, pending and firing states.
- Relate the `for` duration, label stability and missing inputs.
- Separate alert labels from explanatory annotations and use templates in annotations.
- Write a recording rule with a stable name and use it inside an alert.

## Before You Start

The playground for this module is a private kind cluster with an instrumented probe, a traffic generator and Prometheus. The rule file is a ConfigMap that starts empty. Nothing in the reading text changes it.

## Reading Order

1. Alert Rule Anatomy And Pending State
2. Labels, Annotations And Templates
3. Recording Rules
4. Guided Practice
5. Summary

<!-- astrona:playground -->
