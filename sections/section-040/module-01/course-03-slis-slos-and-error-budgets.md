---
draft: true
exam_objectives:
- Alerting basics (when, what, and why)
---
# SLIs, SLOs And Error Budgets

Alert thresholds need a reason. A service level objective gives that reason: it states how reliable a service must be, and the error budget states how much unreliability is allowed. This part defines the terms, shows how an error budget is computed, and connects it to alerts.

## Service level indicator

A **service level indicator (SLI)** is a measured number that describes one aspect of the service as users see it. The most common SLI is the proportion of good events:

```text
SLI = good events / valid events
```

For the `probe` service, a valid event is a request counted in `lab_requests_total`. A good event is a request with `status="200"`. In PromQL, the SLI over a window is:

```promql
sum(rate(lab_requests_total{status="200"}[30s]))
/
sum(rate(lab_requests_total[30s]))
```

Other SLIs use latency (the share of requests faster than a limit), freshness or throughput. The indicator must come from the point of view of the caller and must have a clear definition of which events count.

## Service level objective

A **service level objective (SLO)** is a target for an SLI over a period. For example: "99.9 percent of requests succeed, measured over 30 days". An SLO has three parts: the indicator, the target and the window. Changing any of them changes the meaning.

An SLO is not a promise to customers and not a prediction. It is an internal agreement about how much failure is acceptable. A contract with a customer is a service level agreement (SLA), which usually has a looser target and a penalty.

## Error budget

The **error budget** is the part of the target that may be missed:

```text
error budget = 1 - SLO target
```

With a target of 99.9 percent, the error budget is 0.001, which is 0.1 percent of all requests. Over a window with one million requests, up to one thousand requests may fail without breaking the SLO. Over a 30 day window, 0.1 percent of the time is about 43 minutes of full outage.

The budget turns reliability into a number that teams can spend. If the budget is nearly used, the team slows risky changes. If a large part is left, the team can release faster.

## Burn rate

The **burn rate** compares the current error ratio to the allowed ratio:

```text
burn rate = observed error ratio / error budget
```

A burn rate of 1 uses the budget at exactly the speed that spends it over the full window. A burn rate of 10 uses it ten times faster, so a 30 day budget would be gone in three days. The same ratio of failures can be harmless or serious depending on the SLO, and the burn rate carries that information.

For the `probe` service with a budget of 0.001, an observed error ratio of 0.01 gives a burn rate of 10. In this environment the traffic generator fails every tenth request, so the error ratio is near 0.1 and the burn rate is near 100. This is far above any reasonable alert threshold, which makes the lab alerts fire.

## From budget to alert

A symptom alert based on the budget asks one question: how fast is the budget being consumed? The expression compares the error ratio with a multiple of the budget.

```promql
sum(rate(lab_requests_total{status="500"}[30s]))
/
sum(rate(lab_requests_total[30s]))
> 14.4 * 0.001
```

The number 14.4 is a burn rate. At that speed, a 30 day budget is gone in about two days, and one hour of burning uses two percent of it. The important point is that the threshold comes from the SLO and the response time wanted, not from an arbitrary percentage.

## Choosing an SLI and target

Pick the SLI from user experience first. Then check that the metrics exist and have a stable definition. Pick the target from what users need and what the system can deliver today. A target of 100 percent is not useful: it leaves no budget, and every deployment would break it. A target that the service always exceeds by a wide margin gives no signal.

## Query the ratio in the playground

Use the private kubeconfig of the module playground. This command calls the Prometheus HTTP API from the `shuttle` pod and prints the error ratio as JSON. The output is not shown here because it depends on the traffic at that moment.

<!-- astrona:playground:renew -->

```sh
export KUBECONFIG="$(astrona kubeconfig ats-051-playground-040-01)"
kubectl -n starfleet exec shuttle -- python -c "import urllib.request,urllib.parse; q='sum(rate(lab_requests_total{status=\"500\"}[30s]))/sum(rate(lab_requests_total[30s]))'; print(urllib.request.urlopen('http://prometheus.starfleet.svc:9090/api/v1/query?query='+urllib.parse.quote(q)).read().decode())"
```

Read the `value` field: the first element is the evaluation time and the second is the ratio as a string. Divide the ratio by 0.001 to get the burn rate.

## Common pitfalls

> [!WARNING]
> A target of 100 percent leaves no error budget. Choose a target below it.

> [!WARNING]
> Counting requests that were never valid, such as health checks, changes the ratio. Define valid events explicitly.

> [!WARNING]
> A burn rate without its window is incomplete. Always state the window used to measure the error ratio.

> [!WARNING]
> Do not copy a burn rate threshold from another service with a different SLO.
