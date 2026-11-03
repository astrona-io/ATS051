---
draft: true
exam_objectives:
- Dashboarding basics
---
# Summary

A histogram stores request durations as cumulative bucket counters with the label `le`, plus a sum of durations and a count of observations. The bucket with `le="+Inf"` equals the count. The application chooses the bucket bounds, and Prometheus cannot change them later.

The function `histogram_quantile` estimates a quantile from the buckets. It finds the bucket that holds the requested rank and interpolates linearly inside it. The error cannot be larger than the width of that bucket, and a quantile above the highest finite bound is reported as that bound. Choose a bucket bound near each latency target that matters.

Quantiles are estimated from the rate of the buckets, after the buckets of all replicas are added with `sum by (le)`. The `le` label must stay in the `by` clause, or the result is empty. A quantile is never averaged, added or compared by `max` across replicas, because it carries no information about the number of requests behind it. The mean latency is exact: it is the rate of the sum divided by the rate of the count, over the same window.

A summary metric exposes quantiles that the application calculated. They are accurate for one process but cannot be combined across replicas. A histogram can be combined and lets the query choose the quantile. Native histograms keep the whole distribution in one series, and a classic histogram uses one series for each bucket.

A dashboard tool such as Grafana sends the same queries that you send by hand. Variables fill label values into queries, and the list of values comes from the label values and series endpoints of the Prometheus HTTP API. The step follows the panel width and the min step setting. The variable `$__rate_interval` keeps the rate window longer than the step and than four scrape intervals. A multi-value variable needs a regular expression match.

Key facts to remember:

- Buckets are cumulative, and the last bucket is `+Inf`.
- Order of operations: `rate`, then `sum by (le)`, then `histogram_quantile`.
- Prometheus rejects a range query that returns more than 11,000 points for one series.
- When a panel looks wrong, run its final query against the API and compare.

<!-- astrona:playground:destroy -->
