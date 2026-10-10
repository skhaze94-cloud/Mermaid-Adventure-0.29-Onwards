# Mermaid Adventure — v0.29.1 Sarah Detail Polish

**v0.29.1** adds soft local blinks, eased gaze and smile transitions, tiny head-following ear/nose responses, and connected front/back hair motion. These details share the body’s stroke phase, turn, current and effort cues. The painted neck stays anchored; Gentle Motion and Economy disable the extra deformation. See `godot/SARAH-DETAILS-VALIDATION.md`.

**v0.29 — Ultimate Sarah** builds on the complete v0.28 Living Creatures baseline. Sarah now has 36 body/fluke loops with 144 samples each, 12 distinct swim-stroke profiles, and six aerial performances. Direction, speed, boost and waterfall phase choose her strokes automatically, with continuous phase and blended joints.

Horizontal swimming includes breaststroke, alternating front crawl, relaxed sidestroke and butterfly. Rising uses a high scoop or alternating climb; diving uses a spear reach or compact sweep. Boost drives a dolphin kick or power stroke. The waterfall has dedicated entry, balancing/sculling, climb, dive, surge and exit body motions.

Open the root `project.godot` in Godot 4.3 or later, allow asset import, then press F5. Keep `godot/` and `dist/` beside `project.godot`; their paths are used by the project.

See `START-HERE.txt` for controls and `godot/ULTIMATE-SARAH-VALIDATION.md` for v0.29 checks. Older validation records describe earlier releases. Sarah's existing artwork, collisions, speed limits, jump trajectories and combat timing remain intact. Gentle Motion and Economy settings remain available.

## Import provenance

- Source ZIP SHA-256: `77d1135839384e4db23441d03ab8d1a2c09dc517391f2fdef106acebe4072898`
- Original contents: 254 files, 68,824,182 uncompressed bytes.
- All source files, including binary assets, retained byte for byte in their original relative paths.
- Added only this repository overview and a `.gitignore` for generated Godot caches.
- Imported on 10 October 2026 as the v0.28 baseline for v0.29 development.
