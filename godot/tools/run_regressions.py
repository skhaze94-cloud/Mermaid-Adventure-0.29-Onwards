#!/usr/bin/env python3
"""Run all native game suites and fail on engine errors, even with a zero exit code."""
import argparse,json,pathlib,subprocess,time
p=argparse.ArgumentParser()
p.add_argument('--godot',required=True)
p.add_argument('--output',type=pathlib.Path,required=True)
p.add_argument('--only',nargs='+',help='Rerun selected suites while retaining other recorded results')
a=p.parse_args()
root=pathlib.Path(__file__).resolve().parents[2]
a.output.mkdir(parents=True,exist_ok=True)
results=[]
if a.only and (a.output/'regressions.json').exists():
    results=json.loads((a.output/'regressions.json').read_text())
for suite in sorted((root/'godot').glob('*_test.gd')):
    if suite.name=='package_extraction_test.gd':continue  # Needs archive/extraction arguments; package_validation.py owns it.
    if a.only and suite.name not in a.only:continue
    start=time.monotonic()
    command=[a.godot,'--headless','--path',str(root),'--max-fps','60','--script','res://godot/'+suite.name]
    try:
        run=subprocess.run(command,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=600)
        output=run.stdout
        passed=run.returncode==0 and not any(marker in output for marker in ['SCRIPT ERROR','Parse Error','Compile Error','\nERROR:'])
        code=run.returncode
    except subprocess.TimeoutExpired as error:
        output=str(error.stdout or '')+'\nTIMEOUT';passed=False;code=-1
    (a.output/(suite.stem+'.log')).write_text(output)
    result={'test':suite.name,'passed':passed,'seconds':round(time.monotonic()-start,3),'exit_code':code,'tail':'\n'.join(output.strip().splitlines()[-3:])}
    results=[r for r in results if r['test']!=suite.name]+[result]
    results.sort(key=lambda r:r['test'])
    (a.output/'regressions.json').write_text(json.dumps(results,indent=2)+'\n')
    print(('PASS' if passed else 'FAIL'),suite.name,result['seconds'],result['tail'],flush=True)
print(f'{sum(r["passed"] for r in results)}/{len(results)} native regression suites passed',flush=True)
raise SystemExit(0 if all(r['passed'] for r in results) else 1)
