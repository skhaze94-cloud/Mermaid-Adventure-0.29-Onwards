# Mermaid Adventure v0.39 — Living Tutorial

A tutorial-only integration of the twelve supplied Meshy GLBs, built from complete v0.38 Pearl Storybook.

## What is in the tutorial

- The sea-slug postman and tea crab occupy the nursery ledges; the frog king takes Dozy's lantern-keeper role in Bellflower. The shy friend uses the lavender jellyfish. The octopus hosts the tea party, with three different guests: jellyfish, crab and slug. A sleeping moon whale and shell cottages dress the caverns.
- The three Boost-boop volunteers use the crab, jellyfish and octopus. Their health, positions, hit rules and lesson progression remain authoritative. Daddy and Antonella stand behind Sarah in that lesson so the volunteers have a clearer presentation area.
- All five tutorial treasure chests use the supplied pink-shell, red-coral or vine models, including the alternate red-coral model in Bellflower. Their actual tops are separated and pivot around rear lid hinges. Existing collection radius, 100-point base reward, saved taken state and reward ownership are retained.
- Small bounded joint offsets animate the imported skeletons: phased tentacle/limb motion, attentive upper-body movement and occasional small greeting accents. Skeletons existed in the five character files; they contained no animation clips. No new facial rig or elaborate locomotion library is claimed. The sleeping whale has gentle root motion, not a newly skinned fin rig.
- Dialogue, friend identities and reward IDs remain intact. Daddy, Antonella and Avina keep their established appearances because the attached creature set contains no matching family replacements. Sarah is unchanged.

## Scope and animation ownership

Only `avina_tutorial.gd` installs the new shared model stage. The generic painted-prop renderer has an optional callback, which remains unset in every other chapter. Source level data, collisions, controls, save schema, dialogue branches, Sarah's animation and the royal rigs are byte-identical to v0.38. A compact trial cue also avoids the previously over-tall layout at a narrow UI size.

Existing gameplay owns positions, practice states, dialogue, treasure collection and saves. The adapter only reads those values. Each new creature's root owns presentation orientation; its cached Skeleton3D rest poses own bounded joint offsets. Each chest owns one lid hinge. Offscreen creatures skip authored joint updates. Pause freezes poses and stops repeated shared-viewport renders. Retry resets remembered chest presentation without granting rewards. Removed encounter records hide cached models. Full mode updates at a maximum 30 Hz, Economy at 20 Hz with a smaller viewport; Gentle Motion reduces gesture amplitude. Resolution caps preserve aspect ratio.

## Assets and preservation

All original attachments remain untouched. Runtime copies use embedded 1024px texture derivatives; the 718,258-triangle cottage is simplified to 30,000 triangles. The exact original and derived SHA-256 hashes, bone counts, original filenames and tutorial roles are in `godot/assets/tutorial39/PROVENANCE.json`. Derived files are complete game resources, not links to a separate model service.

The complete source ZIP retains the inherited `art-originals`, art, audio, all levels and verification records. No inherited source file was removed. The preservation manifest records every unchanged file and the small list of tutorial, adapter and version edits.

## Review and limits

Native Godot 4.4.1 renders were inspected at 1280×800 and 844×390: surface friend, both caverns, practice volunteers, tea party, all five chest models closed/open, phone controls and paused dialogue. A 48-frame, two-second staged nursery performance was inspected at normal speed and through consecutive samples. The player position is held for that preview; it is not a complete playthrough. The new regression also checks capped 1920×1080 projection alignment, actual joint changes, pause, retry, hidden old sprites, chest state and isolation from Highland.

13 relevant regression suites pass. The exported Windows executable's embedded game pack was exercised with Linux Godot; see `verification/tutorial39/export-smoke.log`. The Windows executable itself has not been run on physical Windows. Android export/signing and physical-device performance were outside this tutorial integration. Historical Sarah animation limitations documented in earlier releases remain outside this change.

The Meshy auto-rig motion is deliberately restrained. These are small living idle/greeting performances, not retopologised anatomy or authored full-body swim cycles. Review on the intended hardware remains necessary.

## Measured rendering cost

Matched nursery fixture, Linux Godot 4.4.1, Mesa llvmpipe software rendering, 1120×700, 8 warm-up + 20 samples per mode, deterministic 30 Hz presentation steps. These intervals include software rendering and scheduling, not physical Windows or Android FPS. Economy's later resolution-cap reduction is not represented in this earlier measurement.

| Mode | CPU visual sync ms, before → after | Render interval ms, before → after | Draw calls, before → after | Rendered primitives, before → after |
|---|---:|---:|---:|---:|
| Full | 1.80 → 1.87 | 55.25 → 164.72 | 178.0 → 182.0 | 36,877 → 189,679 |
| Economy | 1.52 → 3.88 | 56.47 → 149.28 | 138.0 → 139.5 | 35,057 → 111,219 |

Texture memory in this fixture rose from 556,434,507 to 679,403,951 bytes; static memory from 67,985,199 to 70,833,943 bytes. The 3D models visibly cost more to render than the prior paintings; this is not claimed as a performance improvement. One shared viewport and cached resources limit overhead, while Economy reduces update cadence and resolution. Physical-device profiling is still required.

Extract the Windows ZIP and launch `Mermaid_Adventure_v0_39.exe`. Its game data is embedded. Open the complete source with Godot 4.4.1; import will rebuild the `.godot` cache. Existing application and save identities are preserved.
