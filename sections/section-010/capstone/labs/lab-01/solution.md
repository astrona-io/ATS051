---
draft: true
exam_objectives:
- Dashboarding basics
---
# Dashboarding Basics Capstone Solution

Select the private kubeconfig of the lab first:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-051-lab-010-cap-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-051-lab-010-cap-01" || exit 1
```

## Choose the four expressions

Each panel answers one question. Traffic needs a rate, because `lab_requests_total` is a counter that only grows. Errors need a ratio of two rates, so the numerator and the denominator use the same window. Duration needs `histogram_quantile()` over bucket rates, and the aggregation must keep `le`. Saturation is a gauge, so you query it directly with no `rate()`.

```text
sum by (status) (rate(lab_requests_total[30s]))
sum(rate(lab_requests_total{status="500"}[30s])) / sum(rate(lab_requests_total[30s]))
histogram_quantile(0.95, sum by (le) (rate(lab_request_duration_seconds_bucket[30s])))
lab_queue_depth
```

## Record the evidence

The script below evaluates the four expressions through the `shuttle` pod and saves the responses in the `evidence` ConfigMap. Save this as `record_dashboard.py`:

```python
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
```

Run it:

```sh
python3 record_dashboard.py
```

If the script reports missing data, wait 30 seconds and run it again.

## Check the result

```sh
kubectl -n starfleet get configmap evidence -o jsonpath='{.data.report\.json}'
```

The output is one JSON object with a `panels` list of four entries.

## Common pitfalls

> [!WARNING]
> A ratio of rates with different windows gives a wrong number. Do not wrap the gauge in `rate()`. Do not save only the printed values: the grader compares the whole `data` object of each panel.
