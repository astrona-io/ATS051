#!/usr/bin/env bash
set -euo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-051-lab-020-cap-01" ]]; then
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

RECORDED = 'service:lab_requests:rate10s'


def main():
    rules = rule_index()
    record = rules[RECORDED]
    alert = rules['ProbeErrorRatioHigh']
    require(record['type'] == 'recording' and record['health'] == 'ok', 'The recording rule is missing or unhealthy')
    require(alert['type'] == 'alerting' and alert['health'] == 'ok', 'The alerting rule is missing or unhealthy')
    require(squash(record['query']) == squash('sum by (service, status) (rate(lab_requests_total[10s]))'), 'The recording rule expression is not the requested one')
    require(record['group'] == alert['group'], 'Both rules must be in the same group')
    require(record['position'] < alert['position'], 'The recording rule must come before the alert in the group')
    require(RECORDED in alert['query'], 'The alert must use the recorded series')
    require('lab_requests_total' not in alert['query'], 'The alert must not read the raw counter')
    series = prometheus_query(RECORDED)['data']['result']
    require(series and all('status' in item['metric'] for item in series), 'The recorded series has no data or lost the status label')
    require(alert['duration'] <= 10, 'The for duration must be 10 seconds or less')
    require(alert['labels'].get('severity') == 'critical', 'The severity label must be critical')
    require(alert['annotations'].get('summary'), 'The alert needs a summary annotation')
    require(alert['state'] == 'firing', 'The alert is not firing yet (state: ' + alert['state'] + ')')

run(main)
PY
