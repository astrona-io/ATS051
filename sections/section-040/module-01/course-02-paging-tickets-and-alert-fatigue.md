---
draft: true
exam_objectives:
- Alerting basics (when, what, and why)
---
# Paging, Tickets And Alert Fatigue

Every notification costs the receiver attention. Alerting design is the work of spending that attention only where a person can change the outcome. This part explains how to choose between a page, a ticket and a dashboard, why too many alerts make a team slower, and which Prometheus features reduce noise.

## Three kinds of output

A condition can be delivered in three ways.

- **Page.** A notification that interrupts a person at any hour, usually through a paging service or a phone call. Use it when the condition harms users now, or will within minutes, and a human action can improve the situation.
- **Ticket.** A work item or message that waits for working hours. Use it when the condition needs a human decision but not immediately: a certificate that expires in ten days, a disk that will fill in a week, a slow budget burn.
- **Dashboard or log.** A visible signal that nobody is notified about. Use it for causes, for capacity trends and for everything that helps diagnosis but is not a call to act.

The rule of thumb is that a page must be both urgent and actionable. A condition that is urgent but has no possible action, or actionable but not urgent, is not a page.

## Alert fatigue

Alert fatigue is the loss of attention that happens when people receive many notifications that need no action. The mechanism is simple. Each unnecessary alert teaches the receiver that alerts are probably false. After enough of them, the receiver reacts slower to all alerts, including the real one. Teams then mute channels, add automatic acknowledgements or ignore the pager. The alert system has failed even though every rule evaluates correctly.

Signs of fatigue are visible in data. Count how many notifications each alert produced in a month and how many of them led to an action. An alert with many notifications and few actions is a candidate for removal or for a lower severity. Count how many alerts fire together for one cause. If one outage causes forty notifications, the grouping and inhibition settings need work.

## Features that reduce noise

Prometheus and Alertmanager provide several tools. Each one acts at a different place in the pipeline.

1. **The `for` duration.** An alerting rule with `for: 5m` moves from pending to firing only if the expression holds on every evaluation for five minutes. Brief spikes never reach Alertmanager. The cost is a later notification, so the duration must fit the urgency.
2. **Ratios over windows.** Using `rate()` over a window smooths single failures. A longer window is steadier and slower, a shorter one is faster and noisier.
3. **Grouping.** Alertmanager can combine many alerts with the same labels, such as `alertname` and `service`, into one notification.
4. **Inhibition.** A firing critical alert can suppress warnings for the same service, so the receiver gets the most important message only.
5. **Silences.** A silence is a temporary rule in Alertmanager that mutes alerts matching given label matchers, for example during planned maintenance. It has an end time.
6. **Severity routing.** Alertmanager routes `severity="page"` to a paging receiver and `severity="ticket"` to a ticket receiver, so each alert reaches the right place.

A rule written well needs fewer of these. A rule written on a cause metric with no `for` duration needs all of them and still produces noise.

## Choosing the level for a condition

Ask these questions in order.

1. Does it affect users now? If no, it is not a page.
2. Can a person do something that changes the outcome? If no, it is not a page.
3. Does it need action within minutes, or can it wait for working hours? Minutes means page, otherwise ticket.
4. Does the alert help only diagnosis? Then it is a dashboard panel.

## An example set for the probe service

For the `probe` service, a reasonable set has four rules.

- `ErrorBudgetFastBurn`, severity `page`: both a long and a short window show a high error ratio.
- `ErrorBudgetSlowBurn`, severity `ticket`: a lower error ratio over a long window.
- `ProbeDown`, severity `page`: no successful scrape of the job.
- `Watchdog`, severity `none`: an alert that always fires, so a missing notification proves that the pipeline is broken.

Cause metrics such as `lab_queue_depth` appear on a dashboard next to the error ratio so that the responder sees them after the page arrives.

## What a good page message contains

The page itself must help the receiver start work. The rule carries this information in labels and annotations, and Alertmanager forwards it to the receiver.

- The `summary` annotation: one sentence that says what is wrong and for whom, for example that the error ratio of the `probe` service is above the budget threshold.
- The `description` annotation: more detail, including the current value from the template `{{ $value }}`.
- The `runbook_url` annotation: the address of the runbook for this alert.
- The labels `severity`, `team` and `service`: routing and grouping keys.

A message such as "alert fired" with no context forces the receiver to open several tools before knowing the scope. A message with a clear summary and a runbook lets the receiver decide in seconds whether to act.

## Ownership and escalation

Every page has an owner. Routing by the `team` label sends the notification to the correct on-call schedule. If the receiver does not acknowledge the page, the paging service escalates it to a second person. This behaviour belongs to the paging service. Alertmanager only delivers the notification and repeats it according to `repeat_interval` while the alert still fires.

## Keeping the set healthy

Review the alerts on a schedule. After an incident, ask whether an alert fired early enough and whether the runbook helped. After a noisy week, ask which alerts produced notifications without an action. Change the rule, the severity or the threshold, or delete the alert. A smaller set that people trust is better than a larger set they ignore.

## Common pitfalls

> [!WARNING]
> Paging for conditions that wait until morning trains people to ignore the pager.

> [!WARNING]
> A very long `for` duration hides short but serious outages. Choose it from the urgency, not only from noise.

> [!WARNING]
> Muting a noisy alert with a silence hides the problem. Fix the rule, or lower its severity.

> [!WARNING]
> An alert set with no always-firing check cannot show that the delivery path works.
