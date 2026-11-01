# v0.36 — Connected Grace & the Living Royal Family

Built from the complete v0.35 Sarah Grace source. The update focuses on Sarah’s connected movement and the tutorial royal family. All 247 checked inherited paintings, models, audio, scenes and protected movement/world/save files retain their exact baseline bytes. Original GLBs are preserved. Mummy and Queen Antonella are one character.

## Structural audit and changes

Sarah’s old hip endpoint could remain attached while the abdomen and tail left that point along different tangents. Her turn also rotated a long tail strip toward a rigid vertical pose; signed front-body projection could invert painted cells during the negative-facing exit. A trial projection revealed another ribbon collapse where the width normal aligned with the spine. Those rejected trials are not supplied as finished evidence.

The final rig uses a distributed pelvis curve, a matching curved proximal tail, and a 169-vertex anatomical loft across the actual deformed lower bodice and projected tail root. It samples the original scale painting, adds one draw, and follows the same curved centerline. Tail cross-sections remain perpendicular to the projected spine, preserving visible thickness throughout the turn. Absolute facing width keeps the front body’s vertex order coherent. The tail foreshortens into a curved depth arc rather than rotating as a rigid strip. Fin/wake anchors follow the projected tip. Existing responsive movement physics and action priority remain.

Daddy and Antonella’s original GLBs each have one static mesh, zero skins and zero animation clips. They previously moved mostly as whole objects. They now use genuine cached GPU skinning with 22 Daddy bones and 21 Antonella bones, four normalized influences per vertex, and independent head/neck, spine, shoulders, elbows, wrists, lower body and restrained hair/cloth response. Geometry, UVs, materials and paintings are retained. The staff follows the gripping hand as a rigid weighted accessory. A final hand audit corrected a pinching cuff/palm transition: all 923 inspected hand/cuff triangles retain orientation; 723 rigid palm/finger triangles preserve area to floating-point precision.

The two parents have different timed performances for idle, greeting, speaking/listening, demonstrations, celebration and travel. Gestures anticipate, perform and return to rest. Tutorial proximity, lesson progress and gift stages choose cues; unconditional periodic waving is removed. Demonstration glow projects from the animated palm. The viewport is slightly wider to give hands/staff more clearance without reducing character height. Economy and Gentle retain connected anatomy while rendering royal portraits at 20Hz. Hidden actors suspend updates.

## Ownership and compatibility

Grace Motion owns presentation intent/stroke timing; Definitive2.1 owns view projection and registered attachments; spine/torso motion owns chest/collar/pelvis deformation; tail skin owns the model-space length-preserving wave; the connected waist owns the shared broad loft. Royal Actor owns action timing; Royal Connected Skin owns cached mesh/skin data and bone poses; Family Attention chooses scene cues only. Existing dialogue priority, interruption, pause, retry and scene reset remain.

Royal binding files include exact reference positions. Godot4.5.1 reorders imported vertices relative to4.4/4.4.1. A guarded, one-time exact-position remap handles this; conflicting duplicates or changed geometry are rejected. It is not approximate nearest-neighbour binding. Rebuild instructions and the generator are in godot/tools/royal36.

## Review and validation

The separate portable Visual Review contains matching-size before/after views, consecutive60Hz turn frames, normal and slow-motion previews, native tutorial compositions and phone/widescreen dialogue. Final native captures use the Linux4.4 stable executable supplied by the user. Earlier rejected experiment folders are excluded from delivered comparisons.

Independent360-frame reversal analysis finds zero folded connector frames; minimum connector triangle area is positive, transverse tail width remains at least65.6 full-grid units, and measured screen-centerline displacement at the facing crossing stays below0.293 units. Mesh measurements do not guarantee every painted pixel; actual final side/intermediate views were also inspected. Tiny covered lower-edge cells remain in the inherited side bodice grid beneath the connected pelvis surface.

164,916 unique counted source checks pass on supplied4.4, plus title/device-layout suites. Existing action, interruption, reset, pause/hidden and geometry suites remain. World tests cover all15 caverns and23 named friends. The actual Windows embedded pack passes105 chapter/world checks and12 skin integrity checks. Actual Android exported resources pass105 world checks plus2,115 skeletal binding/remap/pose checks. Tests are supporting evidence, not a substitute for the rendered review.

## Performance

The accompanying performance.json contains clean sequential measurements under supplied4.4, Mesa llvmpipe software OpenGL,1120x768. Each mode uses30 warm and90 measured rendered frames with fixed60Hz character ticks; screenshot writing is excluded. These are fixture measurements, not physical Windows or Android FPS.

| Mode | v0.35 mean / p95 rendered interval | v0.36 mean / p95 rendered interval |
| --- | --- | --- |
| Full | 208.57 / 263.56 ms | 221.64 / 266.00 ms |
| Gentle | 208.07 / 265.52 ms | 95.65 / 241.11 ms |
| Economy | 210.54 / 268.46 ms | 90.14 / 230.01 ms |

Full-quality character script time rises5.043→5.617ms, and mean rendered fixture cost rises6.3%. This is a measured cost of the richer deformation, not a zero-overhead claim. Reduced modes benefit from the deliberate portrait update cadence. Source royal topology stays unchanged:230,522 vertices/300,086 source triangles for the visible pair;43 visible bones. The three configured royal instances total307,317 vertices/400,120 source triangles/65 bones, including the hidden playable Daddy. The fixed tutorial view draws the same299,824 royal triangles before/after. Sarah adds169 vertices and one mesh/draw.

Full-mode static memory grows~0.76MiB; texture memory~1MiB for wider portrait targets; render buffers~21.32MiB for the skinned derivatives. External process peak RSS grows~28.89MiB. Original paintings are not enlarged or duplicated. First-visible-scene timings10.32→7.01s are observations from one sequential run with differing filesystem warmth; no startup improvement is claimed. Physical-device latency, FPS, memory and thermals remain untested.

## Builds and limitations

Open project.godot with Godot4.4/4.4.1 for the tested desktop project. Windows x86-64 uses matching4.4.1 runtime/templates. Android export uses official4.5.1 templates, which provide verified16KiB native ELF PT_LOAD alignment as well as16KiB ZIP alignment. Merely aligning the ZIP was insufficient with the4.4.1 native libraries. The project and exact binding remap support4.5.1.

The Android APK is explicitly unsigned because the original Mermaid private signing key is unavailable. The original app ID and version3600/0.36.0 are preserved. It requires that original key before installation/update; no substitute signing identity was created. See verification/connected36/android for package proof and reproduction notes.

Sarah remains painted2.5D with view-dependent artwork, not unrestricted3D anatomy. The royal faces and original open-finger shapes remain; no lip-sync, blink or fist morph is claimed. The derivative royal meshes do not retain automatic imported LODs because of a malformed4.4 getter; reviewed fixed tutorial geometry matches baseline, but materially different3D camera distances need profiling. Export-editor shutdown emitted cleanup diagnostics that did not reproduce in the clean runtime suites; raw logs are retained. Physical Windows launch and Android-device testing remain outstanding. This release does not claim perfect anatomy for every possible input combination.
