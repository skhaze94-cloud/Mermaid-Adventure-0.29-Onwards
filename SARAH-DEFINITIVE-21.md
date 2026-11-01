# v0.20.0 — Sarah Definitive 2.1

Built from the complete v0.16.0 Whimsy 4.0 source, using Godot 4.5.1 Compatibility. This release focuses on Sarah; the world, dialogue, caverns, characters, progression, movement balance and save format remain intact.

## Audit and changes

The v0.16 rendered audit covered rest, swimming, boost, ascent, airborne motion, re-entry, bubble charge and reversal at one fixed camera, root position and 3× display scale. The opening was also captured at matching timed cues. The underlying shoulder problem was a sleeve pivot away from the painted hinge, attachment coordinates that did not follow the deformed chest, and multiple motion layers writing the same shoulder positions. Increasing general animation amplitude would have amplified those errors.

Both sleeve pivots now sit inside the painted upper arm. Cached bilinear anchors follow the actual deformed torso surface every update. Sleeve roots counterrotate against the shoulder rotation, with deformation spreading into the upper arm. Each arm has 13 mesh rows rather than nine, while cached column weights retain the elbow, wrist and finger follow-through. Torso and spine layers retain their rotational contribution, with one final owner for attachment positions. The audit also checked the neck, waist, hair overlap, elbows, wrists and hands; the original paintings remain unchanged.

Visual facing now uses a critically damped heading separate from immediate physics facing. Front and restrained three-quarter paintings keep facial proportions through a turn. New front bodice and shared arm/tail meshes form a connected camera-facing pose. View changes use a coordinated blink and registered collar/cuff points instead of overlapping translucent faces. These are authored 2.5D views, with bounded perspective projection, rather than a freely rotating 3D model.

The menu has a 32-second performance cycle after arrival: a small greeting, a long player-facing glance, quiet swimming rests, a second gesture and a brief lagoon glance. Later cycles vary greetings, reward gestures and a bubble gesture. Breathing, blinks, gaze, hair and tail movement remain restrained. Full-quality animation is the default. Economy keeps the performance with cheaper secondary motion; Gentle Motion keeps a calm painted pose without dimensional turns and decorative gestures. Hidden menu heroes no longer advance their performance.

Gameplay keeps the existing swim, steering, boost, jump and bubble mechanics. Their visual continuity benefits from the connected arm roots, smoothed facing and existing chest, head, tail, elbow and wrist responses. This is a refinement of the authored movement system; it does not replace every jump or swim clip.

## Animation ownership

`sarah_definitive_21.gd` is the final shoulder-anchor and visual-orientation owner. Semantic priority is impact, jump, boost, casting, decorative gesture, then swimming/idle. The existing animation players own authored jump and gesture values; motion, spine and torso layers contribute deformation and rotations. Important actions cancel or suppress decorative gestures. Physics facing and input remain immediate. Retry/reset clears heading inertia; hidden rigs return before animation work. The opening performer owns its timing and suppresses the gameplay idle-greeting timer.

Front arm instances reuse the existing animated meshes. Their cuff registration runs after the skin update, avoiding a one-frame attachment lag. Front/away textures and shaders load at rig construction. Mesh topology is fixed during steady motion and quality changes; the former topology rebuild on scale changes has been removed.

## Measured cost

Measurements are desktop Linux **software OpenGL (Mesa llvmpipe)**, at 1400×960, not Android GPU measurements. Both versions used the same audit script, scene coordinates and manual animation steps. The final paired run fixed llvmpipe to two workers. CPU samples are 180 manual rig updates per state; scene frame samples are 30 rendered frames after setup. Static memory is Godot's tracked allocator, not total process RSS; texture memory is the renderer monitor.

| Metric | v0.16 | v0.20 |
|---|---:|---:|
| Unique painted mesh vertices | 40,557 | 11,845 |
| Arm vertices, each | 891 | 1,287 |
| Rig static allocation | 46.80 MiB | 38.87 MiB |
| Opening static allocation, 8 s | 52.35 MiB | 44.44 MiB |
| Opening texture memory | 53.54 MiB | 60.20 MiB |
| Gameplay texture memory | 258.14 MiB | 264.81 MiB |
| Opening draw calls, 8 s | 198 | 138 |
| Gameplay draw calls | 481 | 481 |
| Swim rig update mean / p95 | 6.02 / 10.30 ms | 3.08 / 4.48 ms |
| Boost rig update mean / p95 | 14.87 / 40.84 ms | 3.99 / 7.36 ms |
| Economy rig update mean | 0.130 ms | 0.118 ms |
| Gentle Motion rig update mean | 0.138 ms | 0.111 ms |
| Opening frame median / p95, 8 s | 316.18 / 511.87 ms | 141.12 / 180.57 ms |
| Opening frame median / p95, 26 s | 180.82 / 259.68 ms | 163.88 / 302.72 ms |
| Gameplay frame median / p95 | 155.75 / 186.84 ms | 146.57 / 168.29 ms |

The mesh reduction is 70.8%; arm detail increased where it affects deformation. Five extra painted views cost about 6.67 MiB of texture memory. Full-resolution transparent PNG originals are retained, with 512-pixel runtime import limits included in the source ZIP.

Wall-clock results varied greatly on this shared software-rendered host. An earlier unpinned paired run measured opening medians of 74.64→118.07 ms and gameplay 67.82→67.67 ms. The final run also has a worse opening p95 at the lagoon glance. These timings are evidence of the measured environment, not a reliable FPS improvement or Android performance guarantee. Geometry, allocation and texture counts are the more stable comparisons. Actual Android frame time, thermal behaviour, total memory and touch feel still require physical-device testing; no device result is claimed.

## Validation and previews

All 30 native release suites pass, including 5,688 Sarah 2.1 attachment, ownership, fixed-topology and reset checks at 30/60/120 Hz. Existing controls, jump, bubble, journey, family dialogue, save/Continue, world and Whimsy suites also pass. The source includes the test scripts and current native logs.

The source ZIP also passes CRC/extraction integrity, clean Godot import/startup and all 30 suites from the extracted project. Three motion-sensitive cases were rerun with separate preference profiles after the initial shared test profile inherited Gentle Motion; all pass. The normal package-validation tool already isolates each profile. Resources extracted from the APK pass desktop headless startup, the 5,688 Sarah checks and the 334 Whimsy 4.0 checks. This tests the exported resources and compiled scripts, not the Android engine or device GPU.

Rendered review includes the eight fixed-scale poses, magnified shoulder/cuff connections, both camera views, gameplay-size Sarah and menu layouts at 1400×960, 1280×720, 844×390 and 1024×768. Gentle Motion layouts are included. The 34-second opening and 20-second real-physics gameplay previews are encoded at 24 fps and supplied separately. The gameplay preview includes steering, a jump command, boosts, a moving bubble release, discovery encounters and direction reversals. Timed frame sequences and selected stills were inspected; physical-device playback and testing remain outstanding.

`verification/sarah-21/` contains matched comparisons, all-pose and shoulder crops, phone/tablet views, raw before/after performance JSON, APK identity verification and the preservation check. The supplied comparison uses identical crops and scaling for equivalent rest/swim/charge poses; the timed opening row intentionally shows the changed performance.

The APK uses the established `com.samkhaze.mermaidadventure` identity, version code 2000, version name 0.20.0, the existing release certificate, and verified v2/v3 signatures and 16 KiB native-library alignment. The old Godot application name is deliberately retained because it determines the existing save directory. Private keys and signing passwords are excluded from the source archive.

## Preserved content and art

No original source entry is missing. Every one of the 124 visual/audio/font files in the complete v0.16 archive is byte-identical, including original art copies, all Whimsy 4.0 paintings, Nori the slug and the existing Sarah paintings. `ASSET_PRESERVATION.json` retains the historical 105 baseline art/audio hashes and sixteen Whimsy 4.0 paintings. The new Sarah paintings have separate hashes and production prompt specifications in `godot/assets/sarah-definitive-21/generation.json`.

Five new transparent component paintings were made using the built-in ImageGen tool: `front.png`, `front-blink.png`, `away.png`, `away-blink.png` and `bodice.png`, all saved under `godot/assets/sarah-definitive-21/`. The prompt record is a reconstructed production specification, not a verbatim transcript. Existing artwork was not replaced.

Remaining limits: the rig has a finite set of painted views; a blink masks the view substitution, so it is not continuous 3D yaw. Far-side fingers and hair retain the original layered 2D ordering. No full rear-facing painting or free camera rotation is introduced. Device FPS, GPU memory and physical Android input/playback have not been verified here.
