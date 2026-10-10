# v0.27 — Character Harmony validation

Validated with Godot 4.3 stable on Linux, using the native Compatibility renderer and automated headless checks. The test scripts are included in this project.

## Character assembly and motion

The new character_harmony_test passed **4,475 checks**. It samples actual painted alpha through the current triangle UV mapping at the waist and both shoulder overlaps. It checks complete idle, swim, dash, turn and aerial performances, per-frame arm updates at 120 Hz, persistent royal meshes, frame-rate-independent royal pose blending at 30/60/120 Hz, frozen-clock behavior, gentle-motion behavior, full-resolution royal textures, dense boss geometry and stable combat roots.

Existing Sarah tests passed: neck/hip continuity (4,325 checks), breaststroke and dash (1,689), full-body depth (1,086), fluid tail motion (1,914), jump animation and gesture/quality behavior. The depth test now requires 72 samples in each of the 18 continuous loops. The smoke test checks per-frame high-quality creature animation and retained economy throttling.

## Full-game regressions

**23 suites passed with no reported errors.** Results are recorded in validation-v027.json. Coverage includes all eight chapter buttons and the complete linked adventure route; Avina's three hiding places, companion choices and protected bubble behavior; family dialogue and device layouts; enemy engagement and presentation; background/terrain grounding; controls, jumps, rock recovery, scoring, title flow, transitions and ocean effects.

Rock recovery passed 1,153 checks and grounding passed 487 checks. Character presentation changes do not alter enemy AI, hit windows, score rules, physics bodies or level geometry.

## Native visual review

Native Godot captures reviewed the character rigs in swim, dash, rise, turn, cast, impact, greeting, reward, celebration, gentle-motion and economy states. Family tutorial captures reviewed teaching, dialogue, King Daddy's trial, peekaboo, the portal choice and the following companion. All eight chapters were rendered at entry, terrain and boss positions (24 stage captures), with three menu layouts.

The supplied motion preview is an eight-second, 480-frame native Godot render at 60 FPS. It shows the production character rigs and source textures at enlarged preview scale; it is not a separate art mockup.

The deliverable ZIP is CRC-checked and tested with Godot's ZIPReader extraction sequence into an empty folder, then imported and checked as a fresh project.

## Scope

Native rendering and play logic were checked on Linux Godot 4.3. Frame-rate tests use controlled clocks; they do not constitute physical 120 Hz device certification. Windows, physical mobile devices and newer Godot releases were not run here. The project targets Godot 4.3+ and uses the Compatibility renderer.
