# v0.26.0 — Sarah Flow & Continuity

This release implements all five recommendations from the v0.25 Sarah audit. It preserves the complete Tutorial Overhaul and Whimsy world, dialogue, caverns, progression and save format. No movement speed, jump physics, collision, energy cost or combat balance was changed.

## 1. A connected waist and tail

The lower torso and tail now use one moving hip frame. The lower torso deformation reaches the hip instead of fading back to rest above the attachment; the tail root follows the same rotation and position. The old static rectangular alpha lookup is no longer used to feather the waist.

Two sibling paintings were created non-destructively with built-in ImageGen: `godot/assets/sarah-flow-v026/tail-connected.png` removes the original hollow cuff, and `front-connected.png` replaces the flared blouse hem with continuous scales and a tapered hip. Sarah's face, original paintings and all inherited art remain intact. Exact prompts, source references, dimensions and hashes are in that folder's `generation.json`. Runtime import limits are 2048 for the tail and 512 for the frontal torso. Tail texture coordinates scale with the actual imported resolution, preventing a transparent root when the original image is downsampled.

## 2. Continuous turns

The original bodice mesh and tail remain visible throughout a turn. Cached contour registration maps side and front paint onto one body surface; geometry and paint move through intermediate three-quarter projections instead of swapping entire torso sprites. The view envelope is continuous and bounded per frame. The head, shoulders and hip travel along the same orientation path. The long back hair follows the turning heading continuously rather than mirroring in one frame.

Faces use the existing authored paintings, with a blink and hysteresis for the art handoff. Each frame uses one face painting; blink pictures no longer blend at partial opacity and create doubled eyes. The frontal arms reuse the articulated original meshes, attach under the painted shoulder caps and remove duplicate sleeve paint. Projected limb transforms keep nonzero area through left turns and interrupted reversals.

This remains economical painted 2.5D projection, not a full 3D model or a newly painted complete set of profile views. Source paint differences can remain perceptible at close inspection; the face handoff is intentionally blink-registered.

## 3. Movement follow-through

The torso motion owner now combines locomotion and action envelopes for the shared pelvis, then filters the middle-tail and fluke responses at different rates. Braking, turning and bubble hold/recovery contribute small bounded hip responses. Existing action priorities remain in charge of input response, jumps, boost and casting. Decorative greetings still yield to those actions.

The tail centerline preserves its authored length. A brief straightening during a reversal keeps the hanging frontal projection coherent. Additional nodes, particles and per-frame texture loads were not added. Geometry topology remains persistent; paint contour data is prepared once and reused across Sarah instances.

## 4. Clearer jump curls

The combined tail bend has a smooth, bounded curl envelope, including the sum of swimming, tuck, steering and tip offsets. Strong airborne poses no longer keep folding the fin toward Sarah's head. The hip remains connected through ascent, apex, descent and landing; delayed middle/tip responses provide softer recovery. The existing eighteen jump variations, jump chaining and gameplay timing remain intact.

## 5. A live Economy tail

Economy uses 24 centerline samples, interpolated onto the existing painted surface at up to 30 updates per second. It retains a readable swimming wave without the full micro-flutter calculations. Gentle Motion uses a substantially smaller response at up to 15 updates per second. Neither mode rebuilds topology. Switching modes, hiding Sarah and resetting her performance remain supported.

## Review and validation

The new Sarah Flow suite checks imported texture bounds, continuous torso weights, non-collapsing limb/tail transforms through rapid reversals at 30/60/120 Hz, shared hip attachment, tail length, combined curl bounds, Economy movement, quality changes and reset/visibility behavior. The existing socket/ownership suite was updated to check the registered bare-arm attachment in frontal views instead of requiring a duplicated front torso. Its 5,688 checks remain in the release set. The reef reaction test now checks the moving hip attachment instead of requiring a static tail-node position.

Rendered review includes native-size and 3× poses, front/side views, moving casts, jump phases, rapid reversals, Economy/Gentle Motion and ten opening-screen views. The silent 32-second preview includes the opening screen and actual gameplay inputs: boost, two chained jumps, moving charge/release, pause/resume and rapid reversals. Scripted cuts reposition Sarah between action sections; the actions themselves use the existing controller and physics. Coverage is recorded in the movie log.

Current validation and measurements are in `verification/sarah-flow/`. Earlier verification directories are historical release evidence. The opening footer now reads the current application version instead of the old hard-coded v0.22 label.

The APK retains the existing application ID, release signing certificate and legacy save-directory name. Source exports redact private keystore configuration. All 143 inherited art/audio/font files are byte-identical; the two new paintings are additions.

Physical Android touch, frame pacing and thermal testing remain outstanding. Desktop software-rendering measurements are not handset performance results. The full-quality preset remains the default.

## Desktop measurement comparison

These are sequential runs of the same Godot 4.5.1 audit on Mesa llvmpipe software rendering, after warming each rig state for 30 updates and timing 180 updates. They measure CPU work for Sarah’s manual update, not whole-game FPS. Scene timing uses 30 rendered frames. Variability remains; none of these values is an Android measurement.

| Rig state | v0.25 mean ms | v0.26 mean ms | v0.25 p95 ms | v0.26 p95 ms |
| --- | ---: | ---: | ---: | ---: |
| idle | 2.640 | 2.796 | 2.911 | 3.740 |
| swim | 2.647 | 2.771 | 2.843 | 3.786 |
| boost | 2.715 | 2.749 | 3.092 | 3.581 |
| jump | 2.656 | 2.776 | 2.883 | 3.379 |
| economy | 0.081 | 0.171 | 0.152 | 0.298 |
| gentle | 0.082 | 0.117 | 0.163 | 0.248 |

The full-quality rig costs approximately 0.03–0.16 ms more per measured update, depending on the action. Economy gains live tail movement for about 0.09 ms more on average; Gentle Motion adds about 0.04 ms. These are deliberate quality costs, not a claimed speed-up.

| Scene / resource | v0.25 | v0.26 |
| --- | ---: | ---: |
| Opening, front view: software frame median ms | 116.585 | 117.956 |
| Opening, front view: software frame p95 ms | 130.813 | 133.284 |
| Opening, front view: draw calls | 138.000 | 138.000 |
| Opening, front view: submitted primitives | 25836.000 | 27610.000 |
| Opening, front view: texture MiB | 60.204 | 59.309 |
| Opening, front view: engine-tracked memory MiB | 44.423 | 44.545 |
| Opening, lagoon glance: software frame median ms | 122.178 | 111.339 |
| Opening, lagoon glance: software frame p95 ms | 138.848 | 148.390 |
| Opening, lagoon glance: draw calls | 138.000 | 138.000 |
| Opening, lagoon glance: submitted primitives | 27610.000 | 27610.000 |
| Opening, lagoon glance: texture MiB | 60.204 | 59.309 |
| Opening, lagoon glance: engine-tracked memory MiB | 44.424 | 44.546 |
| Gameplay: software frame median ms | 111.152 | 112.005 |
| Gameplay: software frame p95 ms | 141.015 | 127.443 |
| Gameplay: draw calls | 439.000 | 439.000 |
| Gameplay: submitted primitives | 52773.000 | 52773.000 |
| Gameplay: texture MiB | 275.731 | 274.836 |
| Gameplay: engine-tracked memory MiB | 60.333 | 60.441 |

Stored painted vertices remain 11,845. Direct rig children fall from 10 to 6. One extra topology build occurs once at setup to register the body’s second paint coordinates; quality and motion tests verify no steady-state rebuild. The frontal view now draws the articulated torso grid instead of a rigid quad, so submitted geometry increases in that view. Engine-tracked memory is not process RSS. Frame times here are dominated by software rendering and must not be converted into a handset FPS claim.
