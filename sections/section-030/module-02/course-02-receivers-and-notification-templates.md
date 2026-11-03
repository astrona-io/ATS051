---
draft: true
exam_objectives:
- Understand and Use Alertmanager
---
# Receivers And Notification Templates

A receiver is the last stage of the pipeline. It is a named entry in the `receivers` list that holds one or more integrations, and each integration knows how to deliver a notification to one destination. Routes refer to receivers by name. Alertmanager sends a grouped notification to every integration of the receiver.

## Receiver Configuration

Every receiver has a `name`. The rest of its fields are integration lists, such as `webhook_configs`, `email_configs`, `slack_configs`, `pagerduty_configs` or `opsgenie_configs`. A receiver with a name and no integrations is valid and sends nothing. This is the usual way to build a "discard" receiver for a route that should drop notifications.

```yaml
receivers:
- name: default
  webhook_configs:
  - url: http://probe:8080/hooks
    send_resolved: true
- name: pager
  webhook_configs:
  - url: http://probe:8080/hooks
- name: discard
```

The names must be unique, and every receiver named in a route must exist. Alertmanager refuses to load a file that violates either rule.

## The Webhook Integration

The webhook integration sends an HTTP POST with a JSON body to the `url`. The body has a fixed schema and is the same for every webhook receiver. Its main fields are:

- `version`, the schema version.
- `groupKey`, the identifier of the group.
- `status`, which is `firing` when at least one alert fires and `resolved` when all are resolved.
- `receiver`, the receiver name.
- `groupLabels`, the labels the group was built from.
- `commonLabels` and `commonAnnotations`, the labels and annotations all alerts share.
- `externalURL`, the address of the Alertmanager.
- `alerts`, a list with `status`, `labels`, `annotations`, `startsAt`, `endsAt` and `fingerprint` for every alert.

The `send_resolved` field says whether Alertmanager also sends the notification when the group resolves. Most integrations default it to false, and the webhook integration defaults it to true.

Alertmanager treats a non-success HTTP status from the endpoint as a failed delivery. It retries with an increasing delay until the request succeeds or the group changes. Failures are counted in Alertmanager's own metrics, which you can alert on.

## Credentials And Secrets

Integrations need credentials: an API key, a webhook URL with a token, an SMTP password. Alertmanager can read them from files with fields such as `api_url_file`, `password_file` or `routing_key_file`. A file kept in a Kubernetes Secret and mounted into the pod keeps the secret out of the ConfigMap. Do not place secrets in alert labels or annotations, because those are visible in the API, in silences and in every notification.

## Notification Templates

Integrations that send text, such as email, Slack and PagerDuty, build the text from templates written in the Go templating language. A template is a string in double braces. Fields available inside it come from a data object:

- `.Status`, `.Receiver`, `.GroupLabels`, `.CommonLabels`, `.CommonAnnotations` and `.ExternalURL`.
- `.Alerts`, `.Alerts.Firing` and `.Alerts.Resolved`, lists of alerts. Each alert has `.Labels`, `.Annotations`, `.StartsAt`, `.EndsAt` and `.Fingerprint`.
- Methods such as `.Labels.SortedPairs` and `.Labels.Names`.

A default template set ships with Alertmanager. You can add your own file under `templates` in the top-level configuration and name your template in an integration field:

```yaml
templates:
- /etc/alertmanager/templates/*.tmpl
```

```
{{ define "starfleet.title" -}}
[{{ .Status | toUpper }}] {{ .GroupLabels.alertname }} on {{ .GroupLabels.service }}
{{- end }}
```

An integration field uses it with `title: '{{ template "starfleet.title" . }}'`. The `define` block names the template, and `template` calls it with the data object.

## Labels And Annotations As Message Text

Annotations carry the text the message needs: a summary, a description, a link to a runbook. A rule sets annotations with its own templates evaluated by Prometheus, for example `{{ $labels.service }}`. By the time the alert reaches Alertmanager, those values are plain text. Alertmanager templates then arrange the final message.

## Testing A Receiver In The Playground

The webhook receiver can be tested without a template. Submit one alert to Alertmanager and read the stored body from the `probe` service. The `receiver` field proves which receiver was chosen, and the `alerts` list proves what was delivered.

<!-- astrona:playground:renew -->

```sh
kubectl -n starfleet exec shuttle -- python -c 'import urllib.request; print(urllib.request.urlopen("http://probe:8080/hooks", timeout=8).read().decode())'
```

Read the output as a JSON list. Each entry is one webhook body in the schema above. A delivery that failed does not appear here, so a missing body with a matching route points at the receiver URL or the network.

## Common pitfalls

> [!WARNING]
> A receiver can exist in the file and still never receive anything if no route names it. A route can name a receiver that sends nothing. Never put a token in a label. Check the stored notification, not only the configuration, before you decide a receiver works.
