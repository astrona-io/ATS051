---
draft: true
exam_objectives:
- Understand and Use Alertmanager
---
# Summary

Inhibition suppresses the notifications of target alerts while a matching source alert is firing. A rule needs source matchers, target matchers and an `equal` list that names the labels both alerts must share. Without `equal`, the rule applies to the whole system. The suppressed alerts are still received and still firing, and the API reports them as suppressed with an `inhibitedBy` list.

A receiver is a named list of integrations. A route chooses it by name, and Alertmanager sends each grouped notification to all of its integrations. The webhook integration posts a JSON body with the group labels, common labels and the list of alerts. Text integrations build messages from Go templates over the same data. Credentials belong in files or secrets, never in labels or annotations.

An Alertmanager cluster shares silences and a notification log by gossip on port 9094. Prometheus sends every alert to every instance, and each instance waits a position-based delay and checks the log before it sends. The design gives at-least-once delivery. It does not give exactly-once delivery, and a network partition can produce duplicates. A load balancer in front of the instances breaks the design.

The v2 API and `amtool` show the same state. The alert list reports the state, `silencedBy` and `inhibitedBy` for each alert. `amtool check-config` and `amtool config routes test` validate a file and a route without a running server, and the status endpoint shows the configuration that is really loaded.

<!-- astrona:playground:destroy -->
