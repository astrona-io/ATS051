---
draft: true
exam_objectives:
- Dashboarding basics
---
# Summary

A dashboard panel is a query plus three choices: which series it includes, how it groups them and which unit it shows. The population comes from label selectors. The grouping comes from the `by` clause of an aggregation. A total answers whether the service is healthy, and a split answers which group causes a problem. The reader needs the level that matches the question.

A counter only grows, so a panel shows a rate or an increase instead of the raw value. A rate has the unit "per second". A ratio of two rates over the same window has no unit and lies between 0 and 1. Both sides of the division must describe the same population, or the result is wrong or empty. A ratio hides volume, so the traffic that supports it belongs next to it.

The time range, the step and the rate window are separate settings. The dashboard sends the range and the step to the query range endpoint. The rate window is part of the expression. The number of points in a series is the range divided by the step, plus one. A step smaller than the scrape interval adds no information, and a rate window shorter than two scrape intervals is unreliable.

A missing value has three different meanings. A gap means that no sample is newer than the lookback delta of five minutes, or that a staleness marker ended the series. An empty result means that no series matched the selector. A zero means that Prometheus measured zero. A fallback to zero hides the difference between a healthy service and a failed collection, so use it only when a missing series means zero by design, and keep the scrape health visible.

Key facts to remember:

- `rate()` gives a per-second average over its window and survives counter resets.
- A division of two aggregations matches series by their labels, so a label mismatch gives an empty result.
- `absent()` returns one series with the value 1 when its argument matches nothing.
- The metric `up` shows whether the last scrape of a target worked.

<!-- astrona:playground:destroy -->
