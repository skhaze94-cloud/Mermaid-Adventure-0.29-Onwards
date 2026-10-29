# v0.5.1 full-quality performance review

29 October 2026. Compared with v0.5 commit `1fddff15c88c5d14134cbb3ccbefbd8e4becbb92`.

The pass reduces repeated animation, rendering submission, HUD and hidden-scene work while preserving the painted presentation. Median script/physics update time fell in all eleven controlled cases, by **10.8–31.6%**; the aggregate of those medians fell **23.3%**. Reported texture memory fell **17.1–31.7%** during the same ordered scene tour. These are CPU-update and texture-residency measurements, not promised device frame rates.

## Changes

- Sarah's exact authored triangle grids now use persistent indexed ArrayMesh surfaces. Each animation frame uploads positions; it no longer rebuilds topology, normalized UVs, white colours and the entire surface through Polygon2D. Dynamic bounds include the articulation envelope to prevent edge clipping.
- Cached torso, shoulder and waist weights replace repeated smoothstep/exponential calculations. Tail-column rotations and wave inputs are reused across all thirteen rows. All sampling rates, points, curves, joins and 18 aerial performances remain.
- Two full-precision custom vertex attributes cache static facial feature masks. Live face/hair deformation, expression blending and lighting use the same painting and response equations.
- Chapter paintings and boss art are explicit resources of their own PackedScene, so threaded loading brings in the selected artwork rather than every chapter's preload set. Unused legacy preloads are removed and original fallback paintings load only if needed.
- Chapters that draw their own scenery skip synchronization and processing of hidden Highland components. Active enemy logic, collision, progression, water effects and audio remain intact.
- HUD state is copied to protect invalidation when callers reuse dictionaries. Unchanged snapshots, unchanged touch geometry and repeated font-size overrides do not trigger redundant work. Joystick positions, cooldowns, low-energy cues, pause and results still invalidate immediately.
- Inactive ripple/wake redraws and stationary reef redraws are skipped; the same full-quality effects, particle budgets, textures and lighting remain enabled. The generated soft-light texture is shared between scene instances.

## Measurements

Godot 4.4.1, Compatibility/OpenGL, Linux X11, Mesa llvmpipe software rendering with two worker threads, 1400 × 960. Each case uses 30 warm-up frames and 60 measured frames at a fixed manually advanced 1/60-second simulation step. Economy and Gentle Motion are off. The same audit script runs against a separate baseline checkout. The title case covers its artwork during the frozen menu reveal; transition tweens and native particles are frozen to keep comparisons deterministic.

| Scene | CPU update median, ms | Reduction | Texture memory, MiB |
| --- | ---: | ---: | ---: |
| Highland entry | 7.443 → 5.606 | 24.7% | 211.2 → 173.2 |
| Highland boss | 6.967 → 5.275 | 24.3% | 211.2 → 173.2 |
| Waterfall | 7.165 → 5.216 | 27.2% | 211.2 → 173.2 |
| Shadow Crab Kingdom | 7.264 → 5.366 | 26.1% | 303.2 → 251.2 |
| Miguel’s Lagoon | 7.493 → 5.125 | 31.6% | 303.2 → 251.2 |
| Blackwater Tunnel | 6.696 → 5.462 | 18.4% | 347.2 → 237.2 |
| Pearl Palace | 7.048 → 5.959 | 15.5% | 347.2 → 251.2 |
| Rana Rex | 7.459 → 6.655 | 10.8% | 347.2 → 251.2 |
| Nessie finale | 7.190 → 5.401 | 24.9% | 347.2 → 251.2 |
| Family lagoon | 7.436 → 5.719 | 23.1% | 364.5 → 276.5 |
| Title artwork | 6.210 → 4.325 | 30.4% | 372.1 → 284.2 |

The native dynamic-surface integrity check verifies that animation retains its surface identity, UVs and triangle topology on every update. Rendered primitive/object counts match the baseline in every captured case.

Software-rendered wall times include canvas submission, rasterization and scheduling, and are much slower and noisier than a hardware GPU. They are retained here to avoid presenting CPU update savings as total frame-rate gains:

| Scene | Baseline frame median, ms | v0.5.1 frame median, ms |
| --- | ---: | ---: |
| Highland entry | 141.751 | 130.776 |
| Highland boss | 126.414 | 110.249 |
| Waterfall | 103.613 | 86.143 |
| Shadow Crab Kingdom | 155.984 | 135.905 |
| Miguel’s Lagoon | 151.357 | 124.667 |
| Blackwater Tunnel | 121.282 | 138.241 |
| Pearl Palace | 132.038 | 140.785 |
| Rana Rex | 139.126 | 150.101 |
| Nessie finale | 131.820 | 134.442 |
| Family lagoon | 138.542 | 137.258 |
| Title artwork | 165.583 | 148.499 |

Blackwater's slower tour sample was repeated in isolation: script median **7.123 → 5.239 ms**, rendered mean **124.894 → 122.231 ms**, rendered median **118.039 → 121.096 ms**, and rendered p95 **150.268 → 146.484 ms**. The repeat does not reproduce the large tour slowdown; it also does not establish a reliable hardware-GPU FPS gain. Physical Windows/Android/iOS performance remains unmeasured in this environment.

## Quality verification

- The artwork, audio and authored animation resource files under `dist/`, `godot/assets/` and `godot/animations/` are unchanged.
- **146 states / 5,921,322 point comparisons** cover twelve strokes, both directions, eighteen aerial variations at three points in flight, gestures, Gentle Motion and Economy. UV/topology hashes and attachment transforms match. Maximum local point drift is **0.0000038147 pixels**, below the 0.0001-pixel tolerance.
- Eleven native before/after captures cover all eight chapters, Highland entry/boss, waterfall and title artwork. Mean channel difference is below 0.0001 on a 0–255 scale in every image. Gameplay captures differ by at most two channel levels; the enlarged title has one edge pixel above three levels (maximum fifteen). Inspection retained the same painted detail, colour, lighting and effects.
- **36/36 native regression suites passed.** Coverage includes controls, collision/recovery, chapter progression, family tutorial/layouts, enemies/bosses, scoring, touch/device layout, pause, menu/scene transitions and detailed character geometry. The arm review alone performs 21,764,488 checks. The old harmony assertion expected 297 arm points even in the unmodified v0.5 baseline; it now correctly requires the existing 891-point detail.
- A newly generated playable ZIP passed CRC, Godot Project Manager-style directory extraction, SHA256 byte comparison, fresh editor import, title startup and **11 fresh-extraction suites**. Developer tools, tests and historical reports remain outside that playable package.

Raw results: [validation-performance.json](validation-performance.json). Reusable tools: `tools/performance_audit.gd`, `tools/geometry_equivalence.gd` and `tools/run_regressions.py`. The audits accept output locations through environment variables; `run_regressions.py --godot <path> --output <directory>` runs the native suite. `package_validation.py --godot <path>` performs the standalone package/import checks.
