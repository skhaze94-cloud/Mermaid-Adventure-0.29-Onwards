# v0.27 — Character Harmony

Import the root `project.godot` into Godot 4.3 or newer, wait for asset import, then press F5. Extract each release into a fresh folder.

This update focuses on character assembly and performance. Sarah’s painted hip now sits beneath and overlaps her shaped waist, and both parts share the torso hierarchy. Her fuller arms use distributed elbow and wrist arcs, with fixed shoulder roots. The arm mesh uses 32 columns and nine rows; the tail uses 64 columns and 13 rows. Arms now update every rendered frame. Eighteen continuous body/tail loops contain 72 samples each, with tangent-continuous interpolation.

King Daddy and Queen Antonella use their original 1024 × 1536 transparent source artwork and persistent 40 × 56 skins. Their wave, cast, hug, dash, swim and celebration targets blend over time, with softer hand, hair and fabric follow-through. Their tutorial scale and ending composition have been reviewed alongside Sarah. Antonella’s palace appearance uses the same source artwork and consistent height.

Avina retains her infant proportions and protected follower behavior. She has smooth happy reactions, baby paddles, follower banking and a short tail wiggle. Bubble remains her only gameplay action.

Shared creature portraits now have species-specific fin, claw, tentacle and tail movement, per-frame detail in high quality mode, and short premultiplied-alpha transitions between combat portraits. Combat cues, collisions and hit timing retain their original logic. Bosses use 48 × 32 skins and eased attack/recovery presentation. Gentle motion and economy rendering remain supported.

See [CHARACTER-HARMONY-VALIDATION.md](CHARACTER-HARMONY-VALIDATION.md) for validation. The family tutorial, branching dialogue, Avina’s hide-and-seek, both companion choices and the complete eight-chapter route remain included.

## Previous release documentation

# v0.26 — Family Lagoon

Begin adventure now opens the fully upgraded family tutorial. Choose a chapter still allows direct access to any of the eight chapters. Import the ROOT project.godot in Godot 4.3+, wait for asset import, and press F5.

## The HTML tutorial, rebuilt in Godot

Based on the supplied Sarah-Maria-Family-Adventure-8.2(2).html: the original 7,600-unit reef route, all eleven collision formations, three optional relic chests, three steering rings, reef navigation, boost, sky jump, aerial crossing, Antonella’s heart and eight-second gold gifts, powered jump, Professor Puff / Sir Wobble / Noodle, and the three-hit King Daddy training fight. Training protects the last three hearts. Gift power refills until the powered jump is completed.

King Daddy retains Thunder Teapot, Triple Tickle Bolt, The Cloud of Mild Concern, Royal Wobble Wave, Dad Dash, and Bubble Beard Blast, followed by a clear green vulnerability window. Spells are slow, readable, and harmless enough for practice. King Daddy is also available as an optional swimming hero before the final trial.

New transparent body artwork preserves the parents’ original costumes and identities. Weighted connected meshes add shoulder gestures, cloth/cape lag, breathing, casting, waving, dashing, and celebration. Original expression portraits are recovered from the HTML. Antonella coaches, supplies gifts, and demonstrates Pearl Fan, Crown Halo, and Pearl Wave. Her upgraded body artwork also appears in Pearl Palace.

## Baby Avina

Avina arrives only after the practice fight, parental praise, and a hide-and-seek invitation. Three short rounds near the portal place her behind real foreground coral textures: watch for her little bow and tiny bubbles, then swim close for peekaboo. No time limit or penalty.

After finding her, the portal offers Bring Avina or Go alone. Both choices have a King Daddy farewell followed by Antonella’s response. Earlier playful, curious, or earnest dialogue choices affect those responses. The baby stays with both parents if Sarah goes alone.

A travelling Avina is a protected follower. Her only gameplay action is a small lavender bubble: it joins Sarah’s cast or helps with a nearby creature, with a 2.8-second cooldown and the shared eight-shot cap. She does not dash, jump, collide, collect, take damage, or touch bosses herself. She follows through all adventure chapters, waterfall transitions, retries, and restarts. Her baby wiggles respect Gentle motion. Completing the tutorial keeps Sarah’s learned bubble available in Highland.

## Dialogue and controls

Nine core conversations have three reply choices, a follow-up tip branch, and expressive portraits. Conversations pause gameplay; choices support mouse, touch, keyboard, and controller focus. Responsive dialogue scrolls to focused options. Landscape gameplay is recommended; the existing portrait pause remains available.

Move: arrows/WASD, stick, or touch pad. Boost: Space/controller A. Jump: J or Shift/controller B. Bubble: B or Z/controller X. Pause: P/Escape. Restart: R. Begin again from the menu for a fresh companion choice.

## Validation

See FAMILY-LAGOON-VALIDATION.md for test scope and platform limits. Sarah’s v0.25 18-loop / 432-pose animation library, full adventure route, backgrounds, grounding, controls, audio and scoring are retained.

---

Previous release documentation follows for architecture/history; the v0.26 sections above govern the tutorial.

# Sarah Maria — Mermaid Adventure v0.25: Hero Arms

Sarah’s arm proportions and animation update, built on v0.24’s grounded reef scenery and the existing continuous swimming rig.

## New in v0.25 — Hero Arms

- Longer near/far arms, with fuller upper arms and forearms and a gentle taper toward the wrist. The sleeves remain tucked into the same shoulder sockets; the original skin, sleeve and hand painting stays aligned with Sarah’s body.
- Elbow and wrist pivots now follow the sloping painted anatomy rather than bending above it. Smooth skinning keeps the shoulder attachment fixed during swimming, gestures, turning and jumping.
- A more open breaststroke: extended reach, broad catch and sweep, and a relaxed recovery with less extreme elbow folding. Both arms stay synchronized, with subtle perspective differences.
- A longer streamlined dash reach, gentler idle elbow bend, and retained casting, greeting, reward and jump gestures. Reduced motion and economy modes remain supported.
- Motion library tripled from six to eighteen loops: 432 interpolated poses. New hover, drift, cruise, sprint, descend, bank, settle, reach, greet, cast, recovery and celebration performances complement the original six loops.
- Bounded torso banking, collar counter-motion, hair follow-through and coordinated fin lag add depth while the head and shoulders retain their attachments. Three speed/direction profiles enrich the synchronized breaststroke.
- No movement, collision, reward or chapter changes. This is an arm geometry and performance update using the existing painted assets.

All twenty regression suites pass. The new depth suite runs 1,086 checks of distinct pose libraries, actual context selection, transition continuity, reduced motion and restart. The tail suite now runs 1,914 checks across all eighteen loops. The strengthened breaststroke suite has 1,689 checks, including wider hand travel, forward dash reach, recovery-fold limits, smooth transitions, shoulder continuity, anchored texture UVs and reduced-motion reset. Native pose captures and an enlarged in-game preview show the updated rig; preview enlargement does not change the playable character’s scale.

## Retained from v0.24

- A continuous world-anchored reef floor replaces the visual gap beneath plants. The lip follows a gentle irregular contour; small painted reef caps blend its edge into each chapter’s existing painting.
- Plants share the exact ground-height function with their shadow plane. Roots are buried slightly; layered contact shadows soften the join. Highland’s far and middle gardens now have their own coherent parallax terraces, and foreground roots no longer move when the viewport height changes.
- Floor formations extend their painted feet into the reef bed. Elevated ledges have recessed, softly shaded stone buttresses with fixed-scale texture detail. These are background supports, not new collision obstacles.
- Highland now uses one formation cap per obstacle instead of overlapping two different rock illustrations. Native directional relief remains available; economy mode still skips expensive normal sampling.
- Carved portals now stand on recessed stone plinths. Palace column feet meet the ground with contact shadows. Miguel keeps its own flora, now using the shared planting and shadow conventions.
- Near-floor treasure chests stand on small reef pedestals and no longer pulse or bob. Mid-water rewards retain their intentional floating presentation.
- Original routes, collision rectangles, rewards, enemy and boss gameplay remain intact. All eight chapters receive the same grounding conventions while keeping their individual panoramic artwork and colour palettes.

The nineteenth suite, `grounding_test.gd`, checks original chapter collision data, exact plant/terrace alignment through three camera positions, world-fixed foreground roots, and the single Highland formation layer (487 checks).

## Retained from v0.23

- Thirteen original synthesized sound effects: pearls, treasure, hearts/crystals, checkpoints, victory, boss defeat, UI, boost, splash, swimming, impact, boss hit and bubble casting. Three seamless stereo loops give reefs, deep kingdoms/tunnels and the waterfall distinct ambience.
- Independent Music, Sound effects and Ocean ambience sliders, saved in the existing preferences. A ten-player effects pool limits overlap and lets major rewards take priority. Gameplay effects stop on pause; the victory flourish continues over results.
- Decorative fish schools with gentle schooling, tail flicks and local scattering around Sarah, plus drifting underwater plankton. World-space culling, fewer fish in economy mode, and static schools in reduced motion. These creatures never block Sarah or affect scoring.
- A fixed pool of twenty world-space feedback ripples for collection, impacts, boosts, checkpoints and boss hits. They follow the camera, clear on retry, and use brief static cues in reduced motion.
- Shared connected boss meshes: Miguel’s wings undulate, Flip/Nessie/Baron Bite have subtle tail/body motion, royal characters breathe and react, Duke keeps his atlas expressions, compact boss headers keep faces clear, and all new actors have hit/recovery/defeat performances. Queen/King Daddy and Baron Bite select their existing attack frames. Carlo retains his four-pose rig with gentler hit/departure motion and reduced-motion handling.
- Imported routes, attack schedules, boss health and collision shapes are retained. This update adds performance and feedback; the larger kingdom puzzle/pacing redesign remains future work.

Sound files are original deterministic synthesis, with no external sample dependency. The rebuilding source is `godot/tools/make_ocean_audio.py` (Python/NumPy/SciPy); the delivered WAV files are ready for normal Godot import. Code-built ambient fish and native mesh deformations use the existing artwork.

## New in v0.22

- One persistent ocean transition for starting, continuing and returning to the lagoon: eased iris, chapter crest, title and introduction line.
- Godot background scene loading behind the transition, with duplicate-input protection, inactive gameplay during the handoff, and recovery if a chapter cannot load. Reduced motion uses a short dissolve.
- Music fades across chapter boundaries; the shared Music bus still respects your volume setting.
- Chapter browser includes painted previews, shorter display names with full-name tooltips, and reliably starts at the top.
- Story typography throughout the HUD, readable backed gameplay hints, warmer pause copy, eased modal reveals, compact continuation buttons and an adventure-complete heading.

All 19 current suites pass. The retained `ocean_alive_test.gd` adds 117 successful checks of audio routing/mutes, bounded voices, chapter ambience, accepted actions, duplicate awards, reduced motion, boss reactions and retry reset. The scene-flow suite exercises the actual threaded/animated handoff, reduced motion, duplicate presses, missing paths and return from pause. 24 native chapter entry/rock/boss renders and three menu viewports pass. Native OpenGL captures show the revised title, chapter browser, Highland, pause screen, ocean iris/chapter cards and Shadow Crab Kingdom.

Godot APIs: [background loading](https://docs.godotengine.org/en/4.3/tutorials/io/background_loading.html) and [Tween](https://docs.godotengine.org/en/4.3/classes/class_tween.html).

## Import and play

Extract the ZIP into a **new empty folder**. In Godot **4.3 or newer**, import the root `project.godot`, wait for asset import, then press **F5**. Standard Godot is sufficient; .NET is not required. Do not overlay v0.15/v0.16.

Begin adventure starts Highland. Choose a chapter opens any of the eight scenes directly. Training is optional and continues into Highland. Defeat a chapter’s boss, swim to the portal, then select Next chapter on the native results menu. Nessie’s results return to the main menu. Pause, restart and menu return release held controls and clear transient attacks.

Main route: **Highland → Shadow Crab Kingdom → Miguel → Blackwater Tunnel → Pearl Palace → Rana Rex → Nessie → menu**.

| Chapter | Source length | Source formations | Source minor enemies | Boss health |
| --- | ---: | ---: | ---: | ---: |
| Family Training Lagoon | 7,600 | 11 | 0 | King Daddy: 3 |
| Highland Gold | 29,640 | 23 | 68 | Carlo: 3 |
| Shadow Crab Kingdom | 14,300 | 7 | 27 | Duke: 10, Flip: 8 |
| Miguel’s Lagoon | 33,150 | 10 | 36 | Miguel: 4 |
| Blackwater Tunnel | 10,270 | 12 | 0 | Baron Bite: 8 |
| Pearl Palace | 37,050 | 9 | 40 | Queen Antonella: 5 |
| Rana Rex’s Rainbow Ruin | 41,600 | 6 | 18 | Rana: 6 |
| Nessie: The Crown Thief | Source Rana arena; native exit 5,500 | 0 | 0 | Nessie: 7 |

The screenshot’s Shadow Kingdom parser failure came from a custom `draw_ellipse` helper sharing a name with a newer CanvasItem built-in, with a different signature. It is renamed `_paint_oval` throughout. Scene/resource loading no longer depends on that override. The v0.16 sliding and overlap recovery fixes remain active in every chapter.

## Controls

Move: WASD / arrows / controller left stick. Boost: Space / controller B. Jump: J or Shift / controller A. Bubble: B or Z / controller X. Pause: P or Escape. Restart: R. Reduced motion: F3. Economy: F4. Touch uses the native pad and separate action buttons. Play gameplay in landscape.

Sarah earns Bubble after Carlo; later directly selected chapters start with it unlocked. Basic new bosses telegraph attacks and show a green ring for boost damage. Rana includes a warned horizontal laser; Nessie and Baron Bite rush; Queen fires pearl fans. Three relic chests provide optional training exploration. Palace columns remain open decoration, with source rock formations owning collision. Blackwater remains readable with simple darkness rather than the full HTML spotlight system.

## Implementation and scope

`source/levels-v82.json` preserves data extracted from the actual supplied setup functions; `source/PROVENANCE.md` records its hash and adaptations. `chapter_data.gd` handles source conversion and safe spawn positions. `adventure_run.gd` owns the route catalog and score ledger. `basic_chapter.gd` shares the native movement, collision, scoring, checkpoints, HUD and controls with Highland; existing Shadow/Miguel controllers retain switches, the paired boss and lagoon creature pack.

This is the requested **basic integration**, not a fully faithful reimplementation of every HTML dialogue, tutorial lesson, cinematic, boss phase or moving architectural effect. New bosses use simple native attacks and source health/locations; later polish can expand them without changing the scene flow. Nessie’s original twist arena is separated from Rana to avoid an empty 40,000-unit walk after the finale. No persistent journey save is added.

## Validation

Godot 4.3 Linux headless: the ten existing logic, controls, animation, scoring, resource and layout suites pass. The first-three-chapters suite passes. The complete-adventure suite exercises all eight actual chapter-select buttons, source formation/enemy counts, basic boss hit openings, checkpoint retries, native result buttons, optional training and every scene transition through the finale: **95 checks, zero failures**. The collision suite covers all eight scenes: **1,153 checks, zero failures**.

Native OpenGL Compatibility/llvmpipe: clean editor import and **16 chapter entry/boss renders plus three chapter-menu viewports** pass. ZIP CRC and directory-first fresh extraction/import are checked before delivery. This environment has Godot 4.3; Windows and the user’s newer Godot build were not run here. The specific newer-engine method-name conflict is removed. Headless dummy-renderer fresh import can report shader-global errors; the real OpenGL importer renders those same shaders successfully. Final device performance, audio output and balance need device playtesting.

Run suites with `godot --headless --path . --script res://godot/complete_adventure_test.gd` and similarly for `rock_collision_test.gd`, `journey_test.gd` and the other `*_test.gd` scripts. `capture_complete_adventure.gd` requires a real OpenGL display. `package_project.py OUTPUT.zip` builds a directory-first archive and validates its CRC before publishing the output file.


## Retained v0.18 terrain texture pass

New hand-painted stone material replaces flat Shadow Crab panels and basic
rock cores in Miguel, Blackwater, Pearl Palace, Rana, and Training. Highland
gets the same textured backing behind its existing relief sprites. New transparent reef formations replace rectangular panel silhouettes. Stone
backing stays behind their centers at a fixed world scale. Painted gardens add
organic edges; chapter-specific tinting keeps each setting distinct.
Nessie’s open arena gets reef gardens. Hanging obstacles get painted reef
formations; the imported chapters now use carved seashell portal arches. Shadow and Miguel panoramas now cover the
viewport without repeating seams. Surface paintings align with the gameplay
waterline. Flip now has a dedicated painted dolphin sprite. All collision data and combat remain unchanged.

Asset: `godot/assets/reef-stone-v018.png`. Generated using the built-in imagegen
tool, prompt recorded in `godot/assets/texture-pass-v018.md`.


### Texture release validation

Godot 4.3 Compatibility renderer (Linux, Mesa llvmpipe): all 13 existing
regression suites passed, including 95 complete-adventure checks and 1,153 rock
rescue/collision checks. Native render captures reviewed across all eight
chapters (24 stage views, three menu sizes and seven portal views). All referenced
raster files decoded successfully. Fresh directory-first ZIP extraction, file
hashes, resource references, native editor import and title startup passed.
Windows/device performance has not been measured; use an empty folder and let
Godot import the assets before playing. Original v8.2 level data is unchanged.


## Retained v0.19 Sarah Maria animation pass

Menu-reference face artwork: registered smile, excited and blinking head frames.
Softer child proportions, shorter articulated arms and longer flowing back hair.
The tail is now one connected painting on a 32-segment centerline with seven
mesh rows. The hip stays anchored while the middle curls and the fluke follows;
bending preserves the centerline length. Fin effects follow the deformed tail.

Eighteen 24-pose cycles (six base loops plus twelve contextual performances) supply 432
interpolated key poses, with continuous loop tangents and blended state changes.
These are native rig poses, not 144 separate bitmap frames. Existing bubble-cast,
reward, greeting, impact, celebration, launch and landing performances remain
interruptible. Natural blinking and action expressions give the face more life.

Reduced-motion and economy modes reset tail deformation, and pause/restart clear
the performance state. Character visuals do not move collision geometry or
change input, movement, damage, score or chapter data.

New assets: `assets/sarah-expressions-v019.webp` and `assets/sarah-tail-v019.webp`.
Built-in imagegen, using the menu art as the identity reference. Lossless WebP
encoding verified identical to the generated RGBA pixels. Prompts are recorded
in `assets/sarah-art-v019.md`.


### v0.19 validation

All 14 regression suites passed, including 738 new fluid-motion checks, the
existing jump/gesture tests, 95 complete-adventure checks and 1,153 collision
checks. Native OpenGL captures cover every chapter and the new character’s
greeting, swim, rise, turn, boost, cast, impact, reward, celebration, reduced-motion
and economy poses. A 144-frame native motion preview shows idle, swim, boost and
tuck. New artwork and native rendering use the same shared rig in every chapter.


## v0.20 definitive Sarah polish

Closed the visible gap between neck and collar. The slightly smaller head has
a deeper painted overlap and gentler nodding around the neck attachment.
Back hair now follows the skull, and the tail inherits the torso transform,
so pitching and foreshortening cannot pull those sockets apart. Tail curvature,
tucks, expressions and all eighteen motion cycles are retained. Both arms and rear
painted parts now have reserved render layers above scenery. Removed duplicate
pelvic fins and unused legacy hair/hip joints. The menu identifies this as v0.20.

All 15 regression suites pass on Godot 4.3 Linux. The new continuity suite checks
actual collar alpha under the neck across 1,440 posed frames in both directions:
4,325 checks with zero failures. Existing fluid-motion, jump, chapter-flow and
rock-rescue checks remain passing. Native OpenGL captures cover the action poses,
all eight chapters, and a 144-frame idle/swim/boost/tuck preview. The final ZIP is
CRC checked, freshly extracted and imported in the native editor.


## v0.21 arms and body pass

Swimming now uses a synchronized breaststroke: forward reach, catch, outward
sweep, bent-elbow pull and recovery. A continuous loop drives the shoulders,
elbows and wrists; both hands stay on the same stroke rather than alternating.
Dashing smoothly replaces paddling with a forward reach and straighter elbows.
Bubble casts, greeting, impacts and aerial joy continue to take priority.

The torso rectangle is 62 x 60 instead of 70 x 67, reducing its area by 21%.
The lower bodice also tapers toward the hip; the collar and shoulders stay fixed.
Head size stays unchanged and its neck is repositioned to keep the painted
collar overlap. Arms are slimmer, the far shoulder sits inward, and the 16-column
five-row arm skin follows the elbows with greater detail. Existing tail bends,
tucks, scenery, physics, chapter data and menus remain in place.

All 16 regression suites pass on Godot 4.3 Linux, including 1,449 new arm-motion
checks and 4,325 neck/collar, hair and tail continuity checks. The arm tests
measure the deformed fingertip path, synchronized strokes, locked shoulder
geometry and UVs, smooth dash transitions, a held dash pose, reduced-motion
reset and restart. The native OpenGL preview records 216 frames (nine seconds)
of idle, breaststroke, dash and tuck. Chapter captures and fresh ZIP import
are also verified. Windows and the user's newer Godot version were not run here.
