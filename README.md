# Mermaid Adventure - v0.8.0 Boss Polish

An eight-chapter painted ocean adventure starring Sarah Maria, with the family lagoon tutorial, chapter selection and Avina's optional companionship.

Adventure Polish adds checkpoint saves and Continue, per-chapter stars/bests, a whole-adventure finale, accurate charge/cooldown feedback and distinct, telegraphed later-boss volleys. It removes duplicate projectile drawing, prioritises immediate threats and stops settled results from rebuilding every frame. The original paintings, animations and full-quality defaults are retained. [Review fixes and validation](https://github.com/skhaze94-cloud/Mermaid-Adventure-0.29-Onwards/blob/feature/opal-current-v06/godot/ADVENTURE-POLISH.md).

Opal Current adds pearlescent charge bubbles, 28 painted effect sprites, colourful enemy/boss attacks and fitted hit-opportunity shells. Quick release fires Pearl Pop; hold 0.35 seconds for Prism Bloom or 1.35 seconds for Royal Aurora, then release. Mint open petals and a star mark a valid hit; amber shields and lavender arcs show guards and hit cooldowns. The original paintings, character detail, audio and authored animation remain. [Update review](https://github.com/skhaze94-cloud/Mermaid-Adventure-0.29-Onwards/blob/feature/opal-current-v06/godot/OPAL-CURRENT.md).

The retained v0.5.1 update improves performance while preserving the original artwork, mesh detail, animation sampling, lighting, water effects and full-quality defaults. It reuses indexed skin buffers, caches fixed deformation and facial-feature calculations, loads chapter artwork with its own scene, and avoids hidden scenery and unchanged HUD work. Performance measurements and validation are documented in [the performance review](https://github.com/skhaze94-cloud/Mermaid-Adventure-0.29-Onwards/blob/performance/v05-preserve-visual-quality/godot/PERFORMANCE-REVIEW.md).

Extract the playable ZIP into a new empty folder. Import the root `project.godot` in Godot 4.4 or newer, wait for asset import, then run the main scene. Validated with Godot 4.4.1 on Linux using the Compatibility renderer. Development captures, tests, reports and unused decorative controls are excluded from the playable ZIP.

Swim with arrows, WASD, controller stick or touch pad. Boost: Space / controller B. Jump: J or Shift / controller A. Bubble: hold B or Z / controller X / touch Bubble, then release. Pause: Escape / P / controller Start. Play in landscape; portrait pauses safely. Audio, Gentle Motion, Economy graphics and touch preferences are available in Options.

Princess Polish Sarah triples the sampled body, arm and performance tracks and the painted hair, face, torso, arm and tail articulation points relative to v0.4. Three flowing interpretations add delayed reach, catch and release motion; 18 aerial variations replace six. Boost blends into a new torpedo pose with near-straight elbows, aligned shoulders and tail-driven propulsion. Layered shaded droplets and projected vortex trails add depth to swimming, including waterfall movement. These are effects in the existing 2D renderer.

The v0.4 interface and scenery cleanup remains. Original artwork, physics, controller mappings and connected adventure progression are preserved. Gentle Motion and Economy settings suppress secondary articulation and the new wake.

The repository retains the original v0.28 baseline and release history. Review details: `godot/V05-PRINCESS-REVIEW.md`; checks: `godot/validation-v05.json`. The original MermaidADVENTURE repository is unchanged.

Bubble Polish gives charged shots faster travel (700 / 780 / 860 units per second), distinct release pitches, a one-time Prism readiness cue and short charged-hit controller feedback. Royal Aurora deals four ordinary-enemy damage with 0.45s recovery; charge thresholds, boss damage caps, guard rules, input cancellation and visual pools are retained.

[Bubble balance and validation](godot/BUBBLE-POLISH.md).

Boss Polish adds truthful world-locked warnings, clearer encounter cues, recovery windows for charging, distinct volley pacing and consistent victory feedback. [Encounter review](godot/BOSS-POLISH.md).
