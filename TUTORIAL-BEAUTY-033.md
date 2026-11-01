# Mermaid Adventure v0.33 — The Handcrafted Tutorial

This is the complete Godot 4.4.1 project with a tutorial-only visual overhaul. The chapter sequence, movement balance, collision geometry, treasure rewards, save location and save schema are retained. Other chapters keep their existing art treatment. Start at `project.godot`, or run `godot/training_lagoon.tscn` directly.

## Design review and implemented changes

| Area | Review finding | Result |
| --- | --- | --- |
| Visual repetition | Frequent copies of the same garden and stone reduced the sense of a made-by-hand place. | Eight different garden paintings each have one authored location. Eleven principal surface barriers use different limestone, fossil and coral silhouettes. Small supporting ledges can still share the formation family. |
| Obstacle shape | Generic stretched formations gave the route a construction-kit appearance. | Twelve formation paintings provide distinct low shelves, ledges, pillar and pendant shapes. Floor formations maintain their painted proportions and settle into the seabed. Existing hit geometry stays unchanged. |
| Gardens and grounding | Dense decoration competed with Sarah and collectible signals. | The legacy repeated garden layer is removed from the tutorial. New rooted gardens have individual spacing; only their upper fronds sway. Tiny existing playful critters remain. |
| Treasure presentation | Two recurring bases made the five chests look stamped into the scene. | Five different painted low supports fit the original chest positions. Chest artwork, hinged opening, rewards and saved collection states are retained. |
| Readable pickups | Large decorative clam shapes looked as important as real interactive objects. | Real pearls now read as small pearls. Fake pickup-like dressing and recurring ornamental lanterns are removed. Genuine collectibles and teaching cues retain priority. |
| Swim rings | Procedural arcs looked detached from the painted world. | Three different open coral, seagrass and fossil wreaths retain clear swim-through centres. Completed rings become quieter. |
| Practice target | A wireframe-like switch and floating label looked like editor graphics. | A small pearl target sits on a painted reef altar. The existing lesson instructions and response remain. |
| Grotto entrances | Abrupt shaft bands and hard rectangular edges exposed the scenery construction. | Four new descent paintings blend into the existing nursery and bellflower scenes. Adjacent passage art overlaps with varying UVs; rock edges feather into matching world stone. Openings and collision boundaries stay in their existing places. |
| Cavern walls | A dark repeating wall tile framed the paintings too harshly. | World-space multi-scale stone sampling softens repetition and matches the water palette. The exact room outline still comes from the authored free regions. |
| Resident presentation | Repeated perch dressing and overly tall speech panels crowded the residents. | Different natural perches, calmer dressing and compact measured captions leave more room around Sarah. Long-to-short messages now resize correctly. |
| Interface | Short messages could retain a previous large caption height. | Tutorial caption dimensions use the actual wrapped text. Placement accounts for Sarah's full silhouette and UI scale. Help keeps a larger touch target. Existing family conversations and pause/resume remain. |
| Royal family | Bright lighting made the supplied Meshy models feel cut out. | Softer ambient, key and fill light better match the lagoon. The models, dimensions and original paintings are preserved. |
| Motion and settings | Scenery should add life without constantly distracting from swimming. | Cached small garden meshes sway at the tips. Gentle Motion stops that sway; Economy retains the paintings with the existing quieter effects. Hidden gardens are culled. |

## Verification and preservation

Native Godot stills cover all eleven lesson views, both grottoes, the descent passages, two lower treasure pockets, both nursery residents and Sarah's replies, family conversation, 1920 × 1080 framing and an 844 × 390 touch layout. The portable HTML review includes matching before-and-after views and the full current gallery. Stills use staged inspection positions, not a claim of continuous keyboard playthrough.

The short animation preview captures real Godot character, garden and chest animation with Sarah held in place. It includes a real chest collection/opening, a resident greeting and the swim-ring view. It is a silent ambient inspection clip, not a gameplay walkthrough or frame-rate benchmark.

Source suites pass 1,490 counted checks, plus the device-layout and title-flow suites. This includes all 33 family reply branches and 11 complete cavern loops over 9,308 simulated swim ticks. The new caption regression covers long-to-short messages, Sarah clearance, phone wrapping and touch help. The Windows EXE's embedded pack passes another 26 resource and startup checks, for 1,516 counted checks overall. Export validation is recorded in `verification/tutorial33/export-smoke.log`.

`verification/tutorial33/preservation33.json` checks 229 inherited art, audio, font, data and scene files against the complete v0.32 source. Every checked file is byte-identical; none are missing. Original Whimsy paintings, Sarah, chest art and both original and optimized Meshy GLBs remain in the complete source. New art is additive. Shared renderer changes branch on the tutorial; default rendering for other chapters is retained.

## Measured rendering cost

Matched 1400 × 960 views in Godot 4.4.1, Compatibility renderer, Linux Mesa llvmpipe. Eight-frame means after warmup, with matched camera/player poses and held clocks:

| View | Draw calls before → after | Primitives before → after |
| --- | ---: | ---: |
| Welcome | 186 → 141 | 37,774 → 34,299 |
| Pearl Nursery | 336 → 170 | 54,907 → 38,268 |
| Bellflower Hollow | 240 → 194 | 44,818 → 38,518 |
| Royal gifts | 115 → 105 | 332,113 → 331,615 |

Reported texture memory rises from approximately 503.2 MiB to 528.6 MiB in the welcome view: +25.4 MiB, about 5.1%, for the new paintings. This is the renderer's texture-memory counter, not total process RAM. The new garden layer caches eight 63-vertex meshes; texture resources and atlas regions are reused. There is no per-frame geometry rebuilding or texture loading in this layer.

These measurements describe render workload and texture use on a software renderer. They do not establish a Windows or Android FPS improvement. Physical Windows execution, device frame times and device memory still need testing. The Windows EXE's embedded resources are loaded and checked with the matching Linux Godot runtime; that is distinct from launching the executable on Windows.

## Remaining limitations

The supplied royal Meshy models have no skeleton, skins or animation clips. Their existing breathing, attention and turns move the complete models; independent fingers, elbows and facial acting need rigged assets. Existing background paintings contain their original recurring motifs. Small support ledges share the new formation family. This release removes prominent stamped foreground dressing; it does not claim that every pixel or motif in the world is unique.

New production paintings were created with the built-in image generator. Original output pixels are included unchanged in `godot/assets/tutorial-v033`. See `generation.json` for hashes and prompt records, and `regions.json` for atlas crops.

## Windows and source packages

Extract the Windows ZIP to a new folder and run `Mermaid Adventure.exe`. All runtime resources are embedded. No Godot editor is needed to play. The complete source includes original artwork, native tests and review evidence. To export it yourself, install Godot 4.4.1 and the matching Windows export templates; the source preset has machine-specific template paths cleared.
