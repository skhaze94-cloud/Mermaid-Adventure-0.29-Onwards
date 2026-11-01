from pathlib import Path
import json,hashlib,os
root=Path(__file__).resolve().parent
for item in json.loads((root/'ASSET-PARTS.json').read_text()):
 target=root/item['target'];target.parent.mkdir(parents=True,exist_ok=True)
 if target.exists():
  if target.stat().st_size==item['bytes'] and hashlib.sha256(target.read_bytes()).hexdigest()==item['sha256']:
   print('Already restored',item['target']);continue
  raise SystemExit(str(target)+' differs from the release; move it aside before restoring.')
 temporary=target.with_suffix(target.suffix+'.restore.tmp');digest=hashlib.sha256();size=0
 try:
  with temporary.open('wb') as out:
   for part in item['parts']:
    with (root/part).open('rb') as src:
     while block:=src.read(1024*1024):out.write(block);digest.update(block);size+=len(block)
  if size!=item['bytes'] or digest.hexdigest()!=item['sha256']:raise ValueError('Asset verification failed: '+item['target'])
  os.replace(temporary,target);print('Restored',item['target'])
 finally:
  if temporary.exists():temporary.unlink()
