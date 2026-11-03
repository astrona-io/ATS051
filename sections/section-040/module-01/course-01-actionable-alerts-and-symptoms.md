---
draft: true
exam_objectives:
- Alerting basics (when, what, and why)
---
# Actionable Alerts And Symptoms

An alert is a notification that a rule produced because its condition held for a stated time. In Prometheus, an alerting rule is a PromQL (Prometheus Query Language) expression plus a `for` duration, labels and annotations. Prometheus evaluates the expression on a schedule. Each series the expression returns becomes one alert. An alert is useful only if the person who receives it can decide something or do something. This part explains what makes an alert actionable and why symptoms are the usual thing to alert on.

## What actionable means

An alert is actionable when four questions have a clear answer at the moment it arrives.

- **Who is affected?** A named population: the users of one service, one region or one customer tier.
- **How bad is it?** The impact in terms the receiver understands, such as the share of failed requests.
- **Who owns it?** One team that can change the system. The route to that team is usually a label such as `team` or `service`.
- **What should happen next?** A runbook, which is a short document that lists the checks and the actions for one alert. The alert points to it through an annotation.

If any answer is missing, the receiver spends the first minutes of the incident guessing. If no action exists at all, the alert should not interrupt a person. It can be a dashboard panel or a ticket instead.

## Symptoms and causes

A **symptom** is something a user or a calling system can observe: requests fail, responses are slow, data is stale, a job does not finish. A **cause** is a state inside the system that may lead to a symptom: high CPU use, a full disk, a long queue, a restarted pod, a slow dependency.

Alerting on a symptom has three advantages.

1. It matches impact. If the symptom is present, someone is affected. A symptom alert has few false positives.
2. It covers causes nobody listed. A service can fail through a certificate that expired, a bad deployment or a network rule. One error-ratio alert catches all of them. A set of cause alerts catches only the causes someone thought of in advance.
3. It stays valid when the system changes. A new cache or a new database changes which cause metrics matter. The user-facing success rate keeps its meaning.

Cause metrics still have a job. They help the person who was paged to find the reason. They belong on dashboards, in the alert annotations and in a small number of alerts that warn of a failure that will certainly happen soon, such as a disk that will be full in four hours at the current rate.

## Symptoms in this environment

The `probe` service exposes a counter named `lab_requests_total` with a `status` label that holds `200` or `500`. A counter is a metric that only goes up, so its rate is computed with `rate()`. The error ratio, which is the share of requests that fail, is:

```promql
sum(rate(lab_requests_total{status="500"}[30s]))
/
sum(rate(lab_requests_total[30s]))
```

This expression is a symptom: it measures the outcome seen by callers. The gauge `lab_queue_depth` is a cause candidate. A queue of three items says nothing about failed requests. A queue that grows while the error ratio stays low may be normal. Paging on the queue alone would interrupt a person without a user-visible problem.

## Thresholds do not decide urgency

A numeric threshold is only a way to express a condition. It does not say how urgent the condition is. Two alerts with the same expression and threshold can need different handling, depending on three things.

- **Population.** Ten percent errors on a service used by one test client is not the same as ten percent errors on the checkout path.
- **Speed.** An error ratio that rose from zero to ten percent in one minute needs attention sooner than a ratio that has crept up over a week.
- **Reversibility.** A fault that corrects itself in seconds needs no person. A fault that keeps losing data does.

This is why the `for` duration, the window of the `rate()` function and the severity label are part of the design, not afterthoughts.

## Severity as a statement of response

The `severity` label should describe the response, not the subsystem that produced the metric. A common set of values is:

- `page`: a person is woken up or interrupted at once.
- `ticket`: a person looks at it during working hours.
- `none` or `info`: kept for dashboards and for the pipeline itself.

The labels `severity`, `team` and `service` are chosen so that Alertmanager can route on them. Alertmanager is the component that receives alerts from Prometheus and decides where to send them. Labels that carry changing numbers, such as the current error ratio, must not be used as identifying labels, because every new value would create a new alert and a new notification. Put the current value in an annotation instead, for example with the template `{{ $value }}`.

## Low traffic and missing data

A ratio is volatile when it is based on few events. One failed request out of two is fifty percent, but it is weak evidence. Options are a longer window, a minimum request rate in the expression, or a separate alert on absolute failures. Whichever option is used, a real failure in a rarely used critical flow must not be hidden.

An empty query result is not the same as zero errors. If the target stops being scraped, the expressions that read its metrics return nothing, and an alert on a threshold never fires. Detecting this needs its own rule, such as `absent(up{job="probe"} == 1)`, or an alert on `up == 0`.

## Review the alert set

An alert set needs maintenance. For each alert that fired in the last period, ask whether the receiver took an action, whether the right team received it and whether it came early enough. Alerts that fire often and lead to no action are noise. Remove them or lower them to a ticket. Alerts that arrived late need a shorter window. A quiet inbox can mean a healthy service or a broken pipeline, so the pipeline itself needs a test.

## A worked decision

Take three conditions on the `probe` service and decide how each one is handled.

1. The error ratio is above 1.44 percent in both a 30 second and a 10 second window. Users receive failed responses at a rate that would consume the error budget very fast. This is a symptom, it has an owner and a runbook, and it needs a person now. Severity: `page`.
2. The error ratio is slightly above the objective but has been so for six hours. The budget is being used slowly. A person should look at it during working hours. Severity: `ticket`.
3. The gauge `lab_queue_depth` is above its usual value. No failed requests are visible. This stays on a dashboard. If the queue later causes failures, the error-ratio alert fires by itself.

Each decision names the symptom, the owner and the speed. None of them depends on a single magic number.

## Common pitfalls

> [!WARNING]
> Alerting on every cause metric produces many pages with no user impact. Start from the symptom and use cause metrics as supporting evidence.

> [!WARNING]
> An alert with no runbook and no owner is not actionable, even if its expression is correct.

> [!WARNING]
> Putting a changing value in a label creates a new alert for every value. Use an annotation for values.

> [!WARNING]
> A missing scrape makes threshold alerts silent. Add a rule that detects the absence of data.
