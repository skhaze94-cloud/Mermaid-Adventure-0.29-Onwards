# v0.18 terrain material

Generated with the built-in imagegen tool. Runtime asset: reef-stone-v018.png.

Prompt: Create one square, edge-to-edge seamless tile of richly painted blue-gray
submerged limestone, interlocking irregular natural stone faces, fine mineral
striations, deep navy crevices, subtle turquoise moss, tiny barnacles and weathered
fossil impressions. Orthographic front surface material for a hand-painted
underwater fantasy 2D mermaid game. Elegant detailed storybook painterly art, cool
underwater ambient light, moderate contrast. No landscape, isolated boulder,
standing plants, perspective, borders, text, watermarks, or empty areas.
Opaque filled stone; seamless on all four sides.

Applied at 360 world pixels per tile, cropped to existing obstacle silhouettes.
Existing reef atlas caps/gardens are reused with chapter-specific color grading.


## Reef formations — reef-formations-v018.png

Built-in imagegen; transparent RGBA output preserved. Four isolated terrain
sprites: two compact suspended blue-violet rock formations with hanging kelp,
turquoise tube sponges and violet coral; two broad low blue-gray limestone
outcrops with moss, shells and small reef plants. Front orthographic side view,
solid opaque footprints, richly hand-painted storybook game art, crisp stone
faces with soft underwater highlights. No rectangular backing, text, water,
scenery, characters or shadow. Measured sprite crop rectangles live in
terrain_painter.gd; atlas filtering is clipped to each frame.

## Flip — flip-dolphin-v018.png

Built-in imagegen; transparent RGBA output preserved. Single isolated side-view
blue-turquoise dolphin, full body swimming left, cream-blue belly, friendly
expressive eye and mischievous smile, graceful dorsal fin, flippers and curved
tail. Detailed painterly storybook fantasy game finish with pearlescent
underwater highlights. All fins visible; no scenery, water, bubbles, text,
watermark, accessories or shadow. Draw region crops transparent margins.

Backdrop pass also aligns the painted surface of Palace, Training and Colombia
with the actual jump/swim boundary, and uses bounded panorama movement. Existing
Sarah, enemies, rewards, menu and HUD art were inspected in native captures.
