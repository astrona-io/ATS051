---
draft: true
exam_objectives:
- Understand and Use Alertmanager
---
# Route An Alert To A Webhook Solution

Use a host shell with the private kubeconfig for this independent kind environment. A kubeconfig identifies the cluster and credentials used by kubectl, the Kubernetes command-line tool.

```sh
export KUBECONFIG="$(astrona kubeconfig ats-051-lab-030-01-02)"
test "$(kubectl config current-context)" = "kind-astro-ats-051-lab-030-01-02" || exit 1
node_name="astro-ats-051-lab-030-01-02-control-plane"
worker_name="astro-ats-051-lab-030-01-02-worker"
```

Keep this connection selected. Host-level commands name only this environment's node containers. They do not operate on the host operating system.

## Inspect And Explain

One instrumented probe serves metrics and structured request logs. A traffic generator makes ten percent of requests fail. Prometheus scrapes every two seconds; no evidence report or learner rule exists.

Inspect the current objects before changing them:

```sh
kubectl -n starfleet get pods -o wide
kubectl get nodes -o wide
```

Configure the warning route and a real webhook receiver. Submit a fixture alert directly to Alertmanager, then inspect receiver observations. This exercises Alertmanager independently; Prometheus rule evaluation is covered by the other labs.

Save this as `configmap-alertmanager-config.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: alertmanager-config
  namespace: starfleet
data:
  alertmanager.yaml: "global:\n  resolve_timeout: 1m\nreceivers:\n- name: discard\n\
    - name: warning-webhook\n  webhook_configs:\n  - send_resolved: true\n    url:\
    \ http://probe:8080/hooks\nroute:\n  group_by:\n  - alertname\n  - lab\n  group_interval:\
    \ 2s\n  group_wait: 0s\n  receiver: discard\n  repeat_interval: 1m\n  routes:\n\
    \  - matchers:\n    - severity=\"warning\"\n    receiver: warning-webhook\n"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: alertmanager
  namespace: starfleet
spec:
  replicas: 1
  selector:
    matchLabels:
      app: alertmanager
  template:
    metadata:
      labels:
        app: alertmanager
    spec:
      containers:
      - name: alertmanager
        image: quay.io/prometheus/alertmanager:v0.32.1
        ports:
        - containerPort: 9093
        args:
        - --config.file=/config/alertmanager.yaml
        - --storage.path=/alertmanager
        volumeMounts:
        - name: config
          mountPath: /config
        - name: storage
          mountPath: /alertmanager
      volumes:
      - name: config
        configMap:
          name: alertmanager-config
      - name: storage
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: alertmanager
  namespace: starfleet
spec:
  selector:
    app: alertmanager
  ports:
  - port: 9093
    targetPort: 9093
```

Save this as `send-alert.py`:

```python
import json,subprocess,time,sys,tempfile,os

def call(*args):
 r=subprocess.run(list(args),text=True,capture_output=True,timeout=20)
 assert r.returncode==0, 'Observation command failed: '+args[0]
 return r.stdout.strip()
def obj(kind,name,ns='starfleet'):
 return json.loads(call('kubectl',*(['-n',ns] if ns else []),'get',kind,name,'-o','json'))
def api(path):
 script='import urllib.request; print(urllib.request.urlopen('+repr('http://prometheus:9090'+path)+',timeout=8).read().decode())'
 text=call('kubectl','-n','starfleet','exec','shuttle','--','python','-c',script)
 return json.loads(text) if text else None
def save(data):
 resource={'apiVersion':'v1','kind':'ConfigMap','metadata':{'name':'evidence','namespace':'starfleet'},'data':{'report.json':json.dumps(data,sort_keys=True)}}
 with tempfile.NamedTemporaryFile(mode='w',suffix='.json',delete=False) as f:json.dump(resource,f);path=f.name
 try:call('kubectl','apply','-f',path)
 finally:os.unlink(path)

def am(path,body=None):
 script='import urllib.request,json; body='+repr(body)+'; r=urllib.request.Request('+repr('http://alertmanager:9093'+path)+',data=json.dumps(body).encode() if body is not None else None,headers={"Content-Type":"application/json"}); print(urllib.request.urlopen(r,timeout=5).read().decode())'
 return json.loads(call('kubectl','-n','starfleet','exec','shuttle','--','python','-c',script))
def hooks():
 script='import urllib.request; print(urllib.request.urlopen("http://probe:8080/hooks",timeout=5).read().decode())'
 return json.loads(call('kubectl','-n','starfleet','exec','shuttle','--','python','-c',script))

assert call('kubectl','config','current-context')=='kind-astro-ats-051-lab-030-01-02'
from datetime import datetime,timezone,timedelta
now=datetime.now(timezone.utc)
am('/api/v2/alerts',[{'labels':{'alertname':'ProbeErrors','severity':'warning','lab':'delivery'},'annotations':{'summary':'Fixture warning'},'startsAt':now.isoformat(),'endsAt':(now+timedelta(hours=1)).isoformat()}])
```

Apply the scoped correction:

```sh
kubectl apply -f configmap-alertmanager-config.yaml
```

## Verify The Result

Observe the actual result. A denied request returns a nonzero status when the denial works, so run it separately from a shell sequence that stops on error. Status convergence and a successful request establish different parts of the result.

```sh
kubectl -n starfleet rollout status deployment/alertmanager --timeout=180s
python3 "$solution_directory/send-alert.py"
sleep 6
```

Verify real Alertmanager routing to a receiver. The commands above deliberately target one environment. Keep its remaining components available so an unrelated failure cannot stand in for the required denial or correction. No example command output is presented as evidence of a completed run. A matching field alone does not establish that a process used it or that a controller reconciled it.

After recording your result, remove the independent lab with `astrona destroy ats-051-lab-030-01-02`.

## Common pitfalls

> [!WARNING]
> Confirm the private context and exact node names before a change. Check the stated scope and live result. Do not change unrelated components to hide the original fault.
