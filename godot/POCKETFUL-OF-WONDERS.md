# v0.12.0 Whimsy II: Pocketful of Wonders

Source package release: v0.12.0. No repository merge is implied by this package. Sixteen optional storybook encounters add little spectacles, neighbours and shared jokes to the painted ocean. There are two per chapter, alongside the existing Living Reef activities. They introduce no new required lesson, boss rule, portal gate or companion choice.

## Five ways to find a wonder

- **Dream bubbles:** swim into the bubble and linger nearby. Its miniature whale, shell carousel or soft star-rain unfolds in a short sequence.
- **Tiny tea parties:** float quietly beside the table. A little butler, jelly guest, carefully served cups and an oversized bubble make an extremely dignified tea party.
- **Shell villages:** approach and watch the shy neighbours. Boost nearby for a brief “bring in the washing” mishap; the village settles again afterwards.
- **Bubble mirrors:** rest beside the mirror for a six-beat pantomime: an idea, Sarah’s bubble, her partner’s echo, a copied face, a passing fish’s surprise and a shared giggle.
- **Nori’s post:** pause beside the sea-slug postman to read a short, three-line letter.

These use normal swimming and Boost. There is no additional interaction button or failure timer. Moving away leaves Sarah free; a moment can be visited again. Nearby active combat, loading, waterfall travel, family dialogue and playing as King Daddy keep priority.

| Chapter | First wonder | Second wonder |
| --- | --- | --- |
| Highland Gold | The Pocket Whale — dream | The Thimble Tea Party |
| Shadow Crab Kingdom | Drowsy Lantern Lane — village | Nori’s Lantern Post |
| Miguel’s Lagoon | The Shell Carousel — dream | The Orchid Looking Pool — mirror |
| Blackwater Tunnel | A Rain of Sleeping Stars — dream | Nori’s Star-Mail |
| Pearl Palace | Pearl-Petal Hamlet — village | One Spoonful of Stardust — tea |
| Rana’s Rainbow Ruin | The Rainbow Whale’s Nap — dream | The Rainbow-Shell Village |
| Nessie | Nori’s Homeward Letter | A Crown-Sized Reflection — mirror |
| Family Lagoon | A Teacup Before Goodbye | Two Very Silly Mermaids — mirror |

Highland’s new moments are beyond the waterfall. Nessie’s appear only after her fight. The family’s wait until lesson 10 and are optional backtracking visits, leaving the open exit and original companion choice intact. The compact finale’s mirror uses a separate upper-water position to keep clear of Pip’s route; other stations have broad horizontal separation from Living Reef.

## Together or solo

The mirror partners with Avina only when she is actually visible, following nearby and free of a pending gameplay bubble. Otherwise a friendly fish joins Sarah. Choosing to leave Avina with her family never removes the mirror story or silently brings her along.

All mirror bubbles are presentation, not combat shots. They request no real baby bubble, damage, movement or unlock. A player action, held charge, cast, impact, jump or departure can cancel the pantomime without consuming input. Existing Living Reef attention and family speech are respected.

Gentle Motion keeps all six beats using quiet painted expressions, without the additional gaze/wave movement. Other ornaments settle while the story’s cues remain readable. Economy keeps the encounters and rewards available alongside the existing game quality settings.

## Memories and replay

Each first completion grants a stable Secrets award of 100–150 points and banks that memory through the existing checkpoint path. Across all sixteen authored moments the first-visit rewards total 1,825 points. Replays never award more.

After a completed visit, leave the local area and return after its cooldown to replay the little story. A checkpoint stores only each wonder’s ID, discovered flag and completed flag, alongside the normal reward ledger. Cups, laundry, bubbles, elapsed time and unfinished performance phases are deliberately transient: retry/Continue restores the remembered invitation or completion, then begins any replay cleanly. Older checkpoints can omit the new memory field. Validation rejects unknown or duplicate IDs, malformed flags and completion that disagrees with ledger ownership.

## Authoring and bounded presentation

`pocket_wonders_data.gd` supplies two authored profiles per chapter, with fixed IDs, local copy, eligibility and safe interaction points. Villages and postman feet use actual `Terrain.ground_y`; dreams and mirrors float, and tea-table feet sit below their interaction focus. Decorative points do not create a new target sequence or collision body.

`pocket_wonders.gd` owns invitations, timed scene phases, re-entry and rewards. `pocket_wonders_reactions.gd` manages the six-beat exchange through the existing painted rigs. `pocket_wonders_art.gd` presents at most two visible tableaux, one local caption and a fixed 12,288-vertex Whimsy brush surface. Selected chapter art loads during scene setup, not on approach. Scene props do not enter physics or combat projectile pools; short sound queues reuse the current audio voices.

The [painted-art record](assets/pocket-wonders/README.md) documents the new cutouts and their provenance. Existing artwork and quality settings are retained. Bounded implementation is not a hardware FPS claim; physical-device profiling remains necessary.

## Verification entry points

The package runner registers **23 suites**, adding `pocket_wonders_test.gd` and `pocket_wonders_reactions_test.gd` to the previous 21. The model checks exercise all sixteen stations through real swimming/rest, the village Boost gag, story eligibility, first rewards versus replay, stable-memory validation and interruption behavior. A native save-worker/title-Continue case restores the remembered letter, exact owned reward and safe berth without duplication. Reaction checks cover solo/Avina partners, the six actual beats, protected player actions, Gentle Motion and unchanged gameplay/painted registration. These fixtures isolate optional play from enemy pressure; they do not replace human balance playtesting or physical-device profiling.

## Little reef neighbours

Nori keeps a tiny grounded postal round and turns toward Sarah. Bramble the octopus butler and Lumi the moonjelly host the tea parties. Pipkin the crab helps with the shell village washing. After a completed encounter, a relaxed nearby Sarah may receive a short friendly comment. Chatter is spaced by 24 seconds, appears in a local caption, and yields to gameplay speech, charge input, combat and travel. It grants no extra reward. Retry clears the temporary comment while preserving encounter ownership. Original master PNGs and generation provenance are included in art-originals/.
