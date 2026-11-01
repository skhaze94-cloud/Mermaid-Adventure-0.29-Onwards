# v0.27.0 — Family Tutorial in Motion

## Scope

This release deepens King Daddy and Queen Antonella's animation only in the family tutorial. It preserves the painted source art, tutorial dialogue, lesson order, combat timings, collision, saves, and all non-tutorial scenes. The existing single-character paintings remain the source of truth.

## What changed

- Replaced the coarse 40 × 56 deformation grid with a cached 64 × 96 mesh for the tutorial actors. No mesh or texture is rebuilt during a performance.
- Added smoothly weighted shoulder, elbow and wrist motion for Daddy's welcoming arm and Antonella's pearl-casting hands. Daddy's trident hand stays restrained.
- Added a connected head/neck turn, torso lead and settling motion, breathing, attention shifts, and light hair and garment follow-through.
- Added character-specific idle, swim, wave, talk, listen, cast, dash, celebrate and hug accents. Gesture poses ease in and out rather than replacing one another instantly.
- Dialogue beats animate the current speaker and the listener while the tutorial is paused. On compact landscape phone layouts, the parents ease into separated upper-screen positions above the dialogue dock. Only the two character clocks advance during dialogue; the player, lesson, physics and game clock remain paused.
- Added facing attention toward Sarah during tutorial play. Reduced-motion mode suppresses the extra articulation and keeps the painted silhouettes still.

## Boundaries

The characters remain painted 2.5D sprites, not full 3D models. Arm articulation is a smooth shader skin over the original painting, not a separate cutout skeleton; the original art has no independently authored reverse-side poses. The update deliberately keeps angles small enough to protect the painted likeness.

## Validation

The project includes a visual review capture in `verification/family-tutorial/`. Automated suites and physical Android testing were not run for this focused polish pass. The source release uses Godot 4.5.1 and the Compatibility renderer.
