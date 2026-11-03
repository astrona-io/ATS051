---
draft: true
exam_objectives:
- Dashboarding basics
---
# Histograms, Quantiles And Dashboard Variables

Latency panels are the hardest panels to get right. A histogram stores counts in buckets, and a quantile is an estimate that `histogram_quantile` calculates from those counts. This module explains how the estimate works, how far it can be wrong, how to aggregate it across replicas, and how a dashboard turns the same queries into variables and resolution settings.

## Learning Goals

- Read the `_bucket`, `_sum` and `_count` series of a histogram and explain the `le` label.
- Explain how `histogram_quantile` interpolates inside a bucket and why bucket bounds limit its accuracy.
- Aggregate histogram buckets with `sum by (le)` before calculating a quantile.
- Calculate a mean latency from the rates of `_sum` and `_count`.
- Explain why quantiles must never be averaged.
- Describe how a dashboard variable, `$__rate_interval`, min step and max data points relate to the Prometheus HTTP API.

## Before You Start

You need to know what a counter is and how `rate()` and `sum by` work. You need a terminal with `kubectl`. The playground is a private kind cluster with a `probe` workload that exposes a request duration histogram, a `traffic` workload, a `prometheus` server and a `shuttle` pod that calls the Prometheus HTTP API. Grafana is not installed in the playground.

## Reading Order

1. Histograms And histogram_quantile
2. Aggregating Quantiles And Averages
3. Dashboard Variables And Query Resolution
4. Summary

<!-- astrona:playground -->
