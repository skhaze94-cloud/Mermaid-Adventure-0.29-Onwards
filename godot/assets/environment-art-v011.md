# Environment artwork v0.11

New original storybook raster artwork generated for this project with OpenAI ImageGen on 2026-10-09. Existing Highlands, reef and garden sheets supplied visual references. Lossless WebP conversion preserves the generated pixels and alpha. No upscaling or claimed 3K resolution: backdrops are 1536×1024, gardens 1774×887, rocks and rewards 1254×1254, portal 1024×1536.

Prompts requested a pastel Scottish lake with the waterline at 29% height, an independent flooded crystal grotto, eight isolated reef gardens, two hanging pillars and two floor ledges, shell pearl/chest/heart/boost rewards, and a gold seashell stone portal. A second portal edit requested complete transparency outside and inside the arch. Measured atlas rectangles are in environment_art.gd. Decorative shell-garden frame is retained in the source but excluded from scenery selection to avoid confusing it with collectible pearls.

Native Godot additions: base-pivot Sprite2D parallax gardens, gradient-derived rock relief with atlas-clamped texture sampling, waterline-anchored biome backgrounds, soft flow shader for the waterfall entrance and victory portal, and cached reward atlases shared by lake and waterfall drawing.
