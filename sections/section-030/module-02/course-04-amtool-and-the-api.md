---
draft: true
exam_objectives:
- Understand and Use Alertmanager
---
# amtool And The API

Alertmanager is operated through two interfaces. The HTTP API is the interface that Prometheus and scripts use. The command line tool `amtool` is a client for the same API, and it also works on configuration files without a running server. Knowing both lets you inspect state during an incident and check a change before it is loaded.

## The v2 API

The v2 API lives under `/api/v2` on port 9093. The paths used most often are:

- `GET /api/v2/alerts` returns the alerts that Alertmanager holds. Query parameters filter by `active`, `silenced`, `inhibited`, `unprocessed`, `receiver` and `filter` (a matcher).
- `POST /api/v2/alerts` creates or refreshes alerts. The body is a JSON list of objects with `labels`, optional `annotations`, `startsAt` and `endsAt`.
- `GET /api/v2/alerts/groups` returns the alerts grouped as the routing tree sees them, together with the receiver of each group.
- `GET /api/v2/silences` lists silences. `POST /api/v2/silences` creates or replaces one. `DELETE /api/v2/silence/{id}` expires one.
- `GET /api/v2/status` returns the version, the loaded configuration, the cluster state and the uptime.
- `GET /api/v2/receivers` lists the receiver names.

Each alert in a response has a `status` object. Its `state` is `active`, `suppressed` or `unprocessed`. The `silencedBy` and `inhibitedBy` lists explain why an alert is suppressed, and `mutedBy` lists active time intervals.

The control endpoints are different. `POST /-/reload` makes Alertmanager read its configuration file again, and `GET /-/healthy` and `GET /-/ready` report liveness and readiness. A reload with an invalid file is rejected, and the old configuration stays in use.

## amtool Commands

`amtool` reads its server address from `--alertmanager.url` or from a configuration file. Commands use the same matcher syntax as routes and silences.

- `amtool alert query alertname=ProbeDown` lists alerts that match.
- `amtool silence add alertname=ProbeErrors --duration=1h --comment="practice"` creates a silence. The author defaults to the current user.
- `amtool silence query` lists silences, and `amtool silence expire <id>` expires one.
- `amtool config show` prints the configuration the server loaded.
- `amtool check-config alertmanager.yaml` validates a file offline, including the templates it references.
- `amtool config routes show --config.file=alertmanager.yaml` prints the routing tree.
- `amtool config routes test --config.file=alertmanager.yaml service=probe severity=critical` prints the receiver the labels would reach.

The last two commands need no running server. They are the safe way to check a route change before it is deployed.

## Validating Before You Deploy

A syntax error in the Alertmanager file stops a starting instance and makes a reload fail. Run `amtool check-config` in the pipeline that renders the ConfigMap. It checks that the YAML parses, that every route names an existing receiver, that the regular expressions compile and that the templates parse. It does not check that a receiver URL works.

After deployment, read `GET /api/v2/status`. Its `config.original` field holds the text Alertmanager actually loaded. Compare it with the file you intended to deploy. A ConfigMap change reaches a pod after a delay, so a mismatch right after the edit can mean the pod has not yet seen the new file.

## Using The API From The Playground

The playground has no `amtool` binary on the host. The `shuttle` pod has Python, so the commands below call the API through it. Save this as `list-alerts.py`:

<!-- astrona:playground:renew -->

```python
import json, subprocess

code = 'import urllib.request; print(urllib.request.urlopen("http://alertmanager:9093/api/v2/alerts", timeout=8).read().decode())'
out = subprocess.run(['kubectl', '-n', 'starfleet', 'exec', 'shuttle', '--', 'python', '-c', code],
                     capture_output=True, text=True, timeout=30).stdout
for alert in json.loads(out):
    status = alert['status']
    print(alert['labels'].get('alertname'), status['state'], status['silencedBy'], status['inhibitedBy'])
```

Run it:

```sh
python3 list-alerts.py
```

Each printed line shows the alert name, its state and the silences and inhibiting alerts that suppress it. An empty list means Alertmanager holds no alerts at that moment. Alerts that Prometheus no longer sends expire after the resolve timeout.

## Reading Group Output

The groups endpoint answers a question the alert list cannot: which receiver is each alert going to? Each entry in the response has a `labels` object with the group labels, a `receiver` object with the receiver `name`, and an `alerts` list. Use it to confirm that a route change moved alerts to the receiver you intended, before you wait for a notification.

The `filter` query parameter on the alerts endpoint accepts the same matcher text as `amtool`, for example `filter=severity="critical"`. It can be given more than once, and all filters must match. The same parameter narrows the silences list, which helps when many silences exist.

Timestamps in the API use RFC 3339 format with a time zone, for example `2026-11-03T10:00:00Z`. A silence whose `endsAt` is earlier than `startsAt` is rejected, and so is a silence with no matchers.

## A Short Incident Routine

During an incident, three reads answer most questions. First, list the alerts that are active and read their `status` fields to see whether any are suppressed and why. Second, read the groups endpoint to see which receiver each group is going to. Third, list the active silences and read their `createdBy`, `comment` and `endsAt` fields to find any silence that matches the alert you are investigating.

If a notification is missing, the three answers narrow the cause. An alert that is not in the list never reached Alertmanager, which points at Prometheus or its `alerting` block. An alert that is suppressed was silenced or inhibited. An alert that is active, in a group with the right receiver, and still not delivered points at the receiver itself.

## Authentication And Access

Alertmanager has no built-in user accounts in its API. Access control comes from the network or from a reverse proxy, or from the web configuration file given with `--web.config.file`, which supports TLS and basic authentication. Because a silence can hide every alert, treat write access to the API as a privilege and keep it away from untrusted clients.

## Common pitfalls

> [!WARNING]
> `amtool` validates syntax, not delivery. A valid file can still route to a receiver that fails. A reload that fails leaves the old configuration running, so always confirm the loaded configuration through the status endpoint. Do not expose the Alertmanager API to untrusted networks.
