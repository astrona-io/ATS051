---
draft: true
exam_objectives:
- Alerting basics (when, what, and why)
---
# Burn Rates And Alert Quality

This module turns an error budget into alert rules. You will compute burn-rate thresholds from an SLO, combine a long and a short window so an alert is both reliable and quick to resolve, and learn how to test that the whole alerting pipeline works: rule evaluation, the Alertmanager connection and notification delivery.

The playground has one instrumented `probe` service, a traffic generator that makes every tenth request fail, and Prometheus with a rule group that starts empty. You fill it while you read and in the lab.

## Learning Goals

- Compute a burn-rate threshold from an SLO target and a budget fraction.
- Write a multi-window alert joined with `and`.
- Explain why the short window makes alerts reset faster.
- Add severity and runbook metadata to a paging alert.
- Test rules with `promtool` and prove delivery with a Watchdog alert.

## Before You Start

You need to know what an error budget and a burn rate are, and basic alerting-rule syntax: `alert`, `expr`, `for`, `labels` and `annotations`.

## Reading Order

1. Burn Rate Math
2. Multi-Window Burn Rate Alerts
3. Testing And Watching The Alerting Pipeline
4. Summary

<!-- astrona:playground -->
