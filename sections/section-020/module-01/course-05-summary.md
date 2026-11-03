---
draft: true
exam_objectives:
- Configuring Alerting rules
---
# Summary

An alert rule creates one instance for each label set its expression returns. An instance is pending while the condition has held for less than the `for` duration and firing after that. A single evaluation without a result removes a pending instance and resets its timer.

Labels identify and route an alert, so a label that changes value creates a new instance every time. Annotations describe it and are expanded as templates with `$labels` and `$value`. Keep volatile numbers in annotations and ownership data in labels.

A recording rule stores the result of an expression as a new series. Apply `rate` before `sum`, name the series with `level:metric:operations`, and place the recording rule before the alert that reads it in the same group so both see the same evaluation cycle.

Firing is not delivery. Prometheus sends the instance to Alertmanager, and grouping, silences and inhibition decide what is notified.

<!-- astrona:playground:destroy -->
