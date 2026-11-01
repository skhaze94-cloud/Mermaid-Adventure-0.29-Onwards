# Family visual QA — v0.36

Baseline: complete v0.35 Sarah Grace source (`grace35`). The baseline was not edited.
Engine used: user-supplied Godot 4.4 stable Linux x86-64, official build `4c311cbee`.
Renderer: native OpenGL Compatibility, Mesa llvmpipe software rendering through Xvfb. These measurements do not establish physical Windows or Android FPS.

## Confirmed baseline facts

- Each original royal GLB is a single static mesh, without a skin or animation clips.
- The tutorial instantiates three royal actors (teacher Daddy, teacher Antonella and the hidden playable Daddy). Together they contain 307,317 vertices and 400,120 triangles, with zero Skeleton3D bones.
- Original actor animation applies small root translation, rotation and uniform scale. It cannot articulate elbows, wrists, neck or costume separately.
- Native lesson-six composition places Daddy left of Sarah and Antonella right of Sarah. Both maintain their recognisable original art and larger proportions.
- In the 844×390 dialogue composition, parents' heads remain clear of the dialogue panel. Much of Antonella's lower body and lowered hands are behind the panel; new gestures need to remain readable within this space.

## Capture fixture

`qa_family.gd` uses the real training-lagoon scene, lesson six, Sarah at `(5500,580)` and camera 4900. Royal placement uses the existing tutorial sync before controlled poses. Twelve seconds at 12 fps cover idle, King speaking/Queen listening, King listening/Queen speaking, greeting, celebration/gift cast, and swimming travel poses. The comparison fixture holds actors' positions to show articulation clearly; it is not a recording of live user play. The same fixture runs against baseline and updated projects with the supplied engine. Static opening, actual-size tutorial, widescreen dialogue and phone dialogue are also captured.

`qa_active_benchmark.gd` includes native first scene load, instance and first rendered frame times, individual Skeleton3D bone counts, then 30 warm plus 90 timed frames of controlled active family animation per quality mode. Image saving is excluded from timed intervals. Scene composition is held constant. The standalone counters from qa_family include static view and frozen-royal-viewport passes to expose the SubViewport cost.

## Measurement caveat

Concurrent native character render jobs on the same host materially contaminate software-rendered frame intervals. In particular, baseline Gentle and Economy runs had longer wall-frame times despite much lower script costs. Repeat matched active benchmarks sequentially after other native capture jobs stop before claiming a performance improvement or regression. Preserve raw data rather than treating capture cadence as game FPS.


## Final v0.36 visual review

The final release capture is in `final-release`, with the final Sarah turn/body code and axis-based King palm/cuff weights already frozen before capture. All 144 JPEG movie frames passed Pillow decoding and size checks; eight selected poses also have native PNGs. This final fixture reports 65 bones across three Skeleton3D instances (22 King ×2 plus 21 Queen), with the same 307,317 instance vertices and 400,120 instance triangles as baseline. The visible two distinct role meshes contain 230,522 source vertices and 300,086 source triangles; the spare King shares its cached role mesh.

At gameplay size, King's greeting visibly changes elbow/wrist orientation, while the staff stays straight and gripped. His shoulder and cuff appear connected in the inspected poses. Antonella's forearm and wrist participate in greeting/gift casting, and the glow follows the moving palm. Dress, sleeve and hair outlines remain coherent in the reviewed states. Phone dialogue text and parents' heads remain clear; lower-body occlusion behind the speech panel is the established composition, not newly introduced mesh clipping.

`after-family.mp4` is a 12-second native captured family sequence at 12 fps from fixed simulation ticks. `after-family-slow.mp4` is the same sequence at half speed (23.9167 seconds because the final held frame adds one capture interval). This is capture cadence, not actual game FPS. `before-family.mp4` retains the complete matching baseline sequence. Intermediate raw PNGs were pruned after encoding, retaining eight key baseline PNGs. The final release JPEGs and key PNGs are all retained.

Settled opening views (front, side, away), 844×390 and 1280×720 layouts, and Gentle Motion were captured with the supplied 4.4 engine. Use `opening-front.png` for a fully visible hero; `opening.png` is an earlier entry-fade frame. The settled opening harness now ends cleanly after allowing menu tweens/deferred layout to finish.

## Final clean performance measurements

Use `clean-before.json`, `clean-after.json` and `clean-rss.json`; earlier timing files are retained as historical measurements affected by an external looping LOD probe, subsequently stopped. During the final matched pair, other team native render/export jobs were stopped. Runs are sequential at 1120×768 through the supplied 4.4 engine and Mesa llvmpipe software OpenGL. 30 warm +90 measured frames per quality mode include active character pose updates and native rendering; image writes are excluded.

| Mode | v0.35 mean/p95 frame | v0.36 mean/p95 frame | v0.35/v0.36 character script mean |
|---|---|---|---|
| Full |208.57/263.56ms |221.64/266.00ms |5.043/5.617ms |
| Gentle |208.07/265.52ms |95.65/241.11ms |1.395/1.306ms |
| Economy |210.54/268.46ms |90.14/230.01ms |1.408/1.418ms |

Full-quality mean frame time increases 6.3% in this software-rendered fixture; do not claim zero rendering overhead. Gentle/Economy reduce the royal viewport update cadence to 20 Hz while retaining the skeletons, which explains the lower mean frame times and lower average primitives. Full draw calls are 168.27→168.02; mean primitives 338,522→338,713 (minor Sarah changes). Exact visible royal triangle contribution in the static/frozen viewport comparison is unchanged at 299,824 triangles, so no lost LOD increase occurs in this tested view.

Full static engine memory:67,751,883→68,546,391bytes (+0.76MiB). Texture memory:548,292,659→549,337,139bytes (+1MiB). Render buffers:31,096,250→53,448,526bytes (+21.32MiB). External Linux process high-water memory:1,092,866,048→1,124,352,000bytes (+30.03MiB). Maximum sampled RSS:1,086,312,448→1,116,610,560bytes (+28.89MiB). These counters overlap and must not be added together. Godot cannot read `/proc` through its zero-length-file helper, so its `rss_bytes:0` field is unavailable; use the independent external samples.

First rendered tutorial scene was observed at 10.32seconds baseline and 7.01seconds after. This is one sequential run with differing cache state; it is not evidence of a startup speed improvement. Physical Windows and Android-device frame time, peak memory, input and thermal behaviour remain unmeasured.
