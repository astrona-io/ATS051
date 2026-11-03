---
draft: true
exam_objectives:
- Configuring Alerting rules
---
# Troubleshooting Rules

A rule that does not alert can have a fault in the file, in the expression, in the data, in the timing, or in loading. Work through the causes in order from the closest to Prometheus input to the farthest. Each step has a specific place to read the evidence.

## Step One: Is The Rule Loaded

Read the rules API. If the rule name is not listed, Prometheus did not load it. The causes are an unchanged file, a file that does not match `rule_files`, a reload that was rejected, or a mounted file that has not updated yet.

Check `prometheus_config_last_reload_successful`. A value of zero means the last reload failed, and the old rules are still active. The Prometheus log names the file and the parse error.

## Step Two: Is The Rule Healthy

Each rule in the API has `health`, `lastError` and `evaluationTime`.

- `ok` means the last evaluation finished without error.
- `err` means it failed. `lastError` contains the message, such as a query timeout, a limit exceeded, or too many samples.
- `unknown` means the rule has not been evaluated yet, for example just after loading.

A failing rule produces no alerts and no recorded samples. Fix the error before looking at anything else.

## Step Three: Does The Expression Return Data

Health `ok` does not mean the expression returns data. An empty result is a valid result. Run the expression through the query API at the current time.

- If it returns nothing, remove parts of the expression from the right until data appears. Common causes are a selector that matches no series, a label name with the wrong spelling, a `rate` window shorter than two scrape intervals, and a division where the denominator is empty.
- If the sub-expression returns data and the comparison filters everything out, the threshold is not reached. Look at the value without the comparison.

List the real values of a label to compare with the selector. Querying the metric by name and reading the label values from the result shows whether `status="5xx"` or `status="500"` is the real spelling.

## Step Four: Is The Alert Stuck Pending

A pending alert has `state` equal to `pending` and an `activeAt` time. If it never leaves pending, compare the elapsed time since `activeAt` with `for`. If `activeAt` keeps moving to a later time, the expression is returning no result between evaluations, so the timer restarts.

Causes include a threshold the metric crosses only briefly, a rate window too short for the traffic, and a label that changes. Widen the window, lower the `for` value, or use `keep_firing_for` if the condition drops out for short periods.

## Step Five: Is The Timing Realistic

Add up the delays. The scrape interval, the rate window, the group interval and `for` all apply before the alert is firing. A `for: 1h` keeps a correct alert pending for an hour. A rule can be correct and still seem broken because the observer expected a result sooner.

## Step Six: Is The Alert Reaching Alertmanager

Prometheus lists the Alertmanagers it knows about in the alertmanagers API, with their URLs. Metrics such as `prometheus_notifications_sent_total` and `prometheus_notifications_errors_total` count deliveries to them. An alert that is firing in Prometheus and appears in the Alertmanager alert list was delivered. Anything after that point is routing, silences, inhibition or receiver behaviour, which belongs to Alertmanager configuration.

## Typical Faults And Their Evidence

| Symptom | Evidence | Usual cause |
| --- | --- | --- |
| Rule not in API | No rule with that name | File not loaded or reload rejected |
| Rule health `err` | `lastError` text | Query error or limit exceeded |
| Health `ok`, no alert | Expression returns nothing | Selector or label mismatch |
| Alert stays pending | `activeAt` keeps changing | Condition flaps or label changes |
| Alert is pending long | `activeAt` fixed, state pending | `for` is long |
| Firing, no notification | Not in Alertmanager | Notification path |

## Fixing Without Hiding The Cause

Change the one thing the evidence points to. Lowering a threshold to make a broken selector fire hides the mistake and makes the alert noisy later. Removing `for` to make a flapping alert fire creates paging noise. Prefer the smallest change that makes the rule express the intent, and then re-read the same API fields to confirm it.

## Loading The Fix

After editing a ConfigMap-backed rule file, apply the ConfigMap and make Prometheus read it. A restart of the Deployment works. After the restart, wait for at least one evaluation interval plus the `for` duration before concluding anything, and read the rules API and the alerts API again.

## Worked Example Of Narrowing An Expression

Take this expression, which never returns data.

```promql
sum(rate(lab_requests_total{status="5xx"}[10s])) / sum(rate(lab_requests_total[10s])) > 0.05
```

Evaluate its parts separately, each as its own query.

1. `lab_requests_total` returns series, so the metric exists and is scraped.
2. `rate(lab_requests_total[10s])` returns series, so the window holds enough samples.
3. `lab_requests_total{status="5xx"}` returns nothing, so no series has that label value.
4. Listing the `status` values of the metric shows `200` and `500`.

The first empty part is the fault. The selector asks for a value that the metric never has, so the numerator is empty, the division returns nothing, and the comparison has nothing to filter. Changing the selector to the real value is the minimal fix. The threshold, the window and the `for` duration are not at fault and should not be changed to compensate.

## Reading The Active Alerts

The alerts API returns, for each active instance, the label set, the annotations after template expansion, the state, the `activeAt` time and the value. Use these fields in this way.

- The `value` field shows how far above the threshold the expression is.
- The `activeAt` field shows when the continuous run began.
- The annotations show whether templates expanded.

If annotations show literal braces, the template text was stored unexpanded or the file was read from another source. If a label that routing needs is absent, the aggregation removed it or the rule never added it.

## Common pitfalls

> [!WARNING]
> A healthy rule can still be empty. The old rules stay active after a rejected reload. Waiting too short a time after the restart makes a correct fix look like a failure.
