MERMAID ADVENTURE 0.31 — TREASURES OF THE ENCHANTED LAGOON
========================================================
Native Godot 4.4.1 tutorial-only implementation

WHAT THIS DOWNLOAD IS
A complete tutorial source-update package, not a standalone executable. It includes
the earlier v0.30 reef files plus the new treasure system, so it can be applied directly
to the supplied v0.27.1 source project or to that project with the v0.30 patch installed.
No Windows or Android executable is included. No export-template installation is required
to run it from the Godot editor.

INSTALL
1. Back up the original project folder.
2. Extract this ZIP into the folder containing project.godot; allow the included files
   to replace their matching versions. Do not create an extra nested project folder.
3. Open project.godot in Godot 4.4.1 and let the new textures import.
4. Run the project and choose the family tutorial. Alternatively, open
   godot/training_lagoon.tscn and use Run Current Scene.
5. Swim close to a chest to collect it, as before. No additional key/button is required.

NEW TREASURE CONTENT
Seven transparent painted styles, each with separate closed, body and lid textures:
Pearlkeeper, Coralheart, Moon-Shell, Kelpwood, Crystalwake, Sunken Relic, Golden Crown.
Five are assigned to the five EXISTING tutorial treasure positions. Kelpwood and Sunken
Relic are supplied as additional reusable variants, not new pickups.

The three surface relics use Pearlkeeper, Coralheart and Moon-Shell. The Pearl Nursery
uses Crystalwake and Bellflower Hollow uses Golden Crown. Closed chests have subtle
highlights and a proximity accent. Collecting a chest plays an articulated lid opening,
soft pearl/glint reveal and the existing reward gesture/sound. It then remains visibly
open and empty. Respawn restores collected chest state without replaying rewards.

GAMEPLAY PRESERVATION
The original collection distance, treasure positions, rewards, scoring/combos, checkpoint
format, lesson order, dialogue, collision and controls are unchanged. Each chest still
awards its original 100 base points, with existing combo rules. Decorations do not create
new rewards. A fresh tutorial restart closes the original five chests again.

Sarah, Daddy and Antonella have NOT been redrawn or re-rigged. All 115 original project
artwork files and 44 Sarah/family animation/dialogue scripts were byte-compared to the
uploaded v0.27.1 archive and remain identical. Character-preservation hashes are provided.

SCOPE AND PERFORMANCE
The new actor pool is created only by avina_tutorial.gd. A small optional renderer hook
in deep_routes.gd lets this tutorial draw its own cavern chests; other chapters retain
the original chest renderer. The pool matches the five real treasure records and has
viewport culling. Economy mode reduces sparkle count. Gentle Motion snaps to the open
state, disables the reveal burst and freezes idle glints.

FILES
- godot/tutorial_treasure_chest.gd: reusable painted chest actor and lid/effect animation.
- godot/tutorial_treasure_gallery.gd: tutorial presentation layer reading existing saves.
- godot/avina_tutorial.gd: tutorial-only integration; other collectible art stays original.
- godot/deep_routes.gd: optional custom treasure-rendering hook.
- godot/assets/treasure-v031/: 21 layered chest PNGs, 3 effect/interior PNGs, asset manifest.
- godot/tutorial_treasure_test.gd: dedicated native test suite (100 checks).
- godot/tools/treasure_v031/capture.gd: native viewport screenshot/animation harness.
- verification/treasure-v031/: final import/test/render logs and preservation report.
- v0.30 reef assets and helpers: carried forward without an additional reef redesign.

VERIFICATION
Godot reports: 4.4.1.stable.official.49a5bc7b6.
Final project import: no script/import errors.
All eight executed native test suites passed:
  tutorial_treasure_test — 100 checks, 0 failures
  avina_tutorial_test — 112 checks, 0 failures
  tutorial_overhaul_test — 15 checks, 0 failures
  family_layout_test — 20 checks, 0 failures
  sarah_flow_test — 56,738 checks, 0 failures
  deep_routes_test — 596 checks, 0 failures
  scoring_ui_test — passed
  title_flow_test — passed

The screenshots and animation were captured from the actual tutorial scene in native
Godot using Mesa software OpenGL. Inspection positions were staged; the chest was opened
through the game's actual pickup function, which awarded 100 points. The animation is
an engine inspection capture with the surrounding world held still, not a full gameplay
walkthrough. These are not concept-art mockups. Software rendering is not a performance
benchmark for a Windows gaming PC. Windows/Android exports and device testing were not done.

OPTIONAL COMMANDS
  godot --headless --editor --path . --import
  godot --headless --path . --script res://godot/tutorial_treasure_test.gd
For native screenshots set TREASURE_CAPTURE_DIR to an existing writable directory with
screenshots/ and frames/ subdirectories, then run the capture script with a real display
or Xvfb. GODOT_CAPTURE_PREVIEW=1 suppresses music/intro for screenshots; leave it unset
when running the title_flow_test because that suite tests the opening sequence itself.
