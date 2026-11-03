import json
import os
import subprocess
import tempfile
import time
import urllib.parse

PANELS = [
    {"title": "Request rate by status", "unit": "requests/s",
     "expression": "sum by (status) (rate(lab_requests_total[30s]))"},
    {"title": "Error ratio", "unit": "ratio",
     "expression": "sum(rate(lab_requests_total{status=\"500\"}[30s])) / sum(rate(lab_requests_total[30s]))"},
    {"title": "Request latency, 95th percentile", "unit": "seconds",
     "expression": "histogram_quantile(0.95, sum by (le) (rate(lab_request_duration_seconds_bucket[30s])))"},
    {"title": "Queue depth", "unit": "items",
     "expression": "lab_queue_depth"},
]

QUERY_SCRIPT = (
    "import sys,urllib.request;"
    "print(urllib.request.urlopen('http://prometheus:9090/api/v1/query?'+sys.argv[1],timeout=8).read().decode())"
)


def run(*args):
    result = subprocess.run(list(args), text=True, capture_output=True, timeout=30)
    if result.returncode != 0:
        raise SystemExit("Command failed: " + " ".join(args[:4]) + "\n" + result.stderr)
    return result.stdout.strip()


recorded = []
for panel in PANELS:
    evaluated_at = time.time()
    parameters = urllib.parse.urlencode({"query": panel["expression"], "time": evaluated_at})
    answer = json.loads(run("kubectl", "-n", "starfleet", "exec", "shuttle", "--", "python", "-c", QUERY_SCRIPT, parameters))
    if answer["status"] != "success" or not answer["data"]["result"]:
        raise SystemExit("No data for panel '" + panel["title"] + "'. Wait 30 seconds and run the script again.")
    recorded.append(dict(panel, evaluated_at=evaluated_at, data=answer["data"]))

resource = {
    "apiVersion": "v1",
    "kind": "ConfigMap",
    "metadata": {"name": "evidence", "namespace": "starfleet"},
    "data": {"report.json": json.dumps({"panels": recorded}, sort_keys=True)},
}
with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as handle:
    json.dump(resource, handle)
    path = handle.name
try:
    run("kubectl", "apply", "-f", path)
finally:
    os.unlink(path)
print("Saved", len(recorded), "panels")
