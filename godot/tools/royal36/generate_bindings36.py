"""Author conservative 4-influence skins against the production imported vertex order.
Original GLBs are never modified. Masks are authored in measured +Y-up/+Z-front space.
"""
from pathlib import Path
import numpy as np, json, hashlib, struct
SCRIPT=Path(__file__).resolve()
PROJECT=next((p for p in SCRIPT.parents if (p/'project.godot').exists()),SCRIPT.parents[2]/'connected36')
ROOT=PROJECT.parent
OUT=PROJECT/'godot/assets/royal-connected36';OUT.mkdir(parents=True,exist_ok=True)
def smooth(a,b,x):
 t=np.clip((x-a)/(b-a),0,1);return t*t*(3-2*t)
def capsule(v,a,b):
 a=np.array(a);b=np.array(b);d=b-a;t=np.clip(np.sum((v-a)*d,axis=1)/np.dot(d,d),0,1)
 return np.linalg.norm(v-a-t[:,None]*d,axis=1),t
for role in ['king','queen']:
 v=np.fromfile(ROOT/'audit36/royals'/f'{role}-godot-vertices.bin',dtype='<f4').reshape(-1,3);x,y,z=v.T;n=len(v)
 king=role=='king'
 points=[('pelvis',-1,[0,-.04,.01]),('waist',0,[0,.14,.015]),('chest',1,[0,.38,.015]),('neck',2,[0,.585 if king else .54,.035]),('head',3,[0,.73 if king else .70,.06]),
 ('left_upper',2,[-.20,.47,.02] if king else [-.17,.385,.015]),('left_lower',5,[-.35,.30,.08] if king else [-.24,.12,.13]),('left_hand',6,[-.376,.435,.09] if king else [-.36,-.03,.16]),
 ('right_upper',2,[.21,.45,.02] if king else [.18,.385,.02]),('right_lower',8,[.29,.27,.16] if king else [.28,.27,.14]),('right_hand',9,[.38,.15,.36] if king else [.40,.43,.20]),
 ('left_thigh',0,[-.12,-.08,.015]),('left_shin',11,[-.19,-.53,.03] if king else [-.09,-.49,.06]),('left_foot',12,[-.24,-.86,.06] if king else [-.09,-.87,.13]),
 ('right_thigh',0,[.13,-.08,.015]),('right_shin',14,[.26,-.52,.04] if king else [.09,-.49,.06]),('right_foot',15,[.33,-.86,.07] if king else [.09,-.87,.13]),
 ('cloth_left',0,[-.22,-.08,-.10]),('cloth_right',0,[.22,-.08,-.10]),('cloth_back',2,[0,.35,-.18]),('hair',4,[0,.68,-.10])]
 if king:points.append(('staff',7,[-.376,.435,.09]))
 w=np.zeros((n,len(points)),dtype=np.float64)
 # Shared torso: broad smooth transitions through chest, waist and pelvis.
 anchors=[-.04,.14,.38,.585 if king else .54,.73 if king else .70]
 for i in range(4):
  a,b=anchors[i:i+2];m=(y>=a)&(y<b);t=smooth(a,b,y[m]);w[m,i]=1-t;w[m,i+1]=t
 w[y<anchors[0],0]=1;w[y>=anchors[-1],4]=1
 # Head stays coherent. Hair gets a restrained, delayed child response, with
 # its lower lengths blended into chest rather than swung as a rigid helmet.
 hairmask=(1-smooth(-.11,.005,z))*smooth(.04,.22,y)*(1-smooth(.74,.86,y))
 hairmask*=.58 if king else .78
 w*=1-hairmask[:,None];w[:,20]+=hairmask
 # Broad cloth zones preserve the joined robe, with small independent drape.
 cloth=smooth(-.04,-.55,y) if False else (1-smooth(-.55,-.04,y))
 cloth*=.80
 rear=(1-smooth(-.13,.015,z))
 side=smooth(-.08,.08,x)
 cw=np.zeros_like(w);cw[:,17]=(1-side)*(1-rear*.80);cw[:,18]=side*(1-rear*.80);cw[:,19]=rear*.80
 w=w*(1-cloth[:,None])+cw*cloth[:,None]
 # Rear cape above pelvis is attached to chest and a dedicated cloth bone.
 back=(1-smooth(-.18,-.045,z))*smooth(-.10,.05,y)*(1-smooth(.50,.66,y))*.70
 w*=1-back[:,None];w[:,19]+=back
 # Limbs use smooth capsules, with independent upper arm, elbow and wrist.
 arm_coverage=[]
 for ids,tip in [([5,6,7],[-.39,.43,.11] if king else [-.49,-.105,.22]),([8,9,10],[.49,.15,.42] if king else [.52,.49,.23])]:
  path=[points[k][2] for k in ids]+[tip];dist=np.column_stack([capsule(v,path[i],path[i+1])[0] for i in range(3)])
  near=np.min(dist,axis=1)
  sidegate=smooth(.12,.24,np.abs(x))
  # Back costume/hair must not catch an arm simply by projection overlap.
  front=smooth(-.10,.015,z)
  if king:front=smooth(-.075,.025,z)
  mask=(1-smooth(.075,.145,near))*sidegate*front
  mask*=smooth(-.19,-.04,y)*(1-smooth(.57,.65,y))
  scores=np.exp(-np.square(dist/.060));scores/=np.maximum(scores.sum(axis=1,keepdims=True),1e-20)
  w*=1-mask[:,None]
  for i,k in enumerate(ids):w[:,k]+=mask*scores[:,i]
  arm_coverage.append(int(np.count_nonzero(mask>.5)))
 # Lower-body balance: conservative leg corridors; wide skirt stays with cloth.
 for ids,tip in [([11,12,13],[-.27,-.95,.15] if king else [-.09,-.95,.23]),([14,15,16],[.38,-.95,.17] if king else [.09,-.95,.23])]:
  path=[points[k][2] for k in ids]+[tip];dist=np.column_stack([capsule(v,path[i],path[i+1])[0] for i in range(3)])
  near=np.min(dist,axis=1);mask=(1-smooth(.08,.16,near))*(1-smooth(-.20,-.07,y))*smooth(-.08,.10,z)
  if not king:mask*=.65
  scores=np.exp(-np.square(dist/.075));scores/=np.maximum(scores.sum(axis=1,keepdims=True),1e-20)
  w*=1-mask[:,None]
  for i,k in enumerate(ids):w[:,k]+=mask*scores[:,i]
 staffmask=np.zeros(n,dtype=bool)
 if king:
  # The ornate staff is one connected mesh with the grip. Author a rigid
  # accessory zone around its measured diagonal shaft plus open crown.
  shaftdist,_=capsule(v,[-.384,.60,.077],[-.325,-.84,.190])
  staffmask=(shaftdist<.026)&(y<.61)&(y>-.90)
  crown=(y>.55)&(x<-.285)&(z>-.03)&(z<.155)
  staffmask|=crown
  # The hand's nearby surface blends to the same wrist pivot; staff itself
  # uses exactly one influence so its shaft cannot bend with clothing.
  w[staffmask]=0;w[staffmask,21]=1
 # Preserve palm/finger volume in the original authored open-hand shapes.
 # Distal fingers can be far outside a narrow wrist capsule; they must not
 # retain torso weights simply because the original palm fans out widely.
 rigid_hands=[]
 if king:
  forearm=np.array(points[10][2])-np.array(points[9][2]);forearm/=np.linalg.norm(forearm)
  along=(v-np.array(points[10][2]))@forearm
  handzones=[(10,smooth(-.10,-.02,along)*smooth(.265,.32,x)*smooth(.16,.22,z)*smooth(-.12,-.03,y)*(1-smooth(.40,.48,y)))]
 else:
  handzones=[(10,smooth(.365,.44,x)*smooth(.08,.14,z)*smooth(.33,.405,y)),
             (7,(1-smooth(-.40,-.335,x))*smooth(.05,.105,z)*smooth(-.21,-.145,y)*(1-smooth(.01,.065,y)))]
 for bone,amount in handzones:
  w*=1-amount[:,None];w[:,bone]+=amount
  rigid_hands.append({'bone':points[bone][0],'fully_rigid_vertices':int(np.count_nonzero(amount>.999)),'transition_vertices':int(np.count_nonzero((amount>.001)&(amount<.999)))})
 # Keep exactly the four strongest weights and renormalise. Every vertex is bound.
 ids=np.argsort(w,axis=1)[:,-4:][:,::-1].astype(np.uint8)
 weights=np.take_along_axis(w,ids,axis=1);weights/=np.maximum(weights.sum(axis=1,keepdims=True),1e-20)
 assert np.all(np.isfinite(weights)) and np.max(np.abs(weights.sum(axis=1)-1))<1e-6
 (OUT/f'{role}.pos36').write_bytes(v.astype('<f4').tobytes())
 target=OUT/f'{role}.skin36';target.write_bytes(b'RW36SKIN'+struct.pack('<I',n)+ids.tobytes()+weights.astype('<f4').tobytes())
 bones=[{'name':a,'parent':b,'position':c} for a,b,c in points]
 data={'schema':'RW36SKIN: 8-byte ASCII magic, uint32_le N, 4*N uint8 joint indices, 4*N float32_le weights','role':role,'vertex_count':n,'source_vertices_sha256':hashlib.sha256(v.astype('<f4').tobytes()).hexdigest(),'bones':bones,'binding_bytes':target.stat().st_size,'max_influences':4,'arm_vertices_over_half_weight':arm_coverage,'staff_rigid_vertices':int(staffmask.sum()),'distal_hand_zones':rigid_hands,'notes':['Original GLB remains untouched. Skin uses exact imported production vertex order.','Rest positions are global; local rest origins are global-minus-parent-global. Identity rest bases.','Conservative masks author distinct anatomy, rear costume, skirt drape and rigid staff. Hand poses preserve original open/gripping geometry.']}
 (OUT/f'{role}.bind.json').write_text(json.dumps(data,indent=2))
 print(role,len(bones),'bones',n,'verts',target.stat().st_size,'bytes; arm counts',arm_coverage,'staff',staffmask.sum())
