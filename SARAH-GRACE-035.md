# v0.35 — Sarah Grace

A focused movement and presentation update built on the complete v0.34 Friends Cavern source. Sarah keeps her painted likeness, connected shoulders and shared torso–tail skin. All 247 checked inherited paintings, audio, models, scenes and protected world/physics/save files are byte-identical to the verified complete v0.34 ZIP. No new artwork replaces the original paintings.

## What changed

- **Stroke and glide:** a monotonic phase map lengthens the extension and lets the pull travel more purposefully. Arms, shoulder performance, ribs, waist, hand cups and tail details now use the same sampled pose phase. The existing 12 stroke styles and ordinary breaststroke schedule remain.
- **Soft stops:** a bounded deceleration envelope continues through the short physical stop, then settles through the hands, waist and fin. Resuming input clears the braking residue quickly. The velocity controller and movement balance are unchanged.
- **Intention-led turns:** strong steering commits immediately; a small opposing nudge does not reverse the whole painted body while Sarah is still travelling the old way. Gaze leads the existing continuous front/three-quarter/side turn. Shoulder sockets and the shared hip retain their original owners.
- **Purposeful arms:** reduced decorative arm sweep and quieter harmonics during the glide; a small far-arm balancing response supports a greeting. Explicit greetings remain, while the automatic eleven-second gameplay wave is removed. The opening keeps its authored performance and comfortable rests.
- **Connected wave:** the same retimed stroke drives the upper body and the delayed middle/fluke response. The tail keeps moving during the glide. No mesh detail, textures or nodes are added.
- **Cleaner jumps and interruptions:** ordinary jumps use smaller corkscrew, arm and roll accents. A full celebratory spin is reserved for a stronger jump chain. All eighteen existing performance indices remain. Boost, cast, jump and impact still take priority over a greeting; shoulder, elbow and wrist settling remain continuous.

## Ownership

`sarah_grace_motion.gd` owns only presentation-facing intent, stroke retiming and the stop envelope. `sarah_definitive_21.gd` retains view projection, shoulder registration and action priority. Existing arm dynamics own elbow/wrist follow-through; spine/torso motion own connected chest, collar and hip deformation; the existing tail skin owns its length-preserving wave. Physics and collision code are unchanged. Reset clears the new state; zero-delta pause and hidden rigs do not advance it. Economy and Gentle retain their deliberate simplified motion.

## Visual review

The portable Visual Review HTML includes matching-time/input/size before-and-after crops, full gameplay-size views, phone/widescreen opening views, the 33-second normal-speed preview and the measurement table. Captures use native Godot software OpenGL, not generated mockups. Close crops preserve aspect ratio. Timing changes intentionally produce different joint poses at the same input timestamp.

Reviewed swimming, stopping, a complete turn, rapid interrupted reversals, ascent, descent, boost/recovery, ordinary and chained airborne poses, bubble hold/release, greeting interruption, Economy and Gentle. The separate seven-second actual game simulation uses the real physics/input/action APIs and successfully records a boost, a jump chain and a moving bubble release. The main twenty-second comparison segment holds Sarah's stage position to make the rig easier to compare. The preview is sampled at 12 fps from fixed simulation ticks; its capture cadence is not measured game FPS.

## Validation

65,316 counted source checks pass, plus the device-layout and title-flow suites. This includes 56,738 temporal/geometry checks, 5,688 registered-body/action checks, 974 new Grace checks and 1,916 world/tutorial/cavern checks. The Windows executable's actual embedded pack passes 100 further checks using the matching Godot 4.4.1 Linux runtime, including every chapter, all fifteen caverns, the resident rewards, royal models, treasure/gallery content and the new Grace rig. ZIP contents and asset hashes are verified separately.

The world, all characters and paintings, caverns, dialogue, progression and save compatibility remain. Stable application identity, world data, movement controller and save code are preserved byte-for-byte. The source ZIP excludes local import caches, temporary builds and historical raw QA captures, while retaining the complete source and original assets.

## Performance

Desktop software-rendering measurements, at 840 × 576, after thirty warm frames and over ninety measured rendered frame intervals per scene:

| Scene | v0.34 mean / p95 | v0.35 mean / p95 | Draw calls |
| --- | --- | --- | --- |
| Opening | 32.88 / 39.17 ms | 32.73 / 38.35 ms | 140 → 140 |
| Tutorial swim | 29.36 / 34.09 ms | 29.19 / 34.88 ms | 227 → 227 |

These small differences are measurement noise, not an FPS improvement claim. In the matching controlled action sequence, full-quality draw-call and primitive ranges are identical (176–267 calls; 36,613–45,917 primitives). Tutorial texture memory remains exactly 557,630,916 bytes (531.8 MiB); opening texture memory remains 54,939,204 bytes (52.4 MiB). Process static memory rises by about 57 KiB. Sarah's 11,845 painted vertices and direct node count are unchanged. Mixed-action rig script time averages 4.209 → 4.234 ms in the captured software-rendered sequence; this is not total frame time. Detailed counters and headless timings are in verification/grace35.

## Remaining limits

Physical Windows launch, Android touch controls, on-device FPS, thermals and memory remain untested here. The executable is a Windows x86-64 build; embedded-pack execution on Linux is a resource/logic verification, not a Windows-device test. This release does not reduce the inherited texture footprint. Sarah remains the established economical painted 2.5D rig; rapid direction changes pass through its registered front view rather than an unrestricted 3D rotation. Native captures and selected sequential frames were inspected; no claim of perfect motion at every possible input combination is made.
