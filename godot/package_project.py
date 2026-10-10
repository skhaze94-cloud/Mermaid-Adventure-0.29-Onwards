#!/usr/bin/env python3
"""Build and CRC-check a complete Godot ZIP, including explicit directories.
Works from a ZIP extraction or a checkout. Replace output only after validation.
"""
from pathlib import Path
import argparse, re, zipfile, os
root = Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser()
parser.add_argument('output', type=Path)
args = parser.parse_args()
files = {p.relative_to(root).as_posix() for p in (root/'godot').rglob('*') if p.is_file() and p.suffix not in {'.uid','.import','.gif','.jpg'} and '.godot' not in p.parts}
files.add('project.godot')
for name in list(files):
    if (root/name).suffix in {'.gd','.tscn','.tres','.godot','.gdshader'}:
        for resource in re.findall(r"[\"']res://(dist/[^\"'\s]+)[\"']", (root/name).read_text()):
            if not (root/resource).is_file():
                raise RuntimeError('Missing runtime asset: '+resource)
            files.add(resource)
notes = 'Sarah Maria — Mermaid Adventure | Godot v0.28 — Living Creatures\n\nExtract into a NEW EMPTY folder. Import the ROOT project.godot in Godot 4.3+.\nWait for import, then press F5. Begin adventure starts the family tutorial.\nChoose a chapter opens any of the eight levels directly.\n\nv0.28: the comprehensive enemy animation update.\nEach crab, eel, jellyfish, pufferfish, swordfish and shark now has 16 actual\njoint-motion clips, up from four portrait poses. Each clip has 96 intervals\nof sampled motion with seamless interpolation and smooth clip blending.\nA persistent 1,617-vertex skin bends the original painted creature itself:\n- Crab: both claw wrists, opposed pincer jaws and alternating walking legs.\n- Eel: articulated swimming spine and delayed tail flexion.\n- Jellyfish: bell contraction and independently lagging tentacle strands.\n- Pufferfish: inflation, tail kick and fin paddling.\n- Swordfish / shark: two tail hinges, pectoral paddle, dorsal fin and banking.\nCarlo, Duke Claw, Miguel, Flip, Baron Bite, Rana Rex, Nessie and the palace\nperformance use the same 16-clip system with species-specific articulation.\nCombat colors remain immediate. Animation never moves the collision root.\nPaused clocks stay still; Gentle Motion and Economy settings remain supported.\n\nThe complete v0.27 character update, family tutorial, Avina choices, chapter\nmenus, transitions and all eight levels are included.\nWASD/arrows: move. Space: Boost. J/Shift: Jump. B/Z: Bubble.\nP/Escape: pause. R: restart. Touch and controller controls included.\n\nValidated with Linux Godot 4.3: 24 automated suites, native chapter renders,\n16-second native animation preview, and fresh ZIP extraction/import.\nSee godot/LIVING-CREATURES-VALIDATION.md for scope and results.\n'
directories = {str(parent)+'/' for name in files for parent in Path(name).parents if str(parent)!='.'}
args.output.parent.mkdir(parents=True,exist_ok=True)
temporary = args.output.with_suffix('.zip.tmp')
with zipfile.ZipFile(temporary,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as archive:
    for directory in sorted(directories,key=lambda p:(p.count('/'),p)):
        archive.writestr(directory,b'')
    archive.writestr('START-HERE.txt',notes)
    for name in sorted(files): archive.write(root/name,name)
with zipfile.ZipFile(temporary) as archive:
    bad = archive.testzip()
    if bad: raise RuntimeError('CRC failure: '+bad)
os.replace(temporary,args.output)
print(f'{args.output}: {len(files)+1} files, {len(directories)} directories, {args.output.stat().st_size} bytes; CRC OK')
