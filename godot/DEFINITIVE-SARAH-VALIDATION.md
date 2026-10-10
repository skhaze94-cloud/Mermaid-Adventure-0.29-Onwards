# v0.29.3 Definitive Sarah

Based on main c0fcb186 (v0.29.2). Body/fluke samples: 144 → 432 per loop (36 loops). Arm samples: 144 → 432 per arm per style (12 styles). Catmull-Rom interpolation and continuous phase remain in use. Increasing samples does not increase gameplay speed or the renderer frame rate.

Added independent near/far shoulder responses, delayed two-harmonic head motion, gaze-following tilt, and bounded local jaw/lower-lip deformation. Shoulder rotation occurs at existing attachment pivots; previous secondary offsets are removed before base interpolation to prevent accumulating drift. Jaw uses the existing face surface and artwork; this is local deformation, not speech lip-sync or a newly modelled open mouth.

Godot 4.4.1 headless validation:
- Spine: 214,009 checks, zero failures.
- Ultimate Sarah: 12,261 checks, zero failures.
- Face details: 14,584 checks, zero failures.
- Definitive Sarah: 11,347 checks, zero failures across 30/60/120 Hz, turns, idle, rise, dive, boost and waterfall contexts.

Checks cover bounded motion, continuous loop tangents, unchanged UV registration, fixed collar/hip bands, motion-setting fallbacks and reset state. No rendered visual preview was available in this environment; the artistic appearance still needs in-game viewing. Historical validation documents refer to their original releases.
