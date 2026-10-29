#!/usr/bin/env python3
"""Validate directory entries, Godot extraction and fresh project startup."""
import argparse, os, pathlib, subprocess, tempfile, zipfile, hashlib, sys, shutil
root = pathlib.Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser()
parser.add_argument('--godot', default='godot')
parser.add_argument('--temp-dir', type=pathlib.Path, help='Optional writable directory for fresh-copy checks')
args = parser.parse_args()
def run(command):
    with tempfile.TemporaryDirectory(prefix='mermaid-package-user-') as user_data:
        env=os.environ.copy()
        env.update(XDG_DATA_HOME=user_data,SARAH_DISABLE_SAVES='1')
        result = subprocess.run(command,env=env,cwd=root,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=240)
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
    suites = ['visual_polish_test.gd','gameplay_controls_test.gd','environment_visuals_test.gd','family_layout_test.gd','complete_adventure_test.gd','scoring_ui_test.gd','title_flow_test.gd','scene_flow_test.gd','sarah_princess_test.gd','sarah_breaststroke_test.gd','jump_animation_test.gd','opal_current_test.gd','adventure_polish_test.gd','bubble_polish_test.gd','boss_polish_test.gd','opening_journey_test.gd','journey_flow_test.gd','journey_effects_test.gd','whimsy_test.gd']
    # Developer checks are copied into the temporary extraction only.
    # The playable ZIP has no captures, tests or historical reports.
    for suite in suites:
        shutil.copyfile(root/'godot'/suite,stage/'fresh/godot'/suite)
        print(run([args.godot,'--headless','--path',str(stage/'fresh'),'--max-fps','60','--script','res://godot/'+suite]).strip(),flush=True)
    print(log.strip())
    print('GODOT FRESH PACKAGE IMPORT TEST PASSED')
