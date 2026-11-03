#!/usr/bin/env bash
set -euo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-051-lab-030-cap-01" ]]; then
  printf 'Refusing to operate on another Kubernetes context\n' >&2
  exit 1
fi
python3 - <<'PY'
import json
import subprocess
import sys
import time
import urllib.parse

HTTP_SCRIPT = (
    "import json,sys,urllib.request\n"
    "body=json.loads(sys.argv[2]) if len(sys.argv)>2 else None\n"
    "data=json.dumps(body).encode() if body is not None else None\n"
    "request=urllib.request.Request(sys.argv[1],data=data,headers={'Content-Type':'application/json'})\n"
    "print(urllib.request.urlopen(request,timeout=8).read().decode())\n"
)


def call(*args):
    result = subprocess.run(list(args), text=True, capture_output=True, timeout=40)
    assert result.returncode == 0, 'Command failed: ' + ' '.join(args[:5])
    return result.stdout.strip()


def http_json(url, body=None):
    arguments = [url] + ([json.dumps(body)] if body is not None else [])
    text = call('kubectl', '-n', 'starfleet', 'exec', 'shuttle', '--', 'python', '-c', HTTP_SCRIPT, *arguments)
    return json.loads(text) if text else None


def prometheus(path):
    return http_json('http://prometheus:9090' + path)


def prometheus_query(expression, at=None):
    parameters = {'query': expression}
    if at is not None:
        parameters['time'] = at
    return prometheus('/api/v1/query?' + urllib.parse.urlencode(parameters))


def alertmanager(path, body=None):
    return http_json('http://alertmanager:9093' + path, body)


def hook_messages():
    return http_json('http://probe:8080/hooks')


def evidence():
    text = call('kubectl', '-n', 'starfleet', 'get', 'configmap', 'evidence', '-o', 'json')
    return json.loads(json.loads(text)['data']['report.json'])


def squash(text):
    return ''.join(str(text).split())


def rule_index():
    groups = prometheus('/api/v1/rules')['data']['groups']
    return {rule['name']: dict(rule, group=group['name'], position=position)
            for group in groups for position, rule in enumerate(group['rules'])}


def require(condition, message):
    if not condition:
        raise AssertionError(message)


def run(main):
    try:
        main()
    except (AssertionError, KeyError, ValueError, IndexError, subprocess.SubprocessError) as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
    print('Required result verified')

from datetime import datetime, timedelta, timezone


def fixture(run, alertname, severity, service, instance):
    now = datetime.now(timezone.utc)
    return {
        'labels': {'alertname': alertname, 'severity': severity, 'service': service, 'instance': instance, 'run': run},
        'annotations': {'summary': 'Grader fixture'},
        'startsAt': now.isoformat(),
        'endsAt': (now + timedelta(minutes=5)).isoformat(),
    }


def messages_for(run):
    return [m for m in hook_messages() if any(a['labels'].get('run') == run for a in m['alerts'])]


def main():
    run = str(int(time.time()))
    alertmanager('/api/v2/alerts', [
        fixture(run, 'ProbeDown', 'critical', 'probe', 'a'),
        fixture(run, 'ProbeDown', 'critical', 'probe', 'b'),
        fixture(run, 'ProbeSlow', 'warning', 'probe', 'a'),
        fixture(run, 'ProbeSlow', 'warning', 'other', 'c'),
    ])
    messages = []
    for attempt in range(15):
        time.sleep(2)
        messages = messages_for(run)
        if len(messages) >= 2:
            break
    require(messages, 'No notification reached a webhook receiver')
    pager = [m for m in messages if m['receiver'] == 'pager']
    require(len(pager) == 1, 'The critical alerts must arrive in exactly one notification to the pager receiver')
    require(len(pager[0]['alerts']) == 2, 'The pager notification must group both critical alerts')
    require(pager[0]['groupLabels'] == {'alertname': 'ProbeDown', 'service': 'probe'}, 'Group by alertname and service')
    for message in messages:
        for alert in message['alerts']:
            if alert['labels'].get('run') == run and alert['labels']['alertname'] == 'ProbeSlow':
                require(alert['labels']['service'] != 'probe', 'The warning for the failing service must be inhibited')
    default = [m for m in messages if m['receiver'] == 'default']
    require(default and any(a['labels']['service'] == 'other' for m in default for a in m['alerts']),
            'The warning for the other service must go to the default receiver')

run(main)
PY
