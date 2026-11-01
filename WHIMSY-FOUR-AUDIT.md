# Whimsy 4.0 — audit and field guide

## What the audit found

The strongest existing details are the expressive paintings, Nori’s postal routine, the sea-slug’s small local remarks, Pip’s journeys and the unhurried tea parties. Their warmth comes from a clear silhouette, a small task and a little response to Sarah. The additions follow that pattern.

The biggest gap was spatial: the eleven caverns were useful routes with attractive scenery, but very few residents. The four later chapters also lacked optional underground loops. Adding more surface captions would have made the interface busier without giving the ocean more life.

| Area reviewed | Finding | v0.16 action |
|---|---|---|
| Paintings and identity | The existing cast has a coherent pearlescent storybook style worth preserving. | All 105 baseline art/audio hashes remain unchanged. Sixteen new transparent character paintings use soft faces, tactile props and distinct silhouettes. |
| Places to linger | Most social discoveries lived on the surface route. Caverns were comparatively quiet. | Eight paired neighbourhoods occupy real reef perches, one per chapter. Each includes a little shell home, hanging lights and a scene-specific prop performance. |
| Branching exploration | The original eleven loops were limited to the tutorial and opening chapters. | Blackwater, Pearl Palace, Rana and Nessie gain four optional tunnel loops. Each has two surface connections, an upper gallery and a lower treasure pocket. There are now fifteen loops. |
| Platforms and collision | A painted shelf should agree with the swimming boundary. | Sixteen new perches are actual collision rectangles and are drawn from those same rectangles. Real-control route checks verify the entrances, lower loop and return path. |
| Speech and HUD | v0.15 already reduced intrusive tutorial UI. New social scenes should keep that space. | Residents speak in one local bubble, never a new modal or button stack. Their text yields to gameplay messages, charge, combat, transitions and family conversations. The existing compact HUD remains. |
| Interaction | More identical collectible tasks would feel repetitive. | Each pair shares a different pastime. Rest nearby for a hello; a passing Boost can stir a little harmless performance. There is no failure timer or compulsory task. |
| Saves and rewards | Welcome rewards need the same ownership guarantees as older discoveries. | Stable resident IDs and one 120-point welcome reward per neighbourhood use the existing checkpoint and ledger. Retry and actual title-screen Continue retain both residents and the exact reward. Legacy saves without these records remain valid. |
| Motion and visual load | Constant effects would compete with swimming and attack warnings. | Small skin deformation, gentle pose motion and bounded prop effects stop under Gentle Motion or quiet states. Economy reduces small effects. Offscreen districts stop material/prop updates; only two new character textures load per scene. |
| Existing Whimsy | New content must supplement Nori, the tea parties and reef activities. | Fresh visual fixtures cover the original Whimsy tableaux, Living Reef discoveries and Pocketful of Wonders encounters, alongside the eight new neighbourhoods. Existing gameplay, motion and save suites pass. |

## Eight places, sixteen new friends

These friends are in addition to Nori, Bramble, Lumi, Pip, the village neighbours and the family. The entrance coordinates below are world positions for finding and editing the areas in Godot; they do not appear as HUD instructions.

| Chapter | Neighbourhood | Residents | Surface entrances |
|---|---|---|---|
| Family lagoon tutorial | Quilt-and-Pearl Nursery | Mallow, a quilt-carrying sea bunny; Tilly, a baby turtle nursery helper | x 580 and 1160 |
| Highland Gold | Posy & Purl’s Garden Steps | Posy, the hermit-crab florist; Purl, the cuttlefish knitter | x 1200 and 2260 |
| Shadow Crab Kingdom | Lantern Story Library | Ludo, the frogfish lamplighter; Vesper, the ribbon-eel librarian | x 1900 and 2960 |
| Miguel’s Lagoon | Bubble-Tart Conservatory | Peep, the pufferfish pastry chef; Saffron, the leafy seadragon gardener | x 2360 and 3440 |
| Blackwater Tunnel | Pocket-Rain Tailor Shop | Button, the dumbo-octopus tailor; Hush, the umbrella jelly | x 4950 and 5950 — new tunnel |
| Pearl Palace | Very Polite Tea Terrace | Sir Crumb, a biscuit-and-tea crab; Dot, the pearl seamstress | x 7550 and 8740 — new tunnel |
| Rana’s Rainbow Ruin | Sleepy Shell Rehearsal | Miri, the shell-orchestra conductor; Oona, a dreaming narwhal | x 14940 and 16130 — new tunnel |
| Nessie finale | Little Sea-Star Observatory | Bibi, the batfish kite maker; Grandmother Thimble, the nautilus astronomer | x 3880 and 4700 — new tunnel; greetings follow Nessie’s defeat |

Follow the pearl-marked downward shafts. Swim around the central reef, visit the paired shell perches, explore the lower chest pocket and return through the other shaft. The old upper-gallery routes remain clear. Every district is optional, including the tutorial nursery.

## Small performances

Mallow and Tilly mind a pearl nest; Posy and Purl share a flower-and-knitting garden; Ludo and Vesper keep warm lamps and shell books. Peep’s bubble tarts puff, Button and Hush keep a very small rain shower, Sir Crumb’s cups lift politely, Miri’s notes drift around sleepy Oona, and Bibi’s kite joins Thimble’s sea-star chart. Resting nearby starts a greeting and a small flourish. Boost can stir the props without damaging residents or creating combat projectiles.

Stay near each resident briefly to meet them. Greeting both banks one 120-point Secrets reward. Further visits bring occasional lines, not repeat points. Leaving a neighbourhood is always allowed. Resident memories, completion and reward ownership persist; speech timing, rain, notes and decorative sparkles do not.

## Verification and limits

See VERIFICATION.md and verification/ for the final suite results, packaged-resource checks and visual counts. The new neighbourhood suite checks sixteen identities, solid platforms, real swimming through all eight district loops, quiet states, bounded nodes, retry ownership and a real save/title Continue round trip. The original eleven-loop suite still checks its full lower and upper paths.

The Android build uses the same application ID, signing certificate and save location as v0.15. Source archives contain a portable export preset with credentials removed. Original Whimsy paintings are retained in art-originals/whimsy-ii; new paintings and the built-in ImageGen prompt set are in godot/assets/whimsy-four/.

Physical Android installation, sustained frame rate and touch comfort still need a real device. These checks exercise the native desktop runtime and software-rendered window simulations; they do not claim a device playtest. A future accessibility pass could add optional larger world-caption text. A later content update could give each neighbourhood a distinct long-form quest; this release keeps their company brief and optional.
