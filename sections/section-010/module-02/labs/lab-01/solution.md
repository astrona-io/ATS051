---
draft: true
exam_objectives:
- Dashboarding basics
---
# Build A Latency Panel Query Solution

Select the private kubeconfig of the lab first:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-051-lab-010-02-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-051-lab-010-02-01" || exit 1
```

## Write the expression

A histogram exposes one cumulative counter per bucket, labelled with the upper bound `le`. To get a quantile you first turn the bucket counters into per-second rates with `rate()`. You then add the rates of all series that share the same `le` value with `sum by (le)`. Last, `histogram_quantile()` estimates the quantile from the rates of the buckets.

```text
histogram_quantile(0.95, sum by (le) (rate(lab_request_duration_seconds_bucket[30s])))
```

The aggregation must keep `le`. If you drop it, `histogram_quantile()` has no bucket boundaries and returns no result.

## Record the evidence

The script below sends the query to Prometheus through the `shuttle` pod, then saves the response in the `evidence` ConfigMap. Save this as `record_panel.py`:

```python
import json
import os
import subprocess
import tempfile
import time
import urllib.parse

TITLE = "Request latency, 95th percentile"
UNIT = "seconds"
EXPRESSION = "histogram_quantile(0.95, sum by (le) (rate(lab_request_duration_seconds_bucket[30s])))"

QUERY_SCRIPT = (
    "import sys,urllib.request;"
    "print(urllib.request.urlopen('http://prometheus:9090/api/v1/query?'+sys.argv[1],timeout=8).read().decode())"
)


def run(*args):
    result = subprocess.run(list(args), text=True, capture_output=True, timeout=30)
    if result.returncode != 0:
        raise SystemExit("Command failed: " + " ".join(args[:4]) + "\n" + result.stderr)
    return result.stdout.strip()


evaluated_at = time.time()
parameters = urllib.parse.urlencode({"query": EXPRESSION, "time": evaluated_at})
answer = json.loads(run("kubectl", "-n", "starfleet", "exec", "shuttle", "--", "python", "-c", QUERY_SCRIPT, parameters))
if answer["status"] != "success" or not answer["data"]["result"]:
    raise SystemExit("No data yet. Wait 30 seconds and run the script again.")

report = {"title": TITLE, "unit": UNIT, "expression": EXPRESSION, "evaluated_at": evaluated_at, "data": answer["data"]}
resource = {
    "apiVersion": "v1",
    "kind": "ConfigMap",
    "metadata": {"name": "evidence", "namespace": "starfleet"},
    "data": {"report.json": json.dumps(report, sort_keys=True)},
}
with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as handle:
    json.dump(resource, handle)
    path = handle.name
try:
    run("kubectl", "apply", "-f", path)
finally:
    os.unlink(path)
print("Saved evidence for", TITLE)
```

Run it:

```sh
python3 record_panel.py
```

If the script says there is no data yet, wait 30 seconds and run it again.

## Check the result

```sh
kubectl -n starfleet get configmap evidence -o jsonpath='{.data.report\.json}'
```

The output is one JSON object with the fields `title`, `unit`, `expression`, `evaluated_at` and `data`.

## Common pitfalls

> [!WARNING]
> Do not save only the printed value. The grader compares the whole `data` object. Do not change the unit: the buckets are in seconds. A window shorter than the scrape interval gives an empty result.
