# Mermaid Adventure - v0.5.1 Princess Polish Sarah

An eight-chapter painted ocean adventure starring Sarah Maria, with the family lagoon tutorial, chapter selection and Avina's optional companionship.

v0.5.1 improves performance while preserving the original artwork, mesh detail, animation sampling, lighting, water effects and full-quality defaults. It reuses indexed skin buffers, caches fixed deformation and facial-feature calculations, loads chapter artwork with its own scene, and avoids hidden scenery and unchanged HUD work. Performance measurements and validation are documented in [the performance review](godot/PERFORMANCE-REVIEW.md).

Extract the playable ZIP into a new empty folder. Import the root `project.godot`, wait for asset import, then run the main scene. Tested with Godot 4.4.1 on Windows using the compatibility renderer. Development captures, tests, reports and unused decorative controls are excluded from the playable ZIP.

Swim with arrows, WASD, controller stick or touch pad. Boost: Space / controller B. Jump: J or Shift / controller A. Bubble: B or Z / controller X. Pause: Escape / P / controller Start. Play in landscape; portrait pauses safely. Audio, Gentle Motion, Economy graphics and touch preferences are available in Options.

Princess Polish Sarah triples the sampled body, arm and performance tracks and the painted hair, face, torso, arm and tail articulation points relative to v0.4. Three flowing interpretations add delayed reach, catch and release motion; 18 aerial variations replace six. Boost blends into a new torpedo pose with near-straight elbows, aligned shoulders and tail-driven propulsion. Layered shaded droplets and projected vortex trails add depth to swimming, including waterfall movement. These are effects in the existing 2D renderer.

The v0.4 interface and scenery cleanup remains. Original artwork, physics, controller mappings and connected adventure progression are preserved. Gentle Motion and Economy settings suppress secondary articulation and the new wake.

The repository retains the original v0.28 baseline and release history. Review details: `godot/V05-PRINCESS-REVIEW.md`; checks: `godot/validation-v05.json`. The original MermaidADVENTURE repository is unchanged.
