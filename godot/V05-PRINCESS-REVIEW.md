# v0.5 - Princess Polish Sarah

Sarah's existing painted identity and the v0.4 visual cleanup remain. This release concentrates on coordinated movement, finer articulation, a distinct boost silhouette and swimming depth effects. Input, movement speed, collision shapes, boost duration and chapter progression are unchanged.

## Measured expansion from v0.4

| Movement surface or track | v0.4 | v0.5 |
| --- | ---: | ---: |
| Samples per body/fluke loop | 432 | 1,296 |
| Total samples across 36 body/fluke loops | 15,552 | 46,656 |
| Samples per shoulder/elbow/wrist stroke track | 432 | 1,296 |
| Samples per coordinated shoulder/head/jaw/chest track | 432 | 1,296 |
| Breaststroke interpolation keys | 24 | 72 |
| Painted points per back-hair strip | 255 | 765 |
| Connected face/forehead-hair points | 9,555 | 28,665 |
| Connected torso points | 325 | 975 |
| Painted points per arm | 297 | 891 |
| Connected tail/fluke points | 2,535 | 7,605 |
| Aerial performances | 6 | 18 |
| Launch/landing timeline keys | 13 | 39 |
| Greeting/cast/celebration/impact/reward timeline keys | 51 | 153 |

Three continuously blended interpretations add reach, flow and release to the existing stroke families. They are coordinated variations of the established movements, not 108 unrelated animation files. Delayed secondary harmonics travel from the shoulders through the ribs and waist into the fluke, hair and forehead locks. Shoulder, elbow, wrist, head, jaw and chest channels retain their response filters and anchored paint coordinates. The extra detail adds subtle follow-through rather than tripling motion amplitude or swim speed.

The six aerial families each receive three different timing envelopes, giving 18 reachable performances. Their entry/exit rotation envelopes stay closed, and the visual clearance calculation uses the same roll timing. Launch, landing and gesture keyframes are resampled from the authored curves while retaining original timings and durations.

## Torpedo boost and depth

Boost smoothly gathers the hands, aligns the shoulders, nearly straightens the elbows and quietens wrist motion. The upper body stays compact while the hips and fluke carry a controlled dolphin propulsion wave. Directional and waterfall strokes still blend through the shared phase; a dash does not consume the normal breaststroke cadence.

A world-space swimming wake adds shaded droplets, small highlights and projected vortex ellipses. Emitted water stays behind Sarah when she changes position or facing. Front/rear tint differences, projected curves and the existing directional volume lighting give a 3D appearance in the existing 2D compatibility renderer. This is not a replacement 3D character or physics system.

Shared tail, hair and arm calculations are cached by painted column. Equivalence checks against the uncached implementation found maximum point differences below 0.000016 local pixels. The complete authored face grid remains available, while normal gameplay draws fewer subpixel triangles; close-ups restore full face detail, with hysteresis to avoid flickering between levels. A native comparison on this Intel Arc 140V Windows compatibility renderer measured approximately 44 ms per rendered frame for v0.4 and 53 ms for optimized v0.5 in the inspected scene. The increased detail still has a rendering cost; these figures are not a universal frame-rate promise. Economy remains available.

The wake is capped at 72 particles, stops emitting at rest, expires promptly, clears on restart and is suppressed while leaping, in Gentle Motion and in Economy graphics. It adds no collision shapes, gameplay force or rig nodes during swimming. Intended portrait safety and pause behavior remain.

## Validation and delivery

Native production-rig renders cover breaststroke, crawl, torpedo boost, waterfall climb and waterfall boost. The accompanying preview uses those rendered frames. The geometry review checks anchored sleeves, body/tail joins, facial clearance, UV stability, joint ranges and moving-triangle integrity in both directions, across strokes, gestures and all 18 aerial variations. Static face topology is checked once; its finer feature deformation is rendered by the shader.

All 16 regression suites pass; results are recorded in `validation-v05.json`. Eleven fresh-extraction suites also check byte integrity, root `project.godot`, asset import, startup, controls, chapter progression, family layouts, interface, scene transitions, the princess rig, breaststroke and jump animation. These are Windows compatibility-renderer checks, not physical phone performance measurements.

The playable ZIP excludes tests, captures, caches and historical review files. Original artwork and audio remain intact, and the old MermaidADVENTURE repository is untouched.
