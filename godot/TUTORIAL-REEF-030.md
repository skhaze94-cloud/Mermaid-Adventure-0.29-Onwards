# Mermaid Adventure 0.30 — Tutorial Reef Visual Upgrade

## Scope lock
This is a tutorial-only visual upgrade. It changes no other chapter's scenery or gameplay.

**Sarah, Daddy and Antonella are intentionally unchanged.**
- No character source images, atlases, rigs, models, proportions, face art, costumes or dialogue files were edited.
- No family animation controllers or Sarah animation controllers were edited.
- The new environmental animation affects coral and plant dressing only.

## New game-ready assets
Location: `godot/assets/tutorial-v030/`

- 5 high-resolution environment materials: sand, teal reef stone, coral stone, deep grotto stone and kelp floor.
- 1 transparent caustic-light overlay.
- 6 isolated transparent flora/coral sprites derived from the project's existing art atlas.
- 3 transparent hanging-lantern sprites and 3 flowing-current ribbon sprites.
- 12 isolated transparent reef/terrain prop sprites derived from the project's existing terrain atlas.
- 4 isolated transparent decorative item sprites: pearl shell, treasure chest, heart gem and ocean crystal.

The texture tiles use periodic fields and wrapped detail placement. Opposite-edge pixel checks are included in the build notes. `sand_pearl_tile.png` is a shallow horizontal repeat strip intended for the tutorial floor band.

## Tutorial-only implementation
- `godot/tutorial_reef_beauty.gd` draws the new reef treatment.
- `godot/avina_tutorial.gd` calls the helper only from the tutorial's `_draw_world` method.
- The tutorial receives layered caustic light, distant reef flora, a richer floor material, varied coral clusters, low-profile reef props and gentle plant sway.
- Reduced-motion mode stops the sway and caustic drift.
- Decorative shell/crystal props are scenery only; they do not alter collectible counts or progression.
- Existing ring positions, collision geometry, dialogue, lesson order, checkpoints, save format and gameplay controls are unchanged.

## Integration
Copy the `godot/assets/tutorial-v030/` folder and the two tutorial scripts into the project, replacing `godot/avina_tutorial.gd`. The patch also includes `project.godot` with the milestone version changed to 0.30.0.

Godot imports the new PNGs on first project/editor open. Open the project in Godot 4.4 and allow the import scan to finish before running.

## Verification status
- All new PNG files were checked for readable dimensions.
- Seam continuity was measured on the generated tile textures; opposite-edge RGB values match exactly on all four edges for the four stone variants and the caustic overlay; the sand strip has low horizontal seam difference and is intended for horizontal tiling.
- Static source checks confirm the tutorial-only integration and unchanged character source files.
- `godot/tutorial_reef_beauty_test.gd` is included for runtime import/scene smoke testing.
- Godot is not installed in this execution environment, so engine import, runtime frame capture and Windows build remain to be verified in Godot.

## Character-file preservation fingerprints
These are the exact unchanged files checked for this tutorial-only patch:

- `godot/sarah_rig.gd` — SHA-256 `3efcf01e65460f40bd3cc9304b570b098d89ea66d250d153942191925bff9944`
- `godot/sarah_definitive_21.gd` — SHA-256 `b5dce027f3f8443a61da402dd43527f233dccd696f870c68141ac64a297d19d6`
- `godot/sarah_tail_skin.gd` — SHA-256 `85f6b62efcc7adc28845df9c88631b64d67e6be98a3f4f4edf5bc40c73f8c519`
- `godot/family_royal_actor.gd` — SHA-256 `95abd27831a2f3869d502bc057a0763382a075ffc01bd667a91aa7dc53e49032`
- `godot/assets/characters-v027/avina-baby.png` — SHA-256 `f90b01db306b16b34535f730d15571426b70470209649788630565a971f00105`
- `godot/assets/characters-v027/king-daddy.png` — SHA-256 `ff4f3316c41697989321c47b161f03b1d8ed18792f5721faec4bb47f1781af17`
- `godot/assets/characters-v027/queen-antonella.png` — SHA-256 `7fac602b28c8f22512519914b0e72b09b405ead60e45bfc7ef4af2cb0183411f`
- `godot/assets/family-v026/king-body-v026.webp` — SHA-256 `66246929d2bff7874419abb8c1b382b2572ff87923ebf2e80da344ed9ca46a7d`
- `godot/assets/family-v026/queen-body-v026.webp` — SHA-256 `e7f7613e6ed209ee9dd69c1cffbf6e8f2d8f0b9a3f9d4b2addcc6fcd7ad090a5`