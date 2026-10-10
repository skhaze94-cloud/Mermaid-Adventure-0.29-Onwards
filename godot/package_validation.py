#!/usr/bin/env python3
"""Validate directory entries, Godot extraction and fresh project startup."""
import argparse, pathlib, subprocess, tempfile, zipfile, hashlib
root = pathlib.Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser()
parser.add_argument('--godot', default='godot')
args = parser.parse_args()
def run(command):
    result = subprocess.run(command,cwd=root,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=90)
    if result.returncode or any(tag in result.stdout for tag in ['SCRIPT ERROR','Parse Error','Compile Error','\nERROR:']):
        raise RuntimeError(f'Exit {result.returncode}: '+result.stdout)
    return result.stdout
with tempfile.TemporaryDirectory(prefix='sarah-package-') as temp:
    stage = pathlib.Path(temp)
    archive = stage/'ready.zip'
    run(['python3',str(root/'godot/package_project.py'),str(archive)])
    broken = stage/'old-layout.zip'
    with zipfile.ZipFile(archive) as source, zipfile.ZipFile(broken,'w') as target:
        for name in source.namelist():
            if not name.endswith('/'):
                target.writestr('OldWrapper/'+name,source.read(name))
    log = run([args.godot,'--headless','--path',str(root),'--script','res://godot/package_extraction_test.gd','--quit-after','240','--',str(broken),str(stage/'broken'),str(archive),str(stage/'fresh')])
    assert 'GODOT PACKAGE EXTRACTION TEST PASSED' in log, log
    with zipfile.ZipFile(archive) as source:
        assert source.testzip() is None
        for name in source.namelist():
            if not name.endswith('/'):
                assert hashlib.sha256(source.read(name)).digest() == hashlib.sha256((stage/'fresh'/name).read_bytes()).digest(), name
    # A settled editor avoids the 4.4.1 immediate-import shutdown race.
    # Startup below still rejects missing imports and script/resource errors.
    run([args.godot,'--headless','--editor','--max-fps','60','--path',str(stage/'fresh'),'--quit-after','600'])
    run([args.godot,'--headless','--path',str(stage/'fresh'),'--quit-after','16'])
    print(log.strip())
    print('GODOT FRESH PACKAGE IMPORT TEST PASSED')
