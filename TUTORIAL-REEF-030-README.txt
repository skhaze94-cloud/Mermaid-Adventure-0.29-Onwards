MERMAID ADVENTURE 0.30 — TUTORIAL REEF VISUAL UPGRADE
=====================================================

THIS PATCH CHANGES THE TUTORIAL ONLY.

Sarah, Daddy and Antonella are deliberately preserved exactly as supplied:
- No character artwork, source textures, face details, models, rigs, body proportions, costumes or character animation controllers were edited.
- Only the tutorial's environment dressing, materials and reef/plant animation were changed.

CONTENTS
- godot/assets/tutorial-v030/ : 34 new game-ready PNG textures and transparent sprites.
- godot/tutorial_reef_beauty.gd : tutorial-only visual dressing helper.
- godot/avina_tutorial.gd : tutorial scene integration (replaces the original file).
- godot/tutorial_reef_beauty_test.gd : Godot runtime import/scene smoke test.
- godot/TUTORIAL-REEF-030.md : technical notes, scope and preserved-character fingerprints.
- project.godot : project version/description updated to 0.30.0.
- TUTORIAL-REEF-*PREVIEW* : texture and sprite reference sheets.

APPLY
1. Make a backup of your current Mermaid Adventure source folder.
2. Extract this ZIP into the root of the supplied v0.27.1 source project.
3. Allow Godot 4.4 to import the new PNGs.
4. Open godot/training_lagoon.tscn or run the project and select the tutorial.
5. Optional runtime smoke test: run godot/tutorial_reef_beauty_test.gd as a SceneTree script.

SCOPE
The tutorial receives a layered caustic overlay, distant coral dressing, five material textures, varied reef/rock props, shell and crystal scenery, hanging pearl lanterns, current ribbons and gently swaying plants. Reduced Motion stops the movement. Decorative items do not change collectible counts or progression.

The tutorial's lesson order, dialogue, checkpoints, collision, controls, rewards, save format and family character art are preserved.

VERIFICATION LIMIT
Source integration and image integrity checks are complete. Godot is not installed in this execution environment, so engine import, runtime visual QA and Windows export still need to be run in Godot 4.4.
