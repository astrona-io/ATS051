import json,subprocess,time,sys,tempfile,os

def call(*args):
 r=subprocess.run(list(args),text=True,capture_output=True,timeout=20)
 assert r.returncode==0, 'Observation command failed: '+args[0]
 return r.stdout.strip()
def obj(kind,name,ns='starfleet'):
 return json.loads(call('kubectl',*(['-n',ns] if ns else []),'get',kind,name,'-o','json'))
def api(path):
 script='import urllib.request; print(urllib.request.urlopen('+repr('http://prometheus:9090'+path)+',timeout=8).read().decode())'
 return json.loads(call('kubectl','-n','starfleet','exec','shuttle','--','python','-c',script))
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

messages=hooks()
assert any(m.get('receiver')=='warning-webhook' and any(a['labels'].get('alertname')=='ProbeErrors' and a['labels'].get('lab')=='delivery' for a in m.get('alerts',[])) for m in messages), 'Alert did not reach the selected receiver'
