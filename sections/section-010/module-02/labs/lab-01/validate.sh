#!/usr/bin/env bash
set -euo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-051-lab-010-02-01" ]]; then
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

EXPECTED = squash('histogram_quantile(0.95, sum by (le) (rate(lab_request_duration_seconds_bucket[30s])))')


def main():
    report = evidence()
    require(squash(report['expression']) == EXPECTED, 'The expression must be the 95th percentile of the 30 second histogram bucket rate, aggregated by le only')
    require(report.get('unit') == 'seconds', 'The unit must be seconds')
    require(str(report.get('title', '')).strip(), 'The panel needs a title')
    require(0 <= time.time() - float(report['evaluated_at']) <= 300, 'Record the evidence again: it must be less than five minutes old')
    fresh = prometheus_query(report['expression'], report['evaluated_at'])
    require(fresh['status'] == 'success' and fresh['data']['result'], 'The expression returns no series')
    value = fresh['data']['result'][0]['value'][1]
    require(value != 'NaN', 'The quantile is NaN: the histogram has no recent traffic')
    require(report['data'] == fresh['data'], 'The recorded data differs from the live API result')

run(main)
PY
