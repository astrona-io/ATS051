---
draft: true
exam_objectives:
- Dashboarding basics
---
# Dashboarding basics

This section teaches how to build dashboard panels that a reader can interpret correctly. A panel is a query against Prometheus, and its meaning depends on the series it selects, the unit of its values, the time settings and the way missing data is shown. The section has two modules. The first covers population, grouping, units, ratios, time settings and gaps. The second covers histograms, quantiles and the variables and resolution settings of a dashboard tool.

Each module has a playground, a private kind cluster with a Prometheus server and a workload that exposes metrics. You check every claim by sending queries to the Prometheus HTTP API. Each module ends with a summary. A capstone lab closes the section.

## Learning Outcomes

- Choose panels for traffic, errors, duration and saturation, and select their population with label selectors.
- Group series with `sum by` at the level that the question needs.
- Build a rate and an error ratio from counters, state the unit and show the denominator.
- Explain how the time range, the step and the rate window determine the points of a line, and calculate the number of points as range divided by step, plus one.
- Distinguish a gap, an empty result and a measured zero, and explain staleness and `absent()`.
- Calculate a quantile with `histogram_quantile` over `sum by (le)` of bucket rates, and explain why its accuracy depends on bucket bounds.
- Calculate a mean latency from the rates of `_sum` and `_count`, and explain why quantiles are never averaged.
- Describe how dashboard variables, `$__rate_interval`, min step and max data points map to Prometheus HTTP API calls.
