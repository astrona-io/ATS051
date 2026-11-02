---
draft: true
exam_objectives:
- Understand and Use Alertmanager
---
# Routing, Grouping, Silences And Inhibition

Alertmanager manages notifications for alerts produced by Prometheus or compatible sources. It groups related instances, routes them to receivers and applies suppression through silences or inhibition. It does not scrape applications or decide the truth of the original PromQL condition.

## Routing Uses Alert Labels

A routing tree matches alert labels such as team, service or severity. Matching routes select receivers and applicable notification behavior. The root route provides a complete fallback structure, while child routes specialize selected populations. Route ordering and the continue setting affect whether matching proceeds to additional sibling routes.

Ownership labels need to survive the source expression's aggregation. If a rule removes the team or service dimension required by routing, the notification may fall into a default receiver or an unintended group. A route cannot recover ownership that the alert never carried. Keep the label contract consistent between instrumentation, aggregation and notification configuration.

## Grouping Controls Presentation And Timing

Group_by determines which labels distinguish notification groups. Grouping by service can combine related instances, while grouping too broadly can mix unrelated incidents. Grouping too narrowly can generate a message for every affected replica and overwhelm responders. Choose the grouping model according to the incident relationship and recipient's work.

Group_wait delays the initial notification for a new group, allowing related alerts to arrive. Group_interval influences subsequent notifications for group changes, and repeat_interval controls repeated notifications under the applicable behavior. These timers are different from the alert rule's for duration, which establishes persistence before an instance fires.

## Silences And Inhibition Have Different Conditions

A silence suppresses notifications for alerts matching its conditions during a specified interval. It can represent approved maintenance or a known issue under active handling. The underlying alert can remain firing. A silence should have clear scope and ownership so it does not hide unrelated failures indefinitely.

Inhibition suppresses selected target alerts when another matching source alert is active. For example, a broader infrastructure failure can inhibit dependent symptoms when their shared labels establish the relationship. Equal-label requirements need careful design, including the behavior of missing labels. An overly broad rule can suppress alerts that are not actually consequences of the source incident.

## Follow Receiver Delivery

A firing alert can reach Alertmanager and still fail to notify because of routing, suppression or receiver errors. Review the instance labels, matched route, group state and applicable silence or inhibition before blaming the source expression. Receiver authentication, network access and destination availability are separate dependencies.

Notification payloads can contain operational or confidential context. Protect receiver credentials and avoid putting secrets in alert labels or annotations. Restrict access to notification management because creating a broad silence can materially reduce visibility without changing the application.

## High Availability Has A Contract

Multiple Alertmanager instances can coordinate to reduce duplicate notifications, but clustering and network partitions have operational behavior that must be understood. Do not promise universal exactly-once delivery. Sources should use the documented high-availability arrangement rather than assume an arbitrary load balancer reproduces it. Validate monitoring of the notification path itself so a quiet inbox is not mistaken for universal health.

## Common pitfalls

> [!WARNING]
> Suppression changes notification behavior rather than source health. Group timers differ from rule persistence, and routing cannot recover labels removed by the alert expression.
