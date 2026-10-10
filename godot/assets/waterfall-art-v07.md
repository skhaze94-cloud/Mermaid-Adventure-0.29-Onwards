# Waterfall cavern artwork v0.7

Asset: `godot/assets/waterfall-cavern-v07.webp` (1536 × 1024). Generated with the built-in ImageGen tool for this project, then encoded as WebP quality 91 for Godot. The source painting is opaque; it contains no UI, characters or pickups.

Generation prompt: production background for Sarah Maria’s painted underwater mermaid adventure; a straight-on flooded waterfall gorge below the surface, with continuous mossy blue-grey/jade cliffs at the left and right, spacious dark teal water through the centre, distant recessed cavern detail, gentle turquoise light and sparse mist. Hand-painted storybook adventure style; no sky, horizon, lake, waterline, text, characters, enemies or rewards. Keep the central gameplay corridor clear and usable on landscape phones and tablets.

The runtime samples one painting without wrapping tiles. The shader uses the paused gameplay clock, a small bounded vertical depth shift and optional gentle mist. Existing repository character and hazard art is retained.

Hazard sprite: `godot/assets/waterfall-boulder-v07.webp`. A second built-in ImageGen asset replaces the squashed reef-column rendering in the waterfall only. Prompt: one isolated broad jagged blue-grey/turquoise mossy boulder cluster, painterly storybook style, clear compact silhouette, pale teal facet highlights; no rectangular slab, tall reef, seabed, water, UI or text; actual transparent background. Transparent padding was trimmed and the image encoded at a maximum 640-pixel edge for runtime use. Collision dimensions and timing are unchanged.
