# Mermaid Adventure v0.38 — Pearl Storybook

Warm ivory/seafoam dialogue and HUD, painted health/power charms, clearer tutorial choices and real active-gift feedback. Read [PEARL-STORYBOOK-038.md](PEARL-STORYBOOK-038.md) for changes, validation, measurements and limitations; the design specification is [PEARL-STORYBOOK-DESIGN.md](PEARL-STORYBOOK-DESIGN.md). Current evidence: verification/pearl38. Original adventure, controls and character rigs preserved.

# Mermaid Adventure v0.37 — Sarah Connected Motion

Focused Sarah turn, waist, casting and animation-ownership update. Read [SARAH-v037-REVIEW.md](SARAH-v037-REVIEW.md) for the changes, measurements and remaining facial-view limitation. Complete inherited adventure and original assets preserved. Current evidence: verification/sarah37.

# Mermaid Adventure v0.36 — Connected Grace & the Living Royal Family

Complete Friends Cavern source with a connected Sarah pelvis/tail/turn update and genuinely articulated tutorial parents. Original models, paintings, dialogue, progression and saves are preserved. Read CONNECTED-GRACE-036.md for ownership, visual findings, measured costs and limitations. Current evidence is in verification/connected36. Older notes follow.

# Mermaid Adventure v0.35 — Sarah Grace

The complete Friends Cavern adventure with a focused Sarah movement update: clearer stroke and glide, soft visual stops, intention-led turns, quieter arms, connected tail flow and cleaner ordinary jumps. Movement physics, paintings, all characters, caverns, rewards and saves are preserved.

Open project.godot with Godot 4.4.1. Read SARAH-GRACE-035.md for changes, ownership, measurements and limits. Current evidence is in verification/grace35. Earlier release notes follow.

# Mermaid Adventure v0.34 — Friends Cavern

A complete Godot 4.4.1 project. All fifteen caverns now have named friends, saved 50-point hellos, continuous painted descents and softer limestone walls. Six new characters join the existing cast.

Read FRIENDS-CAVERN-034.md for locations, rewards, the full review, validation and performance limits. Current evidence is in verification/cavern34. Earlier release notes follow.

# Mermaid Adventure v0.33 — The Handcrafted Tutorial

A complete Godot 4.4.1 project. The tutorial now has individually placed painted gardens, distinct main barriers, natural grotto descents, different treasure supports and compact resident dialogue. Movement, collisions, lessons, progression, save compatibility and the rest of the Whimsy world are preserved.

Read TUTORIAL-BEAUTY-033.md for the full design audit, measured costs and limitations. Current evidence is in verification/tutorial33. Earlier release notes follow.

# Mermaid Adventure v0.32 — The Living Family Lagoon

This is a complete Godot 4.4.1 source project. It combines the fixed v0.27.1 game, the v0.30 painted reef update, v0.31 articulated treasure chests, the final v0.29 Meshy family integration, and this tutorial beauty pass.

Read TUTORIAL-BEAUTY-032.md for the complete review and current validation.

v0.27.1 — Family Tutorial Load Fix

Fixes a GDScript type-inference error that prevented the tutorial scene from loading. The existing family tutorial smoke run now passes all 112 checks. See verification/tutorial-load-fix.md.

v0.27.0 — Family Tutorial in Motion

Daddy and Antonella receive a tutorial-only character performance upgrade: finer cached body meshes, separate shoulder/elbow/wrist pose weights, connected head and torso movement, gentle breathing, gaze, hair and fabric follow-through, and distinct speaking/listening gestures. Dialogue animations continue while the tutorial world is paused; movement and game clocks remain stopped. Sarah, other chapters, game balance, save data, and the parent paintings are unchanged. See TUTORIAL-FAMILY-POLISH.md for the scope and implementation.

v0.26.0 — Sarah Flow & Continuity

All five Sarah audit improvements are implemented. Tested with Godot 4.5.1. Open SARAH-FLOW.md for artwork, animation, validation and performance details. This package includes the complete v0.25 Tutorial Overhaul and earlier Whimsy world.

v0.25.0 — Tutorial Overhaul

Read TUTORIAL-OVERHAUL.md for the revised tutorial grottos, roaming residents, dialogue and larger royal teachers. Earlier release notes follow.

v0.24.0 — Cute Reactions

Read CUTE-REACTIONS.md for the new resident performance and expression update. Earlier release notes follow.

v0.23.0 — Character Animations

Read CHARACTER-ANIMATIONS.md for the current animation update and coverage. Earlier release notes follow.

v0.22.0 — The Painted Reef

Focused barrier, platform and treasure-support finish. Read PAINTED-REEF.md for this release. The complete v0.21 world and its documentation follow.

# Mermaid Adventure — v0.21.0 Little Moments of Magic

Four optional interactions now inhabit the family tutorial and opening Highland: patient fish friendship, Dozy’s lantern welcome, Nori’s escaped letter and a three-instrument grotto. Twelve new painted assets, six distinct garden beds, a unique peekaboo garden and a clearer Daddy entrance enrich these two areas. The complete Whimsy 4.0 world and Sarah Definitive 2.1 remain. Read [the tutorial audit and release review](LITTLE-MOMENTS.md) for locations, checks, performance and limitations.

Retained Sarah Definitive 2.1:

Sarah's arms now attach to her deforming torso, with sleeve-root counterrotation and more elbow deformation detail. A single final coordinator owns shoulder attachment and visual orientation; action priorities protect casting, boosts, jumps and impacts from decorative gestures. New painted front and three-quarter views support turns without flattening her face. The opening performance has quiet rests, greetings, breathing and long glances toward the player and lagoon. Mesh buffers and topology remain cached while the face and tail use fewer sampled vertices. Controls, physics, save identity and the complete Whimsy 4.0 world are preserved.

Read [Sarah's release review](SARAH-DEFINITIVE-21.md) for before/after measurements, visual review, ownership and limitations. Use Godot 4.5.1 Compatibility. The five full-resolution new paintings and their 512-pixel runtime import settings are included. The release source preset contains no private signing credentials.

The retained Whimsy 4.0 world:

Sixteen new painted friends inhabit eight small neighbourhoods across the ocean. Explore sixteen real shell perches, little homes and distinct prop performances; meet both residents for one owned welcome reward, or simply swim past. Four new tunnel loops extend Blackwater, Pearl Palace, Rana and Nessie. The original eleven cavern complexes, Whimsy paintings, Nori’s routine, family dialogue and compact HUD remain intact. There are now fifteen optional cavern loops.

Read [the full Whimsy audit and field guide](WHIMSY-FOUR-AUDIT.md) for the cast, entrances, design findings and implementation. Godot 4.5.1 Compatibility; signed Android APK supplied separately. All 105 baseline art/audio hashes match, with sixteen new character paintings recorded separately in ASSET_PRESERVATION.json.

A calmer interface for Sarah’s painted ocean. Tutorial guidance is a single small card with contextual Help. Most lessons lead directly into swimming. Family conversations sit in a compact bottom dock, with one speaker per beat, one Continue action, optional Sarah replies, and Daddy’s costume tucked under Little extras. All 33 reply branches retain their warm, cheeky or curious farewell responses. The final bubble lesson has its own correct aiming and charging help.

The score and health panels are slimmer, locked Bubble controls stay hidden, temporary messages wrap, and neighbouring speech yields to active gameplay messages. Daddy’s trial uses one lesson card and a thin progress meter; his move-name billboard and duplicate boss panel are gone. Daddy is a smaller, calmer guide before the trial. Input clears when reading ends, controller Back dismisses optional replies before leaving a conversation, and dialogue respects an existing pause.

This update retains every painting, sound, cavern, helper, reward and checkpoint from v0.14. The Android app ID, signing identity and existing save location are retained. Build and verification use Godot 4.5.1 Compatibility. See CONVERSATIONS.md and VERIFICATION.md.

The Ocean Below expands the tutorial and both numbered opening stages, including the Shadow interlude, with eleven genuine cavern complexes. Swim down through marked seabed entrances, explore upper galleries and lower treasure pockets, then return through another shaft. Vertical camera travel, deep checkpoints, save/Continue and companion following support the new spaces. See DEEP_ROUTES.md for locations.

The retained Ocean’s Little Secrets update gives the opening Highland reach (before the waterfall) its own sanctuary: Nori’s slow postal round, independent antenna/mailbag/mantle movement, a dropped-letter-and-retrieval story, six authored garden beds with opening anemones, pollen bubbles and tiny peeking shrimp, and restrained world-anchored underwater sun shafts. Everything is optional scenery; Gentle Motion, Economy, pause and the original save/gameplay rules remain supported.

An eight-chapter painted ocean adventure starring Sarah Maria, with the family lagoon tutorial, chapter selection and Avina's optional companionship.

Whimsy II adds sixteen optional encounters across the eight chapters: tiny dream worlds, moonjelly tea parties, three shell-cottage villages, silly bubble mirrors and Nori the sea-slug postman. Float nearby to watch or chat; swim away whenever you like. Nori, Bramble the butler, Lumi the moonjelly and the village neighbours keep you company with occasional gentle comments after their stories. All ten original transparent paintings are included in art-originals/whimsy-ii alongside lossless runtime versions. Original v0.11 artwork and audio are byte-identical; see ASSET_PRESERVATION.json.

Import project.godot in Godot 4.4+. Play in landscape. This is a complete source project, not an Android APK. See godot/POCKETFUL-OF-WONDERS.md for encounter locations.

Living Reef adds one optional discovery to each chapter: three shell choirs, three little journeys with Pip the pearl seahorse and two gentle current trails. Wake choir shells with Boost or Sarah’s Bubble in any order; stay beside Pip through three stops and home; swim through the current hoops at your own pace. Each activity grants one owned Secrets reward and banks completion with a nearby checkpoint. There is no failure timer, and every existing boss, portal and tutorial requirement remains independent.

Sarah looks toward nearby discoveries and offers small greetings or reward gestures; Avina joins with brief baby reactions when she is travelling with you. Combat, charge, jump and impact animations keep priority. Gentle Motion retains the activities while using quieter expressions. Pip’s new painted cutout is stored as a lossless WebP with unchanged RGBA pixels. [Living Reef play guide and implementation notes](godot/LIVING-REEF.md) · [Pip art provenance](godot/assets/living-reef/README.md).

Adventure Polish adds checkpoint saves and Continue, per-chapter stars/bests, a whole-adventure finale, accurate charge/cooldown feedback and distinct, telegraphed later-boss volleys. It removes duplicate projectile drawing, prioritises immediate threats and stops settled results from rebuilding every frame. The original paintings, animations and full-quality defaults are retained. [Review fixes and validation](https://github.com/skhaze94-cloud/Mermaid-Adventure-0.29-Onwards/blob/feature/opal-current-v06/godot/ADVENTURE-POLISH.md).

Opal Current adds pearlescent charge bubbles, 28 painted effect sprites, colourful enemy/boss attacks and fitted hit-opportunity shells. Quick release fires Pearl Pop; hold 0.35 seconds for Prism Bloom or 1.35 seconds for Royal Aurora, then release. Mint open petals and a star mark a valid hit; amber shields and lavender arcs show guards and hit cooldowns. The original paintings, character detail, audio and authored animation remain. [Update review](https://github.com/skhaze94-cloud/Mermaid-Adventure-0.29-Onwards/blob/feature/opal-current-v06/godot/OPAL-CURRENT.md).

The retained v0.5.1 update improves performance while preserving the original artwork, mesh detail, animation sampling, lighting, water effects and full-quality defaults. It reuses indexed skin buffers, caches fixed deformation and facial-feature calculations, loads chapter artwork with its own scene, and avoids hidden scenery and unchanged HUD work. Performance measurements and validation are documented in [the performance review](https://github.com/skhaze94-cloud/Mermaid-Adventure-0.29-Onwards/blob/performance/v05-preserve-visual-quality/godot/PERFORMANCE-REVIEW.md).

Extract the playable ZIP into a new empty folder. Import the root `project.godot` in Godot 4.4 or newer, wait for asset import, then run the main scene. The earlier release was validated with Godot 4.4.1 on Linux using the Compatibility renderer. This source package includes native tests, original Whimsy II PNGs and preservation records; development captures and unused decorative controls are excluded.

Swim with arrows, WASD, controller stick or touch pad. Boost: Space / controller B. Jump: J or Shift / controller A. Bubble: hold B or Z / controller X / touch Bubble, then release. Pause: Escape / P / controller Start. Play in landscape; portrait pauses safely. Audio, Gentle Motion, Economy graphics and touch preferences are available in Options.

Princess Polish Sarah triples the sampled body, arm and performance tracks and the painted hair, face, torso, arm and tail articulation points relative to v0.4. Three flowing interpretations add delayed reach, catch and release motion; 18 aerial variations replace six. Boost blends into a new torpedo pose with near-straight elbows, aligned shoulders and tail-driven propulsion. Layered shaded droplets and projected vortex trails add depth to swimming, including waterfall movement. These are effects in the existing 2D renderer.

The v0.4 interface and scenery cleanup remains. Original artwork, physics, controller mappings and connected adventure progression are preserved. Gentle Motion and Economy settings suppress secondary articulation and the new wake.

The repository retains the original v0.28 baseline and release history. Review details: `godot/V05-PRINCESS-REVIEW.md`; checks: `godot/validation-v05.json`. The original MermaidADVENTURE repository is unchanged.

Bubble Polish gives charged shots faster travel (700 / 780 / 860 units per second), distinct release pitches, a one-time Prism readiness cue and short charged-hit controller feedback. Royal Aurora deals four ordinary-enemy damage with 0.45s recovery; charge thresholds, boss damage caps, guard rules, input cancellation and visual pools are retained.

[Bubble balance and validation](godot/BUBBLE-POLISH.md).

Boss Polish adds truthful world-locked warnings, clearer encounter cues, recovery windows for charging, distinct volley pacing and consistent victory feedback. [Encounter review](godot/BOSS-POLISH.md).

Journey Polish strengthens the complete route: collision-safe checkpoint retries, named rest pearls across long stretches, refreshed energy at checkpoints and Rana’s fight at the final approach. The family opening has responsive practice guidance, a direct return to play from conversations, and exact super-bubble teaching. Pooled effects reuse unchanged frame and impact calculations at full visual density. [Journey review, verification and remaining work](godot/JOURNEY-POLISH.md).

Whimsy adds eight small animated reef tableaux, proximity responses, restrained positive-event flourishes, a quiet stillness surprise and a slow pearl constellation on the title artwork. It reuses the existing paintings, keeps combat cues clear, supports Gentle Motion/Economy, and changes no gameplay or save rules. [Whimsy review and validation](godot/WHIMSY.md).
