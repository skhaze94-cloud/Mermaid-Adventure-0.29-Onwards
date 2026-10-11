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
LEGACY_UI = {'joystick','thumb','jump','boost','pause','settings','home','restart','bubble','chest','ribbon'}
RUNTIME_SUFFIXES = {'.gd','.tscn','.tres','.gdshader','.json','.png','.webp','.wav','.ogg','.mp3','.ttf','.otf'}
def runtime_file(p):
    relative = p.relative_to(root/'godot')
    if p.suffix not in RUNTIME_SUFFIXES or not p.is_file(): return False
    if any(x in {'.godot','device-qa'} or 'previews' in x for x in relative.parts): return False
    if p.name.startswith(('capture_','validation-')) or p.name.endswith('_test.gd'): return False
    if relative.parent.as_posix() == 'assets/ui-v014' and p.stem in LEGACY_UI: return False
    return True
files = {p.relative_to(root).as_posix() for p in (root/'godot').rglob('*') if runtime_file(p)}
files.add('project.godot')
for name in list(files):
    if (root/name).suffix in {'.gd','.tscn','.tres','.godot','.gdshader'}:
        for resource in re.findall(r"[\"']res://(dist/[^\"'\s]+)[\"']", (root/name).read_text()):
            if not (root/resource).is_file():
                raise RuntimeError('Missing runtime asset: '+resource)
            files.add(resource)
notes = (root/'START-HERE.txt').read_text(encoding='utf-8')
files.add('README.md')
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
