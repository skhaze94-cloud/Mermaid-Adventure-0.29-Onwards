#!/usr/bin/env python3
"""Validate directory entries, Godot extraction and fresh project startup."""
import argparse, pathlib, subprocess, tempfile, zipfile, hashlib, sys
root = pathlib.Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser()
parser.add_argument('--godot', default='godot')
parser.add_argument('--temp-dir', type=pathlib.Path, help='Optional writable directory for fresh-copy checks')
args = parser.parse_args()
def run(command):
    result = subprocess.run(command,cwd=root,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=90)
    if result.returncode or any(tag in result.stdout for tag in ['SCRIPT ERROR','Parse Error','Compile Error','\nERROR:']):
        raise RuntimeError(f'Exit {result.returncode}: '+result.stdout)
    return result.stdout
if args.temp_dir: args.temp_dir.mkdir(parents=True,exist_ok=True)
with tempfile.TemporaryDirectory(prefix='sarah-package-',dir=args.temp_dir) as temp:
    stage = pathlib.Path(temp)
    archive = stage/'ready.zip'
    run([sys.executable,str(root/'godot/package_project.py'),str(archive)])
    log = run([args.godot,'--headless','--path',str(root),'--script','res://godot/package_extraction_test.gd','--',str(archive),str(stage/'fresh')])
    assert 'GODOT PACKAGE EXTRACTION TEST PASSED' in log, log
    with zipfile.ZipFile(archive) as source:
        assert source.testzip() is None
        for name in source.namelist():
            if not name.endswith('/'):
                assert hashlib.sha256(source.read(name)).digest() == hashlib.sha256((stage/'fresh'/name).read_bytes()).digest(), name
    # Wait for all imports, rather than closing the editor during a slow scan.
    run([args.godot,'--headless','--editor','--path',str(stage/'fresh'),'--import'])
    run([args.godot,'--headless','--path',str(stage/'fresh'),'--quit-after','16'])
    for suite in ['sarah_arm_review_test.gd', 'sarah_torso_motion_test.gd', 'sarah_definitive_review_test.gd', 'sarah_definitive_test.gd', 'sarah_spine_motion_test.gd', 'sarah_face_details_test.gd', 'sarah_ultimate_test.gd', 'complete_adventure_test.gd']:
        print(run([args.godot,'--headless','--path',str(stage/'fresh'),'--max-fps','60','--script','res://godot/'+suite]).strip())
    print(log.strip())
    print('GODOT FRESH PACKAGE IMPORT TEST PASSED')
