---
draft: true
exam_objectives:
- Alerting basics (when, what, and why)
---
# Burn Rate Math

A burn-rate alert answers one question: at the current speed of failures, how soon will the error budget be gone? This part gives the formulas, works through the numbers for a 99.9 percent SLO, and shows how to turn a wanted response time into a threshold. It uses only arithmetic that you can check by hand.

## The quantities

Four numbers describe the situation.

- **SLO target** `T`: the proportion of good events, for example 0.999.
- **Error budget** `B = 1 - T`: the allowed proportion of bad events, for example 0.001.
- **SLO window** `W`: the period over which the target applies, for example 30 days, which is 720 hours.
- **Error ratio** `E`: the observed proportion of bad events over a short look-back window.

The burn rate is `E / B`. If `E` is exactly `B`, the burn rate is 1, and the budget lasts exactly `W`. If the burn rate is `r`, the budget lasts `W / r`.

## Time to exhaustion

For a 30 day window:

- Burn rate 1: the budget lasts 30 days.
- Burn rate 2: it lasts 15 days.
- Burn rate 10: it lasts 3 days.
- Burn rate 14.4: it lasts about 50 hours, which is 720 divided by 14.4.
- Burn rate 720: it lasts one hour.

A fully failed service has an error ratio of 1. With a budget of 0.001 the burn rate is 1000, so the budget is gone in 43.2 minutes.

## Fraction of budget consumed

An alert is often described by how much of the budget may be consumed before someone must act. If the burn rate is `r` and it continues for a duration `d`, the consumed fraction is:

```text
consumed = r * d / W
```

At a burn rate of 14.4 over one hour in a 720 hour window: 14.4 * 1 / 720 = 0.02, which is two percent of the budget. At a burn rate of 6 over six hours: 6 * 6 / 720 = 0.05, five percent. At a burn rate of 1 over 72 hours (three days): 72 / 720 = 0.1, ten percent.

These three pairs are a common starting point: a fast burn that needs a page, a medium burn that also needs a page, and a slow burn that becomes a ticket.

## From a wanted detection to a threshold

To pick a threshold, decide how much budget you accept losing before the alert fires, and over what look-back window. Rearranged:

```text
r = consumed * W / d
```

If you accept losing two percent of a 720 hour budget and look back one hour: r = 0.02 * 720 / 1 = 14.4. The error-ratio threshold is then `r * B`, which is 14.4 * 0.001 = 0.0144. The alert condition becomes `E > 0.0144` over the one hour window.

A higher burn-rate threshold detects only large outages but detects them quickly. A lower threshold catches small, long problems but needs a longer window to avoid noise. Because one rule cannot serve both, a set of several rules with different windows is used.

## Detection time

The time until an alert fires is at least the `for` duration plus the time the look-back window needs to fill with failures. If a full outage starts with an error ratio of 1 and the threshold ratio is 0.0144, the one hour window reaches the threshold after about 0.0144 of an hour, which is under one minute. A small failure at a ratio just above the threshold takes close to the whole window. Detection time shrinks as the problem gets worse.

## Scaled numbers in the lab

The lab cannot wait hours, so it keeps the same threshold of 14.4 but uses windows of 30 seconds and 10 seconds. The meaning of 14.4 is then different: it is only the multiple of the budget used as a threshold. The traffic generator fails ten percent of the requests, so the burn rate is about 100, far above 14.4, and the alert fires within seconds.

## A worked example

The `probe` service has `T = 0.999` and `B = 0.001`. A deployment starts failing one request in fifty, so `E = 0.02`. The burn rate is 0.02 / 0.001 = 20. At that speed the 720 hour budget lasts 36 hours. If the failure continues for one hour, 20 * 1 / 720 = 0.0278 of the budget is consumed, which is about 2.8 percent.

Compare this with a threshold of 14.4: the burn rate of 20 is above it, so a fast-burn alert fires. A slower fault with `E = 0.003` has a burn rate of 3. It is below 14.4 and does not page. It would be caught by a slow-burn rule, which exists to turn it into a ticket.

## Low traffic

At a very low request rate, a single failure can exceed the threshold in a short window. If the service gets one request per minute, one failed request gives an error ratio of 1 in a one minute window. Choose longer windows, or add a minimum rate in the expression, so that single events do not page. Do not remove the alert for rare but critical flows. Use a separate absolute-failure alert for them.

## Checking the numbers

Always check a threshold with one extra calculation before it goes into a rule. Divide the budget by the threshold ratio to get the time to exhaustion in units of the window. For the ratio 0.0144 and the budget 0.001, the burn rate is 14.4 and the window of 720 hours gives 50 hours. If that time does not match the response you want, change the burn rate and calculate again.

## Common pitfalls

> [!WARNING]
> The threshold in the expression is `r * B`, the error ratio, not the burn rate itself. Writing `> 14.4` against a ratio never fires.

> [!WARNING]
> A burn rate is only meaningful with the SLO window it refers to. A 14.4 threshold for a 30 day window is not 14.4 for a 7 day window.

> [!WARNING]
> Do not copy a threshold from another service with a different target. The budget `B` changes the error-ratio threshold.

> [!WARNING]
> Check the arithmetic: consumed fraction, window and burn rate are linked, and a wrong unit (hours against days) changes the result by a factor of 24.
