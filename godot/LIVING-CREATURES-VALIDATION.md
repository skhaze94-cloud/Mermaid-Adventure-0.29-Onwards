# v0.28 — Living Creatures

The six ordinary creature types now use **16 joint-motion Animation resources each**, replacing four changing portraits. Each clip contains two smoothly interpolated tracks with 97 keys (96 intervals). The motion curves are generated once per anatomy and shared; each visible actor keeps its own blended phase and joint values. This is articulated movement of the existing painted artwork, rather than 16 new painted sprite frames.

The four groups are patrol (cruise, paddle, glide, glance), anticipation (gather, coil, flare, hold), attack (launch, strike, follow, bank), and recovery (brake, recoil, settle, rest). All four attack stages fit inside the ordinary 0.48-second attack. The gameplay state owns timing and collision; visual clips do not introduce attack delays.

## Articulation

A persistent shared 49 × 33 vertex mesh carries each skin. The crab moves both claw wrists, opposed jaws and alternating edge legs. Carlo and Duke Claw have separately placed pincer roots. Eels bend along their spine; sharks and swordfish use two tail hinges plus pectoral and dorsal fin movement. Jellyfish contract from a stable bell rim, with phase offsets down individual tentacle lanes. Pufferfish inflate around their body and paddle with fin and tail. Small banking, projected fin length and lighting provide depth while keeping the face connected.

The boss system also covers Miguel's wings and trailing tail, Flip's correctly oriented dolphin tail and paddle, Baron Bite, Rana Rex's arms and tail, Nessie's tail and flippers, and the palace performance's hands and gown. The family tutorial retains its dedicated royal character rigs from v0.27.

## Automated validation

**24 suites passed without reported errors**, including a new articulation suite with **109,458 checks**. It verifies 16 distinct clips per profile, dense sampled curves, loop seams, finite joint values, smooth sampling and transitions, persistent geometry and artwork, reachable variants, frozen clocks, reduced-motion behavior, facing, stable boss collision roots, hit feedback, defeat and restart.

The existing full adventure, eight chapter buttons, enemy engagement, waterfall rendering, controls, Sarah's arms/tail/jump/neck/waist continuity, family dialogue, Avina choice and bubbles, device layouts, scoring, transitions, grounding and rock recovery suites also passed. Results are included in validation-v028.json.

## Native rendering

Godot 4.3's Compatibility renderer produced and was used to inspect all eight chapters at entry, terrain and boss positions (24 stage images), plus three chapter-menu layouts. The native 16-second animation preview contains 960 frames at 60 FPS and shows the production meshes enlarged for inspection: the six ordinary creatures, followed by six boss performances. These are the shipped rigs, not a separate mock-up.

Between two patrol captures, contour fitting removed translation, rotation and uniform scaling. Every ordinary species retained visible contour deformation: 90th-percentile residuals were 6.03 px (crab), 7.82 (eel), 4.49 (jellyfish), 2.46 (pufferfish), 29.57 (swordfish), and 15.40 (shark), at enlarged preview scale. This supplements visual review by checking that motion changes the actual silhouette rather than moving an entire flat card.

The ZIP includes explicit directory entries, is CRC-checked, and is extracted with Godot's ZIPReader into an empty directory before a fresh native import and full-adventure / articulation checks.

## Tested environment

Linux Godot 4.3 stable, native Compatibility rendering. The preview's 60 FPS is its recording/playback rate, not a claim of gameplay performance on all devices. Windows, physical mobile hardware and newer Godot releases were not tested here. Import project.godot in Godot 4.3+ after extracting into a new empty folder.
