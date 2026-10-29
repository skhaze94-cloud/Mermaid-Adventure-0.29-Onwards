# v0.6.1 Adventure Polish

29 October 2026. Review follow-up to Opal Current commit `e580ffa3304ba8ede2ac1499c7f7dfb41b34e065`.

## Player-facing fixes

| Review finding | Implemented behaviour |
| --- | --- |
| Progress existed only in memory | Continue restores checkpoint score/award ownership, enemies, treasure, unlocks, Avina choice, shell switches and independent duo health. Tutorial lessons, gifts and peekaboo also resume. New adventures ask before replacing a checkpoint; chapter stars/bests remain. |
| Duplicate old projectile drawings | Basic chapters now use the shared Opal renderer exclusively for projectiles. |
| Charged cooldown ring used 0.20 seconds for every tier | Each bubble retains its actual recovery duration. Touch shows cooling and charge progress; keyboard/controller players get a discreet tier/progress card and a brief ready cue. |
| Boss fights hid important messages | Priority guard, damage, capacity and save feedback remains visible above the boss panel. Ordinary travel hints stay quiet during combat. |
| Help contradicted unlock/attack rules | Help explains both unlock paths and all charge thresholds. Boss introductions describe Bubble or Boost where both work. The family tutorial offers an optional Royal Aurora target with one reward and no exit gate. |
| Route progress used raw world coordinates | Each chapter measures its playable entry to its actual portal, including Nessie starting at zero and completing at 100%. |
| Finale showed only Nessie’s points | A crown-return results card presents the whole adventure total and chapter breakdown. Chapter personal bests/stars and a completed-journey record are distinct. |
| Emphasis followed enemy-array order | Four ordinary shells receive emphasis by attack/windup state and distance. Cooling enemies yield to immediate threats; the visual caps remain unchanged. |
| Settled HUD kept rebuilding | Finished score counting, result rows and modal layout stop updating; inactive floating feedback is skipped. |
| Later boss volleys repeated one pattern | Queen Antonella’s Crown Waltz, Rana’s Rainbow Ladder, Nessie’s Cresting Wake and Baron Bite’s Pincer Pearls have distinct geometry. Each has a 0.28-second locked-direction warning and at most three shots per existing volley. Speeds, health, recovery gates and projectile pools remain. |

## Saving and compatibility

Preferences keep their existing application identity and file. A separate versioned adventure file lives in Godot’s `user://` directory. Save writes use a verified temporary file, content checksum, atomic replacement and a last-good backup. Recovery never replaces a good backup with an incompatible primary. Object decoding is disabled. A strict floating-point comparison tolerance handles sub-pixel Godot JSON parser differences; the serialized file checksum remains exact.

Autosaves happen at checkpoints/lesson transitions, chapter clears and safe exits/focus loss, with unchanged states skipped. Serialization, verification, backup and file replacement run on a worker using an owned snapshot, without touching live scene data. There is at most one active write plus one coalesced newest request. Every task is joined, and explicit exits flush pending writes. Continue clears held input and transient attacks and supplies arrival protection. Chapter clears save the next chapter; completing Nessie retains records without offering a cleared campaign as Continue. Existing v0.6 preferences and best-score data are preserved. The project declares Godot 4.4 because native JSON conversion is used; verification uses Godot 4.4.1.

## Verification

The new `adventure_polish_test.gd` exercises real title Continue, checkpoint/duo/tutorial restoration, interrupted-file recovery, native value types, per-tier cooldowns, desktop/touch feedback, priority messages, route endpoints, final totals, settled HUD work and bounded/locked boss patterns. Existing native suites and fresh-package validation are rerun. Developer checks are excluded from the playable archive.

Final counts, native captures and matched full-quality performance measurements will be recorded after validation. Physical Windows/Android/iOS hardware FPS and human boss-balance playtesting remain outside this software-renderer environment.
