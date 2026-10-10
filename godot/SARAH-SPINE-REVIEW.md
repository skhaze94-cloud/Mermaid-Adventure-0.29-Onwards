# v0.29.2 — Neck and back motion review

## Finding

The tail and arms already had independent continuous tracks, but the bodice mesh retained a static shape. The torso mainly reacted to vertical velocity, and the head counter-rotated by a fixed fraction. This left little stroke-driven movement between the shoulders and hip, and no delayed neck settling.

## Change

- The torso follows the same blended hip/middle wave as the tail, with restrained back rotation and compact boost amplitude.
- Exact critically damped springs ease back and neck changes. The chest leads; neck inertia follows and settles without overshoot. Torso angle is bounded to 0.13 radians and local neck angle to 0.10 radians.
- Head rotation pivots around the painted collar point. The collar remains attached rather than sweeping away from the chest.
- A small middle-back bend deforms the existing bodice painting. Upper collar/shoulder and lower hip bands are exactly pinned; UVs and source artwork remain unchanged.
- Facial details, hair and arms inherit the connected head/torso transforms. Waterfall and boost use the existing shared stroke, travel, turn and current signals.
- Gentle Motion and Economy omit the additional bodice ripple. Restart clears spring momentum and restores the resting mesh.

## Validation

All 27 regression suites passed in Godot 4.4.1; results are in `validation-v0292.json`. The new spine suite passes 214,009 checks across both facings, five motion inputs and four waterfall contexts. It checks fixed attachment bands, collar pivot, unchanged UV/rest geometry, bounded deformation and angle steps, visible nonzero back movement, reduced-motion/quality behavior and restart. The exact spring is consistent at 15/30/60/120 Hz for a constant target. Existing painted neck-alpha continuity, facial detail, jumping and full adventure suites also pass.

A 29-second native 30 FPS Compatibility preview shows the full body beside a neck/back close-up through idle, swim, ascent, descent, boost, turn, waterfall climb/boost and recovery. Fresh release-package validation checks CRC, byte-identical Godot ZIPReader extraction, editor asset import/startup and spine, face, Ultimate Sarah and full-adventure suites.

Original binary artwork and gameplay movement/collision rules are unchanged. Validation used Windows Godot 4.4.1 and Intel Arc 140V Compatibility rendering; mobile hardware and other backends were not physically tested.
