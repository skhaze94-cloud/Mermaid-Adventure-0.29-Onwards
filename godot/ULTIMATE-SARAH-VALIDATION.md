# v0.29 — Ultimate Sarah

Validated on Windows with Godot 4.4.1 stable, native Compatibility rendering on Intel Arc 140V. The project retains its Godot 4.3 feature target; Godot 4.3 itself and physical mobile/controller hardware were not exercised for this update.

## Movement and strokes

- Body/fluke loops: **18 → 36**, samples per loop: **72 → 144**, total sampled body poses: **1,296 → 5,184**.
- Twelve stroke profiles, each with separate near/far 144-sample shoulder, elbow and wrist tracks. Breaststroke, front crawl, sidestroke and butterfly have different hand paths and arm synchronization. Rising and diving each have two strokes; normal boost has two, plus opposed waterfall sculling and streamlined waterfall surge.
- Six aerial performances replace three: opposing corkscrews, full roll, soaring arc, twirl and asymmetric wave. The new variants also change arm lift and tail tuck.
- Cadence eases with speed, while a shared continuous phase prevents resets. Direction changes have a short stability window; joint tracks crossfade instead of replacing poses abruptly. Tail, hair and torso keep their secondary follow-through.
- Waterfall entry, scull, rise, dive, boost and outflow choose their own body loops. Horizontal visual velocity uses the actual shaft width instead of a fixed 520-pixel multiplier.

## Automated checks

**25 regression suites passed without reported script/resource errors.** Per-suite results are in `validation-v029.json`.

The new Ultimate Sarah suite passes **12,261 checks**: distinct strokes, loop closure and tangent continuity, bounded elbow/wrist angles, automatic directional/boost selection, sustained-swim variety, alternate-stroke reachability, hand/fluke continuity through state changes, shoulder anchors, stable painted UVs, six reachable aerial variants, 30/60/120 Hz phase/joint comparison, real waterfall wiring, pause, Gentle Motion, Economy and restart.

Existing checks cover Sarah's waist/shoulder alpha overlap, arm reach, neck and tail continuity, jump launch/landing, controls, waterfall duration, collision recovery, family tutorial and Avina, enemy articulation and engagement, all eight chapter buttons and the linked adventure, UI layout, scoring, scene transitions and ocean effects. Existing tests were updated where v0.29 intentionally replaces the old 18-loop count and single-stroke behavior.

## Native visual review

A 32-second, 30 FPS native Godot close-up preview shows the production rig across horizontal, rising, diving, boost and waterfall contexts. Its enlarged presentation does not change the playable rig's scale. Sixteen native pose captures and three actual waterfall gameplay renders were checked for framing, painted identity, visible stroke differences and connected anatomy.

## Packaging and scope

The release ZIP uses a root `project.godot`, explicit directory entries, retained binary assets, and current v0.29 instructions. Package validation checks CRC, byte-for-byte Godot ZIPReader extraction, a fresh editor import, startup, and fresh-copy Ultimate Sarah/full-adventure suites.

This update changes Sarah's presentation and contextual animation. Movement speed limits, collision roots, jump trajectories, attack timing, level geometry and the v0.28 creature system are retained. Render-cadence checks simulate clocks; they do not certify performance on physical 120 Hz displays. Historical v0.28 and earlier records remain in the project with their original scope.
