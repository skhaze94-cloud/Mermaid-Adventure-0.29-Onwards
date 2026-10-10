# v0.29.1 — Sarah Detail Polish validation

Preserves the existing painted face atlas and all original binary assets. One persistent mesh keeps face, front hair, nose, ears and neck registered. Local eye/mouth blends avoid whole-head texture swaps. Neck deformation fades to zero at the collar. Hair roots stay attached; front/back hair share the body phase and current response. Facial gaze and joy ease across stroke changes; ear and nose movements remain below one game pixel.

## Verified

- All 26 regression suites passed in Godot 4.4.1, including the full adventure, controls, collisions, jumps, waterfall, character continuity and prior Ultimate Sarah suites. Results: `validation-v0291.json`.
- New facial suite: 14,584 checks, zero failures. Covers ten motion contexts, shared body signals, bounded/eased gaze and expression, complete blink closure/reopening, persistent mesh, anchored transforms, pause, restart, Gentle Motion/Economy and 30/60/120 Hz response consistency.
- Native Compatibility rendering on Intel Arc 140V: 29-second, 30 FPS preview with full-body and enlarged face views. Inspected idle, blink, swimming, ascent/descent, boost, turning and waterfall frames. No shader/runtime errors.
- Release packaging checks ZIP CRC, Godot ZIPReader extraction with every extracted byte verified, fresh editor asset import/startup, and fresh-copy face, Ultimate Sarah and complete adventure suites.

## Limits

Facial features retain the original artwork; nose and ears use subtle local parallax, not replacement drawings or exaggerated independent motion. Tests cover the Windows Compatibility renderer. Mobile GPU performance and other rendering backends were not physically tested. Extra facial/hair deformation is disabled in Economy and Gentle Motion; soft expression blends remain available.
