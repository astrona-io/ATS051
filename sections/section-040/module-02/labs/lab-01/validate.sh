#!/usr/bin/env bash
set -euo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-051-lab-040-02-01" ]]; then
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

def main():
    rule = rule_index()['ErrorBudgetFastBurn']
    query = squash(rule['query'])
    require(rule['type'] == 'alerting' and rule['health'] == 'ok', 'ErrorBudgetFastBurn must be a healthy alerting rule')
    require('[30s]' in query and '[10s]' in query, 'Use a 30 second long window and a 10 second short window')
    require(')and(' in query, 'Join the two window conditions with and')
    require('14.4' in query or '0.0144' in query, 'The threshold is 14.4 times the budget of 0.001')
    require('status="500"' in query, 'Count the failing requests with status="500"')
    require(rule['duration'] <= 10, 'The for duration must be 10 seconds or less')
    require(rule['labels'].get('severity') == 'page', 'The severity label must be page')
    annotations = rule['annotations']
    require(annotations.get('summary'), 'The rule needs a summary annotation')
    require(str(annotations.get('runbook_url', '')).startswith('https://'), 'The runbook_url annotation must be an https address')
    require(rule['state'] == 'firing', 'The alert is not firing yet (state: ' + rule['state'] + ')')

run(main)
PY
