# v0.13.0 — The Ocean’s Little Secrets

This release focuses on one opening area: Highland Gold before its waterfall. The original eight chapters and all sixteen Pocketful of Wonders encounters remain available.

## Nori’s postal round

Nori stands on the seabed around world x1740. The original 1254 × 1254 transparent painting is used unchanged on a fixed 841-vertex mesh. A small vertex shader independently animates his antennae, mailbag and mantle. A deterministic 28-second postal round includes pausing, dropping a spare letter, returning to retrieve it and offering a heart-sealed hello. Local captions yield to gameplay messages, charge, nearby combat, pause and Sarah’s movement. The helper has no collider, reward, quest requirement or saved state.

## Gardens that greet Sarah

Six authored beds lie at x570, 980, 1410, 1800, 2240 and 2680. Existing painted reef plants are combined with small curved stems, opening anemones, bell flowers, pearl pollen bubbles and peeking shrimp. The response eases in and out with Sarah’s distance. The layer draws at most four beds, using fewer flowers on wide phone views and Economy. A fixed 12,288-vertex brush is reused; no nodes or textures are created while travelling.

## Underwater light

A single local shader adds restrained warm-to-aqua light shafts, low-intensity seabed caustics and a world-anchored camera relationship. Three depths of pollen/silt give slight parallax without new screen-space render targets. The light is behind the heroine and the new cutouts. Its region fades toward the waterfall and is hidden after the fall. Existing world light remains intact.

## Accessibility and preservation

Gentle Motion freezes articulation, postal choreography, light animation and additional drifting motes. Combat hushes the flourishes and speech. Pause freezes the scenery clock. Retry resets only the decorative routine. No save-format change, new action, compulsory task, hitbox or score owner is introduced. The original v0.12 PNG, WebP and audio bytes are verified unchanged; see ASSET_PRESERVATION.json. All original Whimsy paintings and provenance remain in art-originals/.

This is a source-project release for Godot 4.4+. No Android APK or repository merge is implied. Physical-device FPS still requires testing.
