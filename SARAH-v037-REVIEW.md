# v0.37 — Sarah Connected Motion

Based on complete v0.36. This is a focused Sarah presentation update. World, family rigs, controls, movement constants, dialogue, progression, saves and original paintings are preserved.

## Changes and ownership

1. **Turn registration:** the signed root transform remains an internal coordinate convention. Front torso and arm geometry now cancels that sign consistently. Negative-facing torso columns and their side-paint UVs are registered together, preventing a new fold when exiting front view. Shoulder socket sampling respects the column correspondence. No extra torso overlay is used.
2. **Live action spine:** front projection now includes the displacement of the current skinned tail from its cached baseline. Turning no longer suppresses the locomotion wave before projection. The perspective spine remains stylised, but swimming, boosting and other actions retain their deformation through it.
3. **Direction ownership:** casting, jumping and boosting no longer bypass presentation-facing hysteresis. Deliberate steering remains immediate. Small opposite input during a charge follows the same facing rules as cruising. Controller physics are unchanged.
4. **Action-aware arms:** the camera-view shoulders retain the current shoulder action, with bounded offsets and weighted greetings. Left-side basis parity stays consistent through interpolation, avoiding a zero-width arm. Existing elbow/wrist controls continue to own their joints.
5. **Waist:** a cubic anatomical loft follows the actual lower-torso and proximal-tail tangents. Its paint coordinates sample the adjoining tail columns rather than an unrelated rectangular crop. This remains a separate connecting surface, not a continuous single mesh or new 3D anatomy.
6. **Quieter ownership:** stroke cycles own arm propulsion; the unrelated additional arm-sweep clock is removed. Natural blinking owns eyelids; turns no longer force repeated blinks. Long back hair fades into the supported portrait hair before the sign handoff, retaining width rather than squeezing to a thin strip.

Presentation order: controller input/velocity → grace facing and stroke timing → base stroke/action poses → shoulder/elbow/wrist follow-through → ribs/waist and live tail deformation → registered view projection and sockets → final arm seating and anatomical loft. The view layer changes perspective; it does not change collision motion or save state.

## Evidence and limitations

In the same targeted full-speed reversal fixture at 60 Hz, maximum corresponding torso-vertex displacement at the sign handoff falls from approximately 105.6 to 0.90 local units; near-arm displacement falls from 64.05 to 0.37 and far-arm from 79.97 to 0.23. These mesh figures include transparent vertices and are not pixel-error or visual-perfection scores. The invisible back-hair mesh may mirror internally while its opacity is zero.

Tiny opposite input (-0.1) while travelling right at 270 units/second now keeps right-facing presentation both while cruising and bubble charging. The dedicated regression covers handoff continuity at 30/60/120 Hz and these two aiming states.

Native rendered close-view turns and opening-screen layouts were reviewed. An attempted facial crossfade was rejected because it produced doubled facial features. The release retains one facial painting at a time and removes forced handoff blinks. The existing authored face views still have a discrete handoff; fully continuous facial perspective requires more closely registered authored artwork. This release does not claim to have solved that remaining art limitation.

Current connected, definitive, flow, grace, tutorial, family-attention, cavern, layout, controls, conversation and scene-flow checks pass, along with the new turn regression. Historical continuity, torso, spine and jump-animation suites contain failures reproduced in unchanged v0.36; their diagnostic logs are retained separately, rather than reported as passing. Those tests predate portions of the current deformation architecture and need individual expectation/behaviour review.

Performance results are supplied as matched Linux Godot 4.4 / Mesa llvmpipe software-rendering fixtures. They are not physical Windows or Android FPS measurements. No physical-device certification is claimed. The Windows executable's embedded resources and scene loading were smoke-tested with the Linux Godot runtime; the Windows binary itself was not executed on Windows.

## Opening the source

Use Godot 4.4.1 or compatible Godot 4.x. Import project.godot and run. The complete source ZIP includes the original assets. For a GitHub clone, follow the repository's restore_original_assets.py instructions for lossless split assets. Standard export templates are required for rebuilding platform packages. Application identity and save location remain unchanged.

## Measured fixture costs

Linux Godot 4.4, llvmpipe, 1120×768. Thirty warm-up and ninety measured frames per mode. Values include the unchanged tutorial royal characters and rendering. These software-renderer runs have scheduling variability and do not establish physical-device FPS.

| Mode | Character script ms, before → after | Rendered interval ms, before → after |
|---|---:|---:|
| Full | 7.17 → 8.25 | 270.74 → 272.51 |
| Gentle | 1.02 → 1.43 | 94.88 → 109.23 |
| Economy | 1.43 → 2.13 | 131.40 → 142.70 |

Full-quality texture memory remains 549,337,139 bytes; static allocation increased by approximately 41 KB. Full-quality mean draw calls are 168.02 → 168.09 (effect visibility varies); rig vertex/triangle topology is unchanged. Additional registered body UV attributes are prepared once. No per-frame texture loading or topology rebuilding was added. Economy and Gentle Motion retain coherent geometry, but their measured fixture times increased; physical Android profiling remains necessary.
