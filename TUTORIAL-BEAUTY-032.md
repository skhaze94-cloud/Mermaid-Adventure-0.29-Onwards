# Mermaid Adventure v0.32 — The Living Family Lagoon

This is a complete Godot 4.4.1 source project. It combines the fixed v0.27.1 game, the v0.30 painted reef update, v0.31 articulated treasure chests, the final v0.29 Meshy family integration, and this tutorial beauty pass.

## Visual review and changes

The native review found three prominent sources of the simple look: tunnel water rectangles projecting above the seabed, a straight sand band, and plain swim-ring arcs. The tutorial now has world-space sand edges interrupted by its real entrances, irregular cached cavern outlines, softer rim shading, planted rock shoulders, practical hanging lights, shell-and-pearl swim rings, and small reef ledges under its five treasure chests. Transparent support pillars and floating background decorations were removed from this tutorial's treatment. All eleven lesson views, both grottoes, family dialogue and 1920 × 1080 framing were rendered for inspection.

King Daddy and Queen Antonella now use their supplied textured Meshy GLBs in transparent 3D viewports. Cached models support the existing attention, travel, dialogue and gentle whole-model performance hooks. Reconfiguring an unchanged role resizes its existing instance. Hidden actors stop viewport updates. The actors retain their natural aspect ratio.

The runtime meshes were simplified with glTF Transform and Meshoptimizer while retaining their texture images. King: 2,503,344 to 100,120 triangles. Antonella: 4,997,952 to 199,880 triangles. Combined geometry is reduced by 96%. These are geometry counts, not a measured FPS gain. Unmodified original GLBs are in art-originals/royal-meshy, excluded from game imports and exports. Their hashes are recorded in verification/tutorial32/preservation32.json.

The five original chest positions, automatic collection, rewards, opening animation and persistent collected states remain the v0.31 system. The complete Whimsy world, Sarah, caverns, lesson sequence, dialogue, collision, progression and save format remain included. All 135 checked baseline visual/audio/font assets and all 58 v0.31 PNG assets are byte-identical.

## Verification

Godot 4.4.1 source checks: family tutorial 112/112; treasure 100/100; deep routes 596/596; tutorial overhaul 15/15; family layout 20/20. Title/menu flow also passed. The compiled Windows EXE's embedded resource pack passed a separate 16-check load run covering all chapter scene paths, five chest actors, both 3D models, dialogue pause/resume and tutorial lesson startup. Total counted checks: 859, plus the menu-flow suite.

The Windows export explicitly includes the chapter and Whimsy JSON data. The output is an x86-64 PE executable with all game resources embedded. No editor is needed to play. The source export preset is portable; install the matching Godot 4.4.1 Windows export template before exporting it again.

Screenshots are native Godot renders with staged inspection positions and held world clocks, rather than a continuous keyboard playthrough. The current validation used Linux and Mesa software OpenGL; it is not a Windows performance benchmark. The Windows EXE has not been launched on a physical Windows PC here.

## Model limitations

The supplied Meshy models have no skeleton, skin or animation clips. Their current performance uses whole-model breathing, turns and pose accents. Independent elbows, wrists, fingers, facial acting and garment animation require a rigged model export. The original paintings remain available in the project.

## Open and build

Open project.godot in Godot 4.4.1. Run the project and choose Begin adventure, or run godot/training_lagoon.tscn directly. For the standalone Windows build, extract its ZIP and run Mermaid Adventure.exe.
