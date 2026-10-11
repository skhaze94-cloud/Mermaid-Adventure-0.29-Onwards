# Sarah v0.29.7 — Dynamic Arms

This update focuses on arm motion and the overlaps affected by it. Sarah's original painted artwork, face details, torso motion and waist treatment are retained.

## Findings and changes

The previous elbow deformation spread the rotation across a long portion of the forearm. The wrist pivot also sat too far into the hand. As a result, a stroke could look like one curved paddle rather than an upper arm, forearm and hand working together.

The elbow bend is now concentrated around the painted joint. The forearm carries that rotation forward, and the hand flexes around a wrist pivot taken from the shaped rest mesh. The near and far paintings have different anatomical proportions, so each has its own elbow and wrist coordinates. The sleeve attachment remains fixed, and the texture coordinates stay attached to the original artwork.

The two elbows and wrists have independent damped responses. Shoulder movement adds a small load to the elbow; the wrist then counter-flexes and settles after the pull. Moving-target integration reduces differences between 30, 60 and 120 Hz. Momentum clears on restart and when Gentle Motion or Economy settings are selected. A paused frame does not advance the joints.

The regular strokes have stronger, separately phased wrist pitch and clearer elbow recovery. Breaststroke remains synchronized; crawl and climbing strokes remain alternating; sidestroke retains its different leading and trailing arms. Boosting keeps a compact forward reach, with restrained hand motion. Greetings, casts and aerial poses use the same connected skins and joint controller.

The review caught raised forearms crossing facial landmarks during aerial motion. Shoulder reach now eases toward a sideward raised pose instead of continuing through the face. A small hysteresis band also prevents near/far arm layers from repeatedly switching when yaw hovers around the depth threshold.

## Review across Sarah's parts

| Area | Review and result |
| --- | --- |
| Sleeves and shoulders | Fixed attachment band; actual painted-alpha overlap with the moving bodice checked in both facings. |
| Elbows, forearms and wrists | Joint angles bounded; painted triangles checked for collapse or inversion; original UVs retained. |
| Hands | Wider wrist response in regular strokes; counter-flex and gesture follow-through; original palm and finger painting retained. |
| Eyes, nose and mouth | Front-arm alpha checked against facial landmarks every simulated frame in the stroke, gesture and aerial review. Raised-reach overlap corrected. |
| Head, ears and jaw | Existing detail and continuity suites retained; native rendered poses reviewed alongside the arms. |
| Hair | Connected roots and both back-hair skins reviewed; intentional arm/hair layering retained. |
| Torso, neck and waist | Independent torso controller retained; collar, shoulder and waist continuity suites passed. |
| Tail and fins | Painted tail geometry reviewed through strokes and aerial curls; existing airborne viewport-clearance tests retained. |
| Waterfall | Native gameplay captures checked for climb, dive and boost, in addition to the contextual stroke preview. |

## Validation and preview

The full regression run contains 31 suites. The expanded arm review covers all 12 strokes in both facings, five gestures in both facings, six aerial styles in both facings, abrupt speed/direction changes, restart, pause, Gentle Motion, Economy and 30/60/120 Hz response. It checks the actual production geometry and source texture alpha. Results are recorded in `validation-v0297.json`.

The fresh-download check extracts the ZIP, compares every extracted byte, imports and starts the project, then runs eight suites against the extracted copy, including the expanded arm review. `project.godot` remains at the archive root.

`capture_sarah_arm_motion.gd` records a 60-second production-rig preview with a full-body view and an intentional tracking close-up. It includes idle, all 12 strokes, six aerial styles, five gestures, waterfall climb, turning and recovery, with additional screenshots at different stroke phases. Native compatibility rendering checks the shader-driven face and the painted layers that headless geometry checks cannot show.

No failures remained in the tested poses. These checks cover the current animation library and representative transitions; they are not a guarantee against every possible future pose or external asset change. All 90 binary assets from the v0.28 baseline remain unchanged.
