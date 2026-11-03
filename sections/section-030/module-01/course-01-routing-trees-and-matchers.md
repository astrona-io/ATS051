---
draft: true
exam_objectives:
- Understand and Use Alertmanager
---
# Routing Trees And Matchers

An alert that reaches Alertmanager is a set of labels, a set of annotations, a start time and an optional end time. The labels identify the alert. Two alerts with identical labels are the same alert. Routing looks only at labels. Annotations are text for humans and are never used to choose a receiver.

## The Route Tree

The `route` block in the Alertmanager configuration is the root of a tree. Every route has a `receiver` name, and any route can have a `routes` list of children. The root route must exist and must match every alert, so it has no matchers. It acts as the fallback: an alert that no child route claims goes to the root receiver.

```yaml
route:
  receiver: default
  group_by: [alertname]
  routes:
  - matchers:
    - severity="critical"
    receiver: pager
  - matchers:
    - team="starfleet"
    receiver: starfleet-chat
```

Alertmanager evaluates the tree for each alert like this:

1. Start at the root. The root matches.
2. Look at the children of the current route in the order they are written.
3. The first child whose matchers all match the alert is chosen, and the search continues inside that child's own `routes`.
4. If no child matches, the current route is the final route and its receiver is used.
5. If a matching child has `continue: true`, after finishing that subtree the search goes on with the next sibling, so the alert can reach more than one receiver.

The consequence of step 3 is that order matters. A broad child placed first captures alerts that a narrower child below it was meant to receive.

## Matchers

A matcher compares one label with a value. The `matchers` list uses a text form with four operators.

- `label="value"` matches when the label equals the value exactly.
- `label!="value"` matches when the label is anything else, including when the label is missing.
- `label=~"regex"` matches when the label value matches the regular expression. The expression is anchored, so it must match the whole value.
- `label!~"regex"` matches when the value does not match the expression.

All matchers in one route must match at the same time. There is no OR inside a route. To express "critical or page" you write two routes with the same receiver, or one regular expression such as `severity=~"critical|page"`.

A label that the alert does not carry is treated as an empty string. That makes `severity=""` match an alert with no severity label, and it makes a negative matcher such as `severity!="info"` match alerts that have no severity at all. This is a frequent source of surprise when a rule forgets to set a label.

## What Routing Cannot Recover

Routing works with the labels the alert already has. Those labels come from the series the alert expression returned, plus the labels set in the rule. If the expression uses `sum by (service)`, only `service` survives, and a route that matches on `team` will never match. The fix belongs in the rule, either by keeping the label in the aggregation or by adding it in the rule's `labels` block. Changing the route cannot create the missing label.

The same applies to `group_by` and to inhibition: any label used later in the pipeline must be present on the alert when it arrives.

## Default Values Inherited By Children

A child route inherits settings from its parent when it does not set them. This covers `group_by`, `group_wait`, `group_interval` and `repeat_interval`. A child that only sets `receiver` therefore groups and times its notifications like its parent. A child that sets `group_by` replaces the parent's list, it does not add to it.

## Matching Is Done Per Alert

Routing is evaluated for each alert separately. Two alerts from the same Prometheus rule with different label values can follow different routes. After routing, the alerts that ended up on the same route and share the same `group_by` label values are placed in one group.

## Reading The Result In The Playground

The Alertmanager API accepts alerts directly, which lets you test a route without waiting for a rule. A POST to the v2 alerts path on the `alertmanager` service with a JSON list of objects, each with a `labels` object, creates an alert. A GET on the same path returns the alerts currently held, and each entry includes a `status` object with its `state`, `silencedBy` and `inhibitedBy` lists.

The probe webhook records the body of every notification. After you submit a fixture alert, a GET on `/hooks` on the `probe` service lists the notifications. In each stored body the `receiver` field names the receiver Alertmanager chose, and the `alerts` list holds the grouped alerts. Compare `receiver` with the route you expected. If it names the root receiver, no child matched.

## A Worked Example

Take the route tree shown above and two alerts. The first has the labels `alertname="ProbeDown"`, `severity="critical"` and `team="starfleet"`. The second has `alertname="ProbeSlow"`, `severity="warning"` and `team="starfleet"`.

For the first alert, Alertmanager checks the first child. The matcher `severity="critical"` matches, so the `pager` receiver is chosen. The first child has no `continue`, so the second child, which would also match on `team`, is never checked. The alert goes to `pager` only.

For the second alert, the first child does not match because the severity is `warning`. The second child matches on `team`, so the receiver is `starfleet-chat`. If the team label were missing, neither child would match and the alert would go to `default`.

Now add `continue: true` to the first child. The first alert then goes to `pager`, and the search goes on to the second child, which also matches. The alert is delivered to both `pager` and `starfleet-chat`. Each delivery is a separate notification with its own group and its own timers.

## Checking A Route Without An Alert Source

The command line tool `amtool` can test a route against a label set without sending anything. The `amtool config routes test` command takes the configuration file and a list of labels and prints the receivers it would choose. The Alertmanager API has no such dry run, so submitting a fixture alert and reading the stored webhook body is the way to test in a running cluster.

## Common Mistakes

- Putting a catch-all child first so that later children never match.
- Using `=` with a value that contains regular expression characters and expecting pattern matching.
- Forgetting that a regular expression matcher is anchored.
- Expecting `continue` on the last matching route to do anything. It only matters when another sibling follows.
- Matching on a label the alert expression dropped.

> [!WARNING]
> A route that matches nothing is not an error. Alertmanager loads the file and the alert quietly falls through to the parent receiver. Always confirm the receiver in the stored notification body.
