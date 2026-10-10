# v0.29.4 — Definitive Sarah: completed review

Reviewed GitHub main `b4ba972` (v0.29.3) before integration. That release contained tripled samples and secondary shoulder/head/jaw motion, but explicitly lacked rendered visual verification. This update preserves that baseline and completes the visual, transition, geometry and fresh-install review.

## Motion points

| Track | v0.29.2 | Reviewed release |
| --- | ---: | ---: |
| Each of 36 body/fluke loops | 144 | 432 |
| Each arm, for 12 stroke styles | 144 | 432 |
| Breaststroke interpolation controls | 8 | 24 |
| Coordinated shoulder/head/jaw/chest profiles | 0 | 22 × 432 frames |

Existing movement libraries contain 15,552 body poses and 10,368 individual arm samples: exactly three times their v0.29.2 counts. The new performance library adds 9,504 frames across seven channels (66,528 scalar values). Sampling density does not change renderer FPS or gameplay speed; independent responses and timing changes supply the added dynamism.

## Findings and implementation

**Shoulders:** fixed sockets still looked like hinges despite secondary rotation. Both sockets now make small, independently phased catch/pull glides; the surrounding painted shoulder area follows. Near/far movement opposes during crawl and waterfall sculling, differs during sidestroke, and remains compact during boost. Sleeve and collar overlap was checked against the real painted alpha. Last-frame roll is removed before base interpolation, preventing accumulated rotation.

**Head:** one counter-rotation ratio was insufficient. A delayed stroke beat plus secondary harmonic, direction/gaze response, turn recoil and gesture-specific amplitudes now anticipate and settle behind the chest. The head continues to pivot at the painted collar. Local neck rotation remains bounded to 0.10 radians, and torso rotation to 0.13 radians.

**Jaw:** the same static smile lacked a local performance response. The existing painted jaw/lower lip now deform locally from a damped, bounded track. Strokes, greetings, celebration, impact and recovery have different amplitudes; boosted swimming keeps a quiet, compact mouth. This preserves artwork and is not speech lip-sync or a newly drawn open mouth.

**Timing:** review exposed a 30-versus-120 FPS difference in shoulder glide. Cadence is now integrated through its easing interval, and shoulder filters integrate a linearly changing target rather than sampling only the frame endpoint. Focused checks compare shoulder/head/jaw endpoints at 30/60/120 Hz.

**Whole performance:** 12 stroke profiles, six aerial variants, five gestures, jump ascent/airborne/landing, turns and recovery use the shared phase and blended state. Collar and hip bands stay pinned; only the shoulder band is allowed to glide. Gentle Motion and Economy remove new detail targets. Restart clears springs, socket offsets and deformation. Collision/movement/combat rules and original binary artwork are retained.

## Verification

- All 29 regression suites pass; complete results: `validation-v0294.json`. Tests include full adventure, controls, collisions, jumps, scene flow, original painted overlap, face, spine, stroke and movement checks.
- Expanded Definitive Review suite: 81,750 checks, zero failures. Covers every dense body control point, all 22 new performance profiles, loop seams, 30/60/120 Hz transitions, all 12 styles, five gestures, six actual jump-style indices, socket/head/jaw bounds, shader signals, UV registration, settings and restart.
- Ultimate Sarah checks all 432 arm samples per style: 19,173 checks, zero failures. Existing Definitive Sarah: 11,347 checks, zero failures. Updated spine: 194,009 checks, zero failures; shoulder band movement is intentional while collar and hip stay pinned.
- Native Godot 4.4.1 Compatibility rendering: 60-second, 30 FPS movie across 27 contexts, with full-body and tracking shoulder/head/jaw close-ups. Separate real-level waterfall climb, dive and boost captures were reviewed. No shader/runtime errors in final captures.
- Release-package validation checks ZIP CRC, Godot ZIPReader extraction with every byte verified, fresh asset import/startup and fresh-copy Definitive Review, Definitive Sarah, spine, face, Ultimate Sarah and full-adventure suites.

Historical validation documents describe their original releases. Artistic quality is best judged from the supplied in-engine preview. Windows Intel Arc 140V Compatibility rendering was checked; mobile hardware and other backends were not physically tested.
