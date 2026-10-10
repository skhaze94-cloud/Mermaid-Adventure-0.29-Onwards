# v0.29.5 — Independent ribcage, waist and neck review

## Finding

The previous torso used one joint rotation and a small middle-back mesh ripple. Fixed upper/lower bands protected the painted joins but made the collar, ribcage and waist read as one rigid unit. The new response separates these regions while preserving the continuous original painting.

## Implementation

- **Ribcage:** independent critically damped rotation (bounded to 0.055 radians), lift (0.40 game pixels) and gentle volume change (0.65%). The middle tail wave, stroke effort and gestures influence the ribs; a separate slow timing channel provides a restrained volume response. Boost reduces amplitude.
- **Shoulders and neck:** their attachment points are transformed by the same ribcage transform as the painted chest. The head counterbalances chest rotation at another delay and continues to pivot around its collar point. A small local throat deformation fades to zero at the collar. Facial breathing follows the rib-volume signal.
- **Waist and tail:** a separate damped waist bend (bounded to 0.045 radians) blends through the lower torso and into the proximal tail. The tail socket and bottom hip band remain fixed. Tail-centerline segment lengths are preserved; the waist does not stretch or detach the tail.
- **Continuity:** the painted mesh blends from full ribcage response at the collar/shoulders through partial lumbar response to the fixed hip band. UV registration and original art stay unchanged. Existing shoulder glide and head/jaw tracks remain in use.
- **Timing/settings:** rib-volume timing resets independently, preserving equivalent state at 30/60/120 Hz. Restart clears rib/waist/lift/volume momentum and the tail-root bend. Pause stops rig processing; Gentle Motion and Economy restore the undeformed bodice and neutral rib transform.

## Validation

All 30 regression suites passed in Godot 4.4.1. See `validation-v0295.json`. The new torso suite passes 377,003 checks across all 12 strokes, both facings and 30/60/120 Hz. Checks include independent nonzero rib/waist/volume responses, angular and geometric bounds, smooth transitions, moving collar/shoulder registration, shader neck signal, fixed bottom hip band, unchanged UVs, preserved tail length, equivalent refresh-rate endpoints, settings and restart.

Existing real painted-alpha shoulder/waist overlap and neck continuity suites pass, along with jump, face, spine, Definitive Sarah and full adventure checks. Previous fixed-collar tests now check that collar paint and neck follow the same moving ribcage transform; the hip band remains fixed. Neck bounds are measured relative to the ribcage.

A native 60-second, 30 FPS Compatibility preview reviews 27 contexts with full-body and tracking ribcage/waist/neck views. Final captures have no shader/runtime errors. Release-package validation checks CRC, Godot ZIPReader extraction with every extracted byte verified, fresh asset import/startup, and fresh-copy torso, Definitive Review, Definitive Sarah, spine, face, Ultimate Sarah and full-adventure suites.

All 90 original binary assets are retained byte for byte. Gameplay movement, collision and combat rules are unchanged. Review used Windows Godot 4.4.1 Compatibility rendering on Intel Arc 140V; mobile hardware and other backends were not physically tested. Historical validation records describe their original versions.
