# v0.21.0 — Little Moments of Magic

Built from the complete v0.20.0 Sarah Definitive 2.1 project. This update concentrates on the family tutorial, Highland before the waterfall, and their existing optional caverns. All Whimsy 4.0 characters, dialogue, paintings, fifteen cavern loops, progression and saves are retained. All 129 art/audio/font files from v0.20 are byte-identical; twelve new transparent paintings are recorded separately.

## Four small stories

Each setpiece has one home, rather than being stamped into both maps.

| Location | Moment | Interaction |
|---|---|---|
| Tutorial, near x540 / y635 | Shy fish friendship | Settle nearby. Boost startles the fish briefly; patient swimming brings it toward Sarah’s hand and eventually introduces a differently shaped moonfish friend. |
| Tutorial, Pearl Nursery | Dozy’s lantern welcome | A sleepy cuttlefish greets Sarah. He rises courteously to leave her room, and his lights warm as she rests nearby. |
| Highland, near Nori x1740 | The escaped letter | Follow the floating letter, approach it to catch it automatically in a protective bubble, then return toward Nori. The story waits for important HUD messages to finish. |
| Highland, Nori’s Root Garden | The little music pavilion | Visit the bell, harp and chime positions. Their three notes make a small song; there is no failure deadline or required order. |

Each completed moment owns one 40-point Secrets award through the existing ledger and checkpoint path. They are optional, require no new controls, and do not launch combat projectiles. The ledger prevents repeated awards and preserves completed moments through saves and retries. Unfinished transient performances reset safely on retry. Casting, boosts, jumps, impacts and existing discovery reactions keep priority over decorative gestures. Ambient speech yields to tutorial conversations, pause, charging and important messages; moving away silences distant chatter.

## Full tutorial overview

The audit rendered the opening, all eleven lesson states, Daddy’s arrival, optional replies, the trial, companion choice, farewell and several aspect ratios. The conversation audit exercises all 33 reply buttons through their actual callbacks and captures their responses at phone size. It also covers 640×360, 844×390, 1024×768 and desktop layouts.

The clearest defects and resulting changes:

- **Oversized empty lesson panel.** Wrapped labels could settle to a smaller minimum while their container retained its earlier large height. The cue now shrinks to its content after layout, and lesson changes request a fresh layout.
- **Daddy entering through the interface.** He now approaches from clear water beside Sarah on a short eased path, fades in gently, greets, then settles before the automatic introduction opens. Help remains immediately accessible. If Sarah explores a cavern first, the surface arrival waits until she returns. Gentle Motion uses the resting position.
- **Guide overlap.** Daddy keeps clear of Sarah’s face during teaching and after the trial, and the gift scene separates the parents. The trial retains its original attacks, vulnerability windows and three-hit requirement.
- **Speech ownership.** Opening a conversation immediately hides ambient speech. New story captions also suppress competing world captions, and the old postal vignette no longer announces another lost letter. The new captions measure their text, use the story font with distance-field rendering, scale for phones, move above Sarah when their first placement would cover her, and respect the actual scaled tutorial cue height on narrow phones.
- **Placeholder speaker icons.** Sarah and Avina now use their character paintings in the dialogue portrait area.
- **Repeated scenery.** The tutorial floor uses seven spaced original garden compositions instead of the earlier repeating line. Peekaboo has a new connected garden with three distinct hiding places. Repeated large entrance planting clusters are removed from the focused caverns; their rims and lights are quieter. Rock skins retain their painted alpha and use cached individual deformation rather than bare rectangular stone blocks.
- **Sarah’s missing lower silhouette in caverns.** Opaque cavern water could cover her low-z tail while higher face and arm layers remained visible. The whole rig now clears that layer. Her v0.20 artwork, geometry and articulation remain intact.
- **Poor cavern composition.** In these opening rooms, the horizontal camera frames the room and its inhabitants instead of displaying a large wall beside them. Movement and collision geometry are unchanged.
- **Floating new props.** The glass nursery sits beyond the shaft on solid ground, and the music pavilion meets the cavern floor.

The existing rings, optional relics, Boost, jump and chained-jump lessons, royal gifts, three volunteers, Daddy’s trial, three peekaboo rounds, bubble practice, all 33 reply branches and both companion choices remain. No lesson is replaced by the new stories.

## Visual craft and assets

The six Highland beds are separate paintings: a spiral fern in a boot, teapot daisies, a lace sea-fan, orchid bough, glass nursery and crescent succulents. Each is placed once in the opening reach. The other new paintings are the conch post office, gold-and-indigo fish, moonfish, Dozy, music pavilion and peekaboo garden. All originals remain full-resolution RGBA PNGs in `godot/assets/little-moments/`; their 512-pixel runtime import limits are included in the source package. `generation.json` contains exact production prompts, hashes and built-in ImageGen provenance.

This is a focused removal of repeated foreground set dressing, not a complete repaint of the existing world. Collectible icons, navigation symbols, rock source materials and motifs inside the preserved background paintings remain shared. Absolute uniqueness of every visible motif and an absence of every possible artifact are not claimed.

## Performance and validation

Paintings load when the scene is built. Character nodes are reused, arm and tail topology remain fixed, and the letter bubble and caption measurements use reusable data. Distant sprites are culled. Removing repeated garden stamps reduces visible submissions. Economy retains the interactions; Gentle Motion freezes decorative clocks, swaying and extra bobbing while allowing the essential interactions.

`verification/little-moments/` contains raw desktop performance JSON, preservation results, comparisons and release checks. The benchmark runs the same three views against v0.20 and v0.21 at 1400×960 with Mesa llvmpipe, two render workers, 180 manual tick samples and 30 rendered frame samples. It measures software-rendered desktop behaviour, not Android GPU performance. Static memory is Godot’s tracked allocation rather than total RSS. The retained v0.20 report is historical and is not a measurement of this update.

| View | Draw calls, before → after | Texture memory, before → after | Manual tick mean, before → after |
|---|---:|---:|---:|
| Tutorial | 550 → 392 | 283.21 → 288.87 MiB | 3.28 → 4.79 ms |
| Nori’s opening reach | 436 → 305 | 282.81 → 294.40 MiB | 6.31 → 5.13 ms |
| Root Garden cavern | 444 → 315 | 282.81 → 294.40 MiB | 3.57 → 4.38 ms |

The sampled software frame median/p95 was 155.51/212.80 → 145.94/223.43 ms in the tutorial, 180.22/291.92 → 237.85/461.73 ms near Nori, and 170.83/223.26 → 192.60/266.00 ms in the cavern. Shared-host timing varies substantially, the final desktop run overlapped packaging work, and some frame and tick costs increased. These samples support neither a phone FPS guarantee nor a claim that every scene became faster. The stable draw-call reduction is roughly 29–31% in these views; the extra texture allocation is about 5.65–11.59 MiB.

Native release validation covers 31 suites, including the new story, ownership, compact-cue and layering checks, the 5,688 Sarah 2.1 checks, full original controls and journeys, saved rewards, dialogue and Whimsy 4.0. Final clean-package and APK verification results accompany the source. Physical Android frame time, thermal behaviour and touch/playback testing remain outstanding.

The Android application ID, original Godot save-directory name and release signing identity remain unchanged; this release uses version name 0.21.0 and code 2100. Private signing material is excluded from the source archive. The supplied videos are silent, fixed-timestep desktop previews at 24 fps, with cuts between the story locations.
