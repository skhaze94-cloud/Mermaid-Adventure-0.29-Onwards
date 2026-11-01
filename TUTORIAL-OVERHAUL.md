# v0.25.0 — Tutorial Overhaul

This update focuses on the training lagoon (stage 7), its Pearl Nursery and Bellflower Hollow loops, and its teaching parents. Other chapters retain their existing cavern geometry and cast layouts. The complete Whimsy 4.0 world, paintings, characters and previous animation work remain included.

## Grottoes that invite exploration

The Pearl Nursery is wider, with separate side ledges for Mallow and Tilly. Tutorial entrances are 320 world units wide. Both chambers have clear central swimming space; the old central blocking reefs and the tutorial's repeated pearl staircases, arrows and entrance icons have been retired. Both openings still return to the lagoon. The existing controls, chest ownership and optional exploration rewards remain in use.

Two distinct painted backgrounds replace the repeated geometric treatment: pale limestone and turquoise light in the Nursery; lavender bellflowers and amber blooms in Bellflower Hollow. A feathered shader joins the room painting to the existing shaft water without stretching the room image down the shaft. Rounded rock outlines, original painted ledges and restrained kelp frame the openings. The tutorial card names the grotto and explains that either opening returns to the lagoon, without advancing the lesson.

New assets are `godot/assets/tutorial-v025/pearl-nursery.png` and `bellflower-hollow.png`. Both were created with built-in ImageGen; exact prompts, original dimensions and SHA-256 hashes are in `godot/assets/tutorial-v025/generation.json`. The full paintings are included; runtime imports are limited to 1024 pixels. All inherited art/audio/font bytes are checked separately in `verification/tutorial-overhaul/asset-preservation.json`.

## Residents with room and a conversation

Mallow and Tilly now occupy opposite ledges, more than 800 units apart. They take slow, individually phased, bounded strolls, stop when Sarah approaches, and retain the existing expressive character controllers. Conversation anchors sit in the open water, so Sarah can greet them without overlapping their faces. Their short lines receive a reply from Sarah through the existing caption owner. Leaving, pausing or suspending the scene cancels pending replies. Gentle Motion suppresses roaming.

Dozy now lives in Bellflower Hollow, where his lantern welcome and Sarah's response have their own space. His original once-only reward identity is retained. The fish greeting now also requires Sarah to be nearby; lingering fish trust can no longer interrupt Dozy after Sarah has left the fish. No failure timer or forced conversation pause was added.

## Daddy and Mummy

The teaching Daddy is 390 pixels high (410 during the trial), and Mummy is 410, replacing 250/310/270. Their positions and courtesy clearances account for this size. Mummy stands clear of her gift collectibles. The separate optional playable Daddy appearance is unchanged.

Tutorial parents opt into additional connected torso, hip, knee, leg and near-arm motion, with eased travel-driven swimming and settling. Daddy briefly welcomes Sarah back from below. Mummy alternates short waves and demonstrations with quiet pauses; her bubble emitter follows the scaled hand. Trial hits, progression and controls retain their existing timings. Other royal appearances do not opt into this shader motion. Gentle Motion suppresses it.

This is economical layered 2.5D animation using the established paintings, not a replacement 3D skeleton or newly authored full walking cycle. Movement stays deliberately small enough to preserve their painted silhouettes.

## Saves and preservation

The application ID, signing certificate, application save-directory name and save schema remain unchanged. Existing tutorial chest entries move to their revised berth, keeping their taken state and reward ledger. Retired pearl rows are removed from saved scene items while earned scores and ledger entries are retained. Existing positions recover into navigable water. Other chapter treasure merging is unchanged.

## Verification and preview

The current release suite contains 34 suites, including 15 focused tutorial-overhaul checks. It covers routes and returns, conversations, pause/Gentle Motion, resident separation and roaming, parent sizes, migration and reward ownership, as well as the inherited movement, story and layout checks. Current results and final package checks are in `verification/tutorial-overhaul/`; earlier verification directories describe historical releases.

The still review covers both chambers, individual greetings and Sarah's replies, parents and landscape phone layouts. The 34-second silent preview uses live character controllers with scripted cuts between locations; it shows the descent, greetings, Dozy and parents. Capture runs use the existing silent-capture setting to avoid audio during desktop review. The v0.24 baseline still viewer produced its complete still set but timed out on shutdown; those stills remain usable for the matched comparison. Current v0.25 still and movie viewers exit successfully.

The Android APK uses the existing signing identity. Packaged-resource checks on desktop do not constitute physical Android-device testing. No device FPS, thermal or touch-performance claim is made. Painted background detail, small sprite deformation and caption readability should still be checked on the intended Android handset.
