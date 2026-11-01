# Mermaid Adventure v0.38 — Pearl Storybook

A focused presentation update built from complete v0.37 Sarah Connected Motion. The family tutorial now has a warm ivory/seafoam storybook interface, painted pearl-heart and power icons, clearer optional replies, and compact contextual feedback. Sarah's movement, world geometry, painted environments, royal rigs, control physics, lesson order, branch effects, rewards and save identity remain intact.

## What changed

- **Design before implementation:** `PEARL-STORYBOOK-DESIGN.md` defines the full component set. The native component board shows the shared production palette, live fonts, painted icon atlas and states.
- **Conversation:** one authored speaker beat at a time, small portraits and beat counts, dark ink on ivory, optional replies and extras, a clear Continue action, bounded scrolling and visible keyboard focus. A short fade reveals the whole line without a mandatory typing delay. Expanded optional replies deliberately use more screen while the game is paused; this does not claim every character remains unobstructed in that reading mode.
- **Warm tutorial copy:** selected instructions are split into shorter beats while the family jokes, all 33 reply branches and their effects remain. Companion choice, optional Daddy fins, input reset and pause ownership are retained.
- **Health and energy:** five distinct full/empty painted heart silhouettes, finite damage/healing feedback and a quiet low-health edge. The turquoise bar is labelled Boost energy because it powers Boost/Jump. It is not misrepresented as a bubble-energy resource.
- **Bubble charge:** context-only charge/recovery on desktop; touch-button tier and cooldown feedback on phones. Labels have their own clear zone below the icon/ring. Existing locked/held/release/recovery semantics remain.
- **Actual active gifts:** the Royal boost badge reads the real tutorial eight-second gift timer and draws a duration ring. It freezes with gameplay pause and disappears when the effect expires. No shield mechanic was invented to match a concept image.
- **Small celebrations:** a reused slug charm accompanies actual Secrets discoveries; pearl/shell charms distinguish other major rewards. Ordinary pickups keep smaller feedback. No reward nodes are allocated on each event.
- **Controls and menus:** painted bubble/fin/jump icons, restrained ivory touch surfaces, shared input/art rectangles, a real desktop Pause button, and matching pause/results panels. Actual phone pause/results targets were enlarged to meet 44 physical pixels. Main analogue controls and movement balance are unchanged.
- **World speech:** existing Whimsy, Pocketful of Wonders, Living Reef, little moments and Avina captions use the same ivory/ink treatment. Their existing single-caption ownership, placement and suppression rules remain.

## Visual and functional review

Native Godot 4.4 renders were reviewed at 1280×720 and 844×390, covering all tutorial speech IDs, expanded replies and final-reply focus, companion choice, health/energy, charge tiers, cooldown, active gift, discovery toast, pause and results. A first capture exposed wrapped beat counters, soft bold text and charge-ring/label collisions. The supplied release includes the counter-width, MSDF bold-text and separate ring/text-zone corrections. Initial images are superseded by `native-final`; targeted final touch/menu states are in `final-touch`.

Current verification is under `verification/pearl38`. The unique suite list avoids counting repeated runs twice. A native geometry report is an aid to visual review, not a claim of pixel-perfect quality. Historical Sarah continuity/torso/spine/jump-animation diagnostics already failed in the unchanged baseline and are not represented as passing by this release. The historical character-harmony fixture timed out in this run and refers to obsolete mesh counts and royal-mesh APIs; it is not counted as passing. Sarah and royal runtime rig files remain byte-identical to v0.37.

The Windows executable's embedded resources and scene loading were tested with Linux Godot 4.4.1: 107 world/resource checks and 11 dedicated Pearl UI checks pass. An eight-second, 192-frame native staged preview at 24 FPS exercises actual bubble-charge begin/release and the real gift duration; player placement is held for the presentation. It is not a complete playthrough or a device FPS test. The Windows binary itself was not run on physical Windows. No physical Android measurement or signing claim is made. Sarah's previously documented exclusive facial-paint handoff remains; this UI update does not redesign her rig.

## Performance measurements

Matched Linux Godot 4.4 tutorial fixtures, Mesa llvmpipe software rendering, 1120×768, 30 warm-up + 60 measured frames per mode. Character updates use deterministic 60 Hz steps. These are native rendered intervals with scheduling variation, not physical Windows/Android FPS. A lower software-rendered interval in one run is not evidence of a device speed improvement. The figures include unchanged royal characters and world rendering.

| Mode | Character+snapshot ms, before → after | Rendered interval ms, before → after | Draw calls, before → after |
|---|---:|---:|---:|
| Full | 6.99 → 7.07 | 297.58 → 253.17 | 158.3 → 159.4 |
| Gentle | 1.63 → 1.96 | 120.35 → 110.91 | 108.5 → 109.5 |
| Economy | 1.85 → 1.50 | 126.51 → 96.47 | 108.5 → 109.5 |

Full-quality texture memory: 549,337,139 → 557,374,327 bytes. Static memory: 68,550,975 → 68,674,379 bytes. The new transparent painted atlas is reused through cached regions; themes and textures are prepared once, not loaded per frame. Physical-device profiling remains necessary.

## Preservation and package use

SHA-256 comparison confirms 1,141 inherited files unchanged outside the scoped UI/version edits, including original art/audio/models and Sarah/royal rig files. No inherited file was removed. The full manifest lists exact paths and hashes.

Use Godot 4.4.1 or compatible Godot 4.x to open `project.godot`. The complete source ZIP contains original unsplit assets; a GitHub clone uses the repository's existing lossless asset-restoration instructions. Rebuilding exports requires the standard platform templates. Existing application identity and save location are preserved.

For Windows, extract the entire Windows ZIP and launch `Mermaid_Adventure_v0_38.exe`. Its game data is embedded. `READ-ME.md` contains these notes; `SHA256SUMS.txt` verifies both release ZIPs.
