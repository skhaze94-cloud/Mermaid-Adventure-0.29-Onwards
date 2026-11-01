# Mermaid Adventure v0.34 — Friends Cavern

A complete Godot 4.4.1 project with a cavern update across all eight chapters. All 15 cavern rooms now contain named friends. Six new residents join the existing sixteen Whimsy neighbours and Dozy.

## Exploring and meeting friends

Swim beside a friend and pause gently for about 1.5 seconds. A short local greeting appears; Sarah has a little reply. Each named friend gives **50 points once in a saved chapter run**. A return visit, retry or Continue preserves ownership and cannot award those hello points again. A fresh chapter run can earn them again.

The original 120-point reward for meeting both members of a chapter's neighbourhood remains. Dozy's existing 40-point lantern activity also remains, separately from the new 50-point hello. Cavern chests still give their original 100 points. Friendly conversations are optional and do not pause swimming, capture controls or open progression gates. Combat and important gameplay messages take priority. The Sea-Star neighbours retain their original after-boss availability.

The HUD calls these areas **Friends Cavern**. Individual room names remain in the data and tutorial guidance.

| Chapter | Cavern | Friends |
| --- | --- | --- |
| Tutorial | Pearl Nursery | Mallow and Tilly |
| Tutorial | Bellflower Hollow | Dozy |
| Highland Gold | Nori's Root Garden | Posy and Purl |
| Highland Gold | Sunken Bell Cathedral | Coda, the bell polisher |
| Highland Gold | Ribbonlight Archive | Folio, the nautilus librarian |
| Shadow Crab Kingdom | Lantern-Well Caverns | Ludo and Vesper |
| Shadow Crab Kingdom | Upside-Down Moonpool | Luma, the moonjelly |
| Shadow Crab Kingdom | Lost Postbox Grotto | Pipette, the post carrier |
| Miguel's Lagoon | Orchid Rootways | Peep and Saffron |
| Miguel's Lagoon | Coral Amphitheatre | Tango, the little usher |
| Miguel's Lagoon | Silverstream Hollow | Rill, the stream guide |
| Blackwater Tunnel | Pocket-Rain Tailor Tunnel | Button and Hush |
| Pearl Palace | Very Polite Tea Tunnel | Crumb and Dot |
| Rana's Ruin | Sleepy Shell Tunnel | Miri and Oona |
| Nessie's finale | Little Sea-Star Tunnel | Bibi and Thimble, after the trial |

## Cavern visual review and changes

The abrupt appearance had two separate causes: shaft artwork blended into a differently mapped room painting, and a recognisable repeating block-stone texture framed the room. Each cavern now samples one continuous painting from its descent through its chamber to its lower pocket. A softer arrival blend becomes opaque just above the old seabed, covering the previous hard material line.

Five new underwater paintings give the later caverns root gardens, fossil bells, ribbon archives, moon-blue mineral formations and coral terraces. The Pearl Nursery and Bellflower paintings remain in use. Some themes share paintings across distant chapters with restrained palette differences. The new continuous limestone material replaces the block-like cavern wall texture; two world-space sampling scales soften repetition. Feathered, irregular room edges use the same wall coordinates on both sides of the join.

Side perches in the later chapters have been spaced toward the edges, with new perches for the six additional residents. Their positions clear both return streams. The tutorial's existing perch collision positions are retained. The body, shafts, upper galleries, lower pockets and central reef routes retain their authored layout; movement controls, boss requirements and portal positions are preserved.

The six new friends use the original transparent atlas pixels, cached meshes and their own fin, shell, gill and face regions. The existing resident performance system supplies attention, small greetings, soft motion and settling. Nearby residents stop wandering while Sarah speaks with them. Hidden residents skip mesh and expression updates. Gentle Motion keeps the company with quiet poses.

Resident captions now use measured text height and Sarah's full silhouette in every chapter. Dozy's older story caption also has explicit text dimensions and horizontal avoidance so a fresh greeting cannot remain hidden behind an oversized panel. The older tutorial-only caption fix therefore also applies to the new friends. Large decorative garlands, repeated cottage staging and simple procedural habitat props were removed from the cavern presentation; character paintings carry their individual personality. Cavern pearl trails use smaller pearl artwork, and the existing non-tutorial chest painting is larger and easier to spot.

Each outline is checked before its mesh is built. A decorative perturbation that folds falls back to the rounded contour. Triangulated cavern geometry is cached at scene creation rather than rebuilt for every draw.

## Verification

The source passes **1,916 counted checks**, plus device-layout and title-flow suites. This includes the new 402-check Friends Cavern suite covering all 15 rooms, all 23 friends, exact point amounts, reward ownership, retries, pause, Gentle Motion, valid greeting positions and v0.33 neighbourhood-save compatibility. Existing route suites exercise all 15 distinct cavern loops using simulated controller input: eleven early/tutorial loops and four later loops. Family conversations still pass all 33 reply branches.

The Windows EXE's embedded pack passes another **76 checks**, including all eight chapter scenes, the new paintings, every cavern outline, all 22 neighbourhood actors, original Dozy resources, both royal models, dialogue and saved hello rewards. Total counted checks: **1,992**. The pack is exercised with the matching Linux Godot runtime; this is not a physical Windows launch.

The native visual review contains 87 current views: every cavern interior, both entrances and the lower treasure pocket, all 23 named friends, and touch/Gentle Motion/Economy layouts. There are 45 matched v0.33 comparison views. Stills use staged inspection positions and held clocks. The separate 16-second preview uses fixed-step simulated swimming through the tutorial descent to Mallow and through the cathedral descent to Coda; both actual greetings and friend rewards trigger. It is a silent 12-fps capture, not a device frame-rate measurement or a complete manual playthrough.

## Measured render workload

Godot 4.4.1, Compatibility renderer, Linux Mesa llvmpipe software OpenGL, matched 1400 x 960 poses. Counters are warmed samples per view, not hardware frame-time benchmarks.

| View | Draw calls before to after | Texture memory before to after |
| --- | --- | --- |
| Pearl Nursery interior | 170 to 178 | 528.6 to 528.6 MiB |
| Bellflower interior | 196 to 204 | 528.2 to 528.2 MiB |
| Bell Cathedral interior | 275 to 101 | 507.9 to 533.2 MiB |
| Moonpool interior | 317 to 142 | 567.4 to 588.7 MiB |

Median draw calls across all 45 matched views decrease from 352 to 170. The tutorial views add a few draws; the later caves lose much of their old repeated decoration. New paintings increase texture memory in several later views. The reported memory is the renderer's texture counter, not total process RAM. Frame time, Windows hardware FPS and Android-device memory/performance still require device testing. No FPS gain is inferred from these counters.

## Preservation, art and limitations

The preservation record checks **237 inherited artwork, audio, font, scene and core-data files** against v0.33. They are all byte-identical. This includes the original and optimized royal GLBs, Sarah's paintings, the Whimsy cast JSON, source level data, movement controller, save store, adventure session and family dialogue. An incomplete copy of Antonella's original authoring GLB was caught and restored from the verified v0.33 source archive before packaging.

The application name, save location and checkpoint schema remain stable. New friend reward keys use the existing score ledger; the original two-neighbour saved-state format stays at version 1 and accepts previous saves.

Seven production PNGs were created using the built-in image generator and copied unchanged into `godot/assets/cavern-v034`. `generation.json` records exact prompts, original output names and hashes; `prompts.json` contains the full prompt set. The new cast uses painted 2.5D meshes. The supplied royal Meshy models remain without a skeleton or individual limb/facial clips; their inherited whole-model performance remains.

## Packages

For Windows, extract the ZIP to a new folder and run `Mermaid Adventure.exe`. All runtime resources are embedded; no editor is required. Physical Windows execution remains untested here.

For source, open `project.godot` in Godot 4.4.1, allow imports to finish, and run. The complete source includes the original paintings and authoring models, new artwork, tests and verification records. The visual HTML review and MP4 are provided separately. A matching Windows export template is needed to export again; machine-specific template paths are cleared in the source ZIP.
