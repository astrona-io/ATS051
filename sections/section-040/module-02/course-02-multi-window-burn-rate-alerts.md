---
draft: true
exam_objectives:
- Alerting basics (when, what, and why)
---
# Multi-Window Burn Rate Alerts

A single look-back window forces a trade-off. A long window gives reliable evidence but keeps the alert firing long after the problem is fixed. A short window resets quickly but reacts to brief spikes. A multi-window alert uses both and fires only when both agree. This part shows the rule, explains the mechanism, and lists the metadata a paging alert needs.

## Why one window is not enough

Suppose the alert uses only a one hour window with a threshold of 14.4. A short outage of five minutes at a full failure rate raises the one hour error ratio above the threshold. The alert fires. The outage ends, but the one hour ratio stays above the threshold for most of the next hour, so the alert keeps firing, and the person paged sees a problem that no longer exists.

Suppose the alert uses only a five minute window instead. It resets quickly, but any brief spike pages a person, even if it consumed almost no budget.

## The two-window condition

The rule requires the error ratio in both windows to be above the same threshold:

```promql
(
  sum(rate(lab_requests_total{status="500"}[30s]))
  / sum(rate(lab_requests_total[30s]))
  > 14.4 * 0.001
)
and
(
  sum(rate(lab_requests_total{status="500"}[10s]))
  / sum(rate(lab_requests_total[10s]))
  > 14.4 * 0.001
)
```

The long window (30 seconds here) shows that the budget loss is significant. The short window (10 seconds) shows that the problem is still happening. When the fault is fixed, the short-window ratio drops first, the `and` becomes false and the alert resolves quickly. In a production setting the same pattern uses one hour and five minutes, where the short window is about one twelfth of the long one.

## How `and` works

In PromQL, `and` is a set operator between two instant vectors. It keeps the elements of the left side that have a match on the right side with identical labels. Both sides here are aggregated with `sum(...)` without `by`, so each is a single element with an empty label set. They match, and the result is the left value. If either comparison filters its element out, the result is empty and no alert instance exists.

When the sides are aggregated `by (service)`, the label sets must agree. Use `by` consistently in both windows, or the `and` returns nothing.

Comparison binds tighter than `and`, so the parentheses are not required by the parser. They make the rule easier to read.

## The `for` duration

The `for` field holds the alert in the pending state until the expression has been true for the stated time. With two windows the `for` duration can be short. The long window already provides evidence, and the short window handles reset. A long `for` on top of a long window delays the page without adding much safety.

The lab uses 10 seconds or less because evaluation happens every two seconds.

## A tiered set

A real service uses several pairs, each with a burn rate, a long window and a short window of one twelfth.

- Burn rate 14.4, windows 1 hour and 5 minutes: two percent of the budget in one hour. Page.
- Burn rate 6, windows 6 hours and 30 minutes: five percent in six hours. Page.
- Burn rate 1, windows 3 days and 6 hours: ten percent in three days. Ticket.

The fast pair catches outages quickly. The slow pair catches problems that no fast pair sees because they burn just above the allowed speed.

## Labels and annotations

The full rule has metadata so that Alertmanager and the receiver can act on it:

```yaml
groups:
- name: lab
  interval: 2s
  rules:
  - alert: ErrorBudgetFastBurn
    expr: |
      (sum(rate(lab_requests_total{status="500"}[30s])) / sum(rate(lab_requests_total[30s])) > 14.4 * 0.001)
      and
      (sum(rate(lab_requests_total{status="500"}[10s])) / sum(rate(lab_requests_total[10s])) > 14.4 * 0.001)
    for: 10s
    labels:
      severity: page
    annotations:
      summary: The probe service burns its error budget 14.4 times too fast
      runbook_url: https://example.com/runbooks/probe-error-budget
```

The `severity` label routes the alert. The `summary` annotation says what is wrong. The `runbook_url` annotation tells the receiver where the procedure is. The address uses `https://`.

## Apply and observe in the playground

Prometheus reads the rule file from a ConfigMap, so after you have applied the ConfigMap change, restart it. Then read the rule state from the HTTP API.

<!-- astrona:playground:renew -->

```sh
export KUBECONFIG="$(astrona kubeconfig ats-051-playground-040-02)"
kubectl -n starfleet rollout restart deployment/prometheus
kubectl -n starfleet rollout status deployment/prometheus --timeout=180s
kubectl -n starfleet exec shuttle -- python -c "import urllib.request; print(urllib.request.urlopen('http://prometheus.starfleet.svc:9090/api/v1/rules').read().decode())"
```

Look for `state` in the rule: `pending` before the `for` duration has elapsed and `firing` after it. `health` must be `ok`.

## Common pitfalls

> [!WARNING]
> Different label sets in the two windows make `and` return nothing. Aggregate both sides the same way.

> [!WARNING]
> Forgetting that the short window must be shorter than the long window removes the fast reset.

> [!WARNING]
> Using a different threshold in each window changes the meaning. Use the same threshold in both.

> [!WARNING]
> A paging alert without a runbook annotation leaves the receiver without a procedure.
