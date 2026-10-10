# Miguel's Lagoon asset pack

Standalone assets for Chapter 2, internally `stage === 1`, in Mermaid-Adventure-9.2.html. The uploaded HTML is unchanged.

## Contents

Six enemies, each with four viewing directions and two poses (48 frames). Eight environmental texture modules, each with three views (24 frames). All final PNG atlases preserve generated transparency. manifest.json records the actual image dimensions and integer pixel crop rectangles; do not assume the requested generation resolution was returned.

Enemies: Maraca Snapper, Ribbon Ambusher, Bubble Bandit Otter, Orchid Hermit, Drumback Turtle, Disco Cuttlefish. Views: left profile, left three-quarter, right three-quarter, right profile. Poses: idle and attack windup. These are discrete pose/view images, not complete frame-by-frame animation loops or full 360-degree turntables. For a first integration, use code-driven bobbing, tilt and recoil; a future animation pass can add attack, recovery and defeat frames.

Environment: emerald root arch, golden mica sandbank, waterfall-polished stone, sunken mosaic arch, moonflower garden, rainbow current ribbon, bubble orchid and lantern seedpods. Views: frontal, oblique left and oblique right. These are transparent textured cutout modules, not seamless repeating material tiles. Place and overlap modules along existing level scenery. Keep navigable openings clear.

## Use

Serve this folder over HTTP alongside the game and import atlas-renderer.mjs. `loadLagoonPack(new URL('./level2-pack/', location.href))` loads the manifest and atlases. `pack.draw(ctx, 'maraca-snapper/idle/left-profile', screenX, worldY, 160)` renders a full source cell at the requested cell width. Transparent padding is included in that width: use manifest content bounds to tune visual scale. Environment frame IDs follow `emerald-roots/frontal` etc. All enemy pivots default to cell center; floor scenery defaults to bottom center. The manifest includes visible content bounds for further pivot calibration.

This renderer is a drawing utility. It does not add spawning, AI, collisions, rewards, save state, sound or UI to the game. Enemy behaviour is specified in enemies.json for the next implementation. Proposed tuning is untested gameplay guidance.

## Integration rules

- Gate new content to Chapter 2 (`stage === 1`) and exclude the Blackwater Tunnel interlude.
- Preserve Miguel's existing starfish volleys, swoop and green vulnerability halo.
- Keep new enemy roster additions bounded. Replace selected repeated encounters instead of doubling every new enemy through doubleStoryEnemyRoster.
- Introduce one enemy mechanic at a time; always leave a safe lane. Avoid combining a lunge, sound ring and current push simultaneously.
- Telegraph danger using shape and sound as well as colour. Respect reducedMotion by disabling incidental bobbing and excessive flashes.
- Collision shapes must use body-sized circles/ellipses, excluding decorative fins, leaves and transparent cell padding. Root and mosaic arches need separate side collision shapes; never use one solid rectangle covering the opening.
- Current ribbons are visual indicators unless later implementation explicitly adds forces. Moonflowers, orchids and lanterns are decoration unless explicitly assigned interactions.
- Coin Dash retains its coin target and timer. Otter loot always returns captured coins at defeat, reset or escape; coins can never become unreachable.
- Use the existing score/health/boost/checkpoint APIs; don't invent parallel state.
- Use drawImage source rectangles rather than stretching the entire atlas. Keep effects behind sprites, and apply horizontal/vertical flips only deliberately.

## Quality and provenance

Created with the built-in image generator. prompts.json records the generation and correction prompts. Source generation sheets were visually reviewed; final transparency, dimensions, frame boundaries, nonempty cells and unchanged source HTML hash were checked. Runtime drawing utility syntax is checked. No in-game integration or playtesting was performed.
