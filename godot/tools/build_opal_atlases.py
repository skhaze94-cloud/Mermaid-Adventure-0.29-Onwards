#!/usr/bin/env python3
"""Measured alpha-island export; masters are retained unchanged. No game art resizing.
Pillow, numpy and scipy are developer export dependencies, never game dependencies.
"""
from pathlib import Path
import hashlib,json
import numpy as np
from PIL import Image
from scipy import ndimage
ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'godot/art-source/opal-current';OUT=ROOT/'godot/assets/opal-current'
NAMES={'friendly-production':['pearl','prism','aurora','little'],
 'core-production':['crab','eel','jelly','puffer','swordfish','shark'],
 'lagoon-production':['maraca','ribbon','otter','orchid','drum','disco'],
 'boss-a-production':['carlo','duke','flip','miguel','palace','rana'],
 'boss-b-production':['nessie','training','king-cloud','king-wave','king-beard','rana-ring']}
GROUPS={'friendly':NAMES['friendly-production'],'enemies':NAMES['core-production'],'lagoon':NAMES['lagoon-production'],
 'carlo':['carlo'],'shadow':['duke','flip'],'miguel':['miguel'],'palace':['palace'],'rana':['rana','rana-ring'],
 'nessie':['nessie'],'training':['training','king-cloud','king-wave','king-beard']}
manifest={'version':1,'gutters_px':16,'source_alpha':'straight','mipmaps':False,
 'source_note':'New imagegen production effect masters. Existing character/scene/audio/animation assets untouched.',
 'atlases':{},'frames':{},'aliases':{'blackwater':'shark'}}
sprites={};OUT.mkdir(parents=True,exist_ok=True)
for filename,names in NAMES.items():
 path=SOURCE/(filename+'.png');image=Image.open(path).convert('RGBA');rgba=np.asarray(image);alpha=rgba[:,:,3]
 labels,count=ndimage.label(alpha>24);areas=np.bincount(labels.ravel())
 major=sorted(range(1,count+1),key=lambda i:areas[i],reverse=True)[:len(names)]
 if any(areas[i]<8000 for i in major):raise RuntimeError('Missing major effect '+filename)
 centroids=ndimage.center_of_mass(alpha,labels,major)
 ordered=sorted(zip(major,centroids),key=lambda z:z[1][0])
 ordered=[x for k in range(0,len(ordered),2) for x in sorted(ordered[k:k+2],key=lambda z:z[1][1])]
 roots=np.zeros(labels.shape,dtype=np.int16)
 for index,(label,_) in enumerate(ordered,1):roots[labels==label]=index
 nearest=ndimage.distance_transform_edt(roots==0,return_distances=False,return_indices=True);ownership=roots[tuple(nearest)]
 for index,(name,(label,centre)) in enumerate(zip(names,ordered),1):
  owned=ownership==index;ys,xs=np.where(owned & (alpha>8))
  left=max(0,int(xs.min())-8);right=min(image.width,int(xs.max())+9)
  top=max(0,int(ys.min())-8);bottom=min(image.height,int(ys.max())+9)
  pixels=rgba[top:bottom,left:right].copy();pixels[:,:,3]=np.where(owned[top:bottom,left:right],pixels[:,:,3],0)
  sprite=Image.fromarray(pixels);source_size=sprite.size
  limit=384 if name in ['aurora','king-cloud','king-wave','rana-ring'] else 192 if name=='little' else 256
  if max(sprite.size)>limit:
   factor=limit/max(sprite.size);sprite=sprite.resize(tuple(max(1,round(x*factor)) for x in sprite.size),Image.Resampling.LANCZOS)
  sprites[name]=sprite
  manifest['frames'][name]={'source':filename+'.png','source_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),
   'source_region':[left,top,right-left,bottom-top],'source_canvas':list(image.size),'source_crop_size':list(source_size),
   'export_size':list(sprite.size),'pivot':[sprite.width/2,sprite.height/2],
   'native_heading_degrees':-50 if name=='training' else -28 if name=='rana' else 0,
   'max_gameplay_extent':76 if name=='aurora' else 155 if name=='king-cloud' else 200 if name in ['king-wave','rana-ring'] else 72,
   'alpha_edges':'Measured alpha ownership; 8 px source halo; complete subjects; separate neighbours'}
for group,names in GROUPS.items():
 width=576 if group in ['enemies','lagoon','shadow'] else 768 if group in ['friendly','training','rana'] else 320
 if group in ['enemies','lagoon']:names=sorted(names,key=lambda name:-sprites[name].height)
 slots=[];x=y=row_h=0
 for name in names:
  im=sprites[name];w,h=im.width+32,im.height+32
  if x+w>width:x=0;y+=row_h;row_h=0
  slots.append((name,x+16,y+16));x+=w;row_h=max(row_h,h)
 height=y+row_h;width=max(x+sprites[name].width+16 for name,x,y in slots)
 atlas=Image.new('RGBA',(width,height),(0,0,0,0))
 for name,x,y in slots:
  im=sprites[name];atlas.paste(im,(x,y))
  pad=np.pad(np.asarray(im),((16,16),(16,16),(0,0)),mode='edge').copy()
  pad[:16,:,3]=0;pad[-16:,:,3]=0;pad[:,:16,3]=0;pad[:,-16:,3]=0
  atlas.paste(Image.fromarray(pad),(x-16,y-16));manifest['frames'][name].update(atlas=group,region=[x,y,im.width,im.height])
 atlas.save(OUT/(group+'.png'),optimize=True)
 manifest['atlases'][group]={'file':group+'.png','size':list(atlas.size),'rgba_bytes':atlas.width*atlas.height*4,
  'sha256':hashlib.sha256((OUT/(group+'.png')).read_bytes()).hexdigest()}
manifest['residency_MiB']={key:round(sum(manifest['atlases'][g]['rgba_bytes'] for g in ['friendly','lagoon' if key=='miguel' else 'enemies']+([key] if key in GROUPS else []))/1048576,3) for key in ['carlo','shadow','miguel','palace','rana','nessie','blackwater','training']}
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('Exported',len(sprites),'effects into',len(GROUPS),'atlases',manifest['residency_MiB'])
