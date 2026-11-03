---
draft: true
exam_objectives:
- Dashboarding basics
---
# Dashboards That Explain Population, Units And Gaps

A dashboard is a page of queries drawn as panels. Each panel looks simple, but its meaning depends on the series it selects, the unit of its numbers, the time settings that the dashboard sends and the way missing data is shown. This module teaches how to build panels that a reader can interpret correctly, and how to check each panel against the Prometheus HTTP API.

## Learning Goals

- Choose panels for traffic, errors, duration and saturation, and select their population with label selectors.
- Group series with `sum by` at the level that the question needs.
- Build a rate and an error ratio from counters, and state the unit of each panel.
- Show the denominator that supports a ratio.
- Explain how the time range, the step and the rate window work together.
- Distinguish a gap, an empty result and a measured zero, and explain staleness.

## Before You Start

You need basic knowledge of Prometheus metric types: a counter only increases, and a gauge goes up and down. You need a terminal with `kubectl`. The playground of this module is a private kind cluster with a `probe` workload that exposes metrics, a `traffic` workload that sends requests, a `prometheus` server and a `shuttle` pod that you use to call the Prometheus HTTP API.

## Reading Order

1. Panels, Population And Grouping
2. Units, Ratios And Denominators
3. Time Range, Step And Rate Window
4. Gaps, Staleness And Zero
5. Guided Practice
6. Summary

<!-- astrona:playground -->
