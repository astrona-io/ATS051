---
draft: true
exam_objectives:
- Configuring Alerting rules
---
# Rule Groups, Evaluation And Validation

This module explains how Prometheus loads rule files, how rule groups are scheduled and evaluated, how to check a rule before it is loaded, and how to find the reason when a rule loads but does not behave as intended.

## Learning Goals

- Describe a rule group, its interval and the order of rules inside it.
- Explain how rule files are loaded and reloaded.
- Check rule syntax with promtool and test rule behaviour with input series.
- Read rule health, last error and evaluation time from the rules API.
- Separate a healthy rule that returns nothing from a failing rule.

## Before You Start

The playground for this module is a private kind cluster with an instrumented probe, a traffic generator and Prometheus. The rule file is a ConfigMap that starts empty. Nothing in the reading text changes it.

## Reading Order

1. Rule Groups And Evaluation
2. Validating Rules With promtool
3. Troubleshooting Rules
4. Summary

<!-- astrona:playground -->
