#!/usr/bin/env python3
"""Archive the complete source and artwork; validate CRC before replacement."""
from pathlib import Path
import argparse,os,re,zipfile,hashlib,json
root=Path(__file__).resolve().parent.parent
parser=argparse.ArgumentParser();parser.add_argument('output',type=Path);args=parser.parse_args()
output=args.output.resolve();temporary=output.with_suffix('.zip.tmp')
manifest=root/'ASSET-PARTS.json'
if manifest.exists():
    for item in json.loads(manifest.read_text()):
        target=root/item['target']
        if not target.is_file() or target.stat().st_size!=item['bytes'] or hashlib.sha256(target.read_bytes()).hexdigest()!=item['sha256']:
            raise SystemExit('Run python restore_original_assets.py before packaging source')

files=[]
for p in sorted(root.rglob('*')):
    if not p.is_file():continue
    relative=p.relative_to(root);parts=relative.parts
    if parts[0]=='archive-parts':continue
    if any(x in {'.godot','.git','node_modules','__pycache__'} for x in parts):continue
    if p.name.startswith('.') and p.name not in {'.gdignore','.gitignore'}:continue
    if p.resolve() in {output,temporary}:continue
    if p.suffix.lower() in {'.exe','.apk','.pck','.zip','.tmp','.idsig'}:continue
    if parts[0]=='verification':
        if len(parts)<2 or parts[1]!='connected36':continue
        # Full native comparisons are embedded in the portable HTML review.
        if p.suffix.lower() in {'.png','.jpg','.webp'}:continue
    if p.suffix=='.log' and parts[0]!='verification':continue
    files.append((p,relative))
output.parent.mkdir(parents=True,exist_ok=True)
with zipfile.ZipFile(temporary,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
    directories={str(parent)+'/' for _,r in files for parent in r.parents if str(parent)!='.'}
    for directory in sorted(directories):z.writestr(directory,b'')
    for p,relative in files:
        if p.name=='export_presets.cfg':
            z.writestr(str(relative),re.sub(r'^(custom_template/[^=]+|keystore/[^=]+)=.*$',r'\1=""',p.read_text(),flags=re.M))
        else:z.write(p,str(relative))
with zipfile.ZipFile(temporary) as z:
    bad=z.testzip()
    if bad:raise RuntimeError('CRC failure: '+bad)
os.replace(temporary,output)
print(output,len(files),'files,',output.stat().st_size,'bytes; CRC OK')
