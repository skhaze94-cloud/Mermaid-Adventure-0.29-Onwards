# v0.23.0 — Character Animations

Built from the complete v0.22 Painted Reef source. All 141 inherited art, audio and font files are unchanged. Collision, controls, dialogue, story rewards, save format and the Whimsy world are preserved.

## Coverage

The update adds restrained secondary detail to existing performances. It retains the established action libraries and paintings, rather than claiming a new full rig or new action clips for every character.

| Character | New independently phased detail |
|---|---|
| Mallow | Ear tips and quilt-covered shell |
| Tilly | Lower flippers and shell/nest region |
| Posy | Upper feelers and shell garden |
| Purl | Lower tentacles and mantle fringe |
| Ludo | Lower fins and side fringe |
| Vesper | Curled lower tail and upper ribbon fin |
| Peep | Side fin and lower body breathing |
| Saffron | Lower tail leaves and upper fronds |
| Button | Lower arms and soft ear fin |
| Hush | Hanging fringe and side tentacles |
| Sir Crumb | Lower legs and side claw region |
| Dot | Lower garment/fringe and side shell edge |
| Miri | Lower arms and side fan |
| Oona | Lower tail and side fin |
| Bibi | Broad side fin and lower fin |
| Grandmother Thimble | Lower arms and nautilus shell |

Each of these sixteen paintings has separate authored UV regions for its appendages, secondary detail and protected face. Their phases vary by character. Smooth activity envelopes leave quieter intervals. This is conservative 2.5D painted deformation: shells and appendages move within connected painted regions, not as detached cutouts or new 3D objects.

Sarah receives a small alternating wrist relaxation during unoccupied idle moments. Her existing full movement, turning, expression and jump libraries remain. Idle detail yields to her gesture player, bubble hold, boosts, jumps and hit response. Daddy and Antonella gain a small distal hand follow-through within their existing royal skin; Avina gains a second tail-fin beat within her existing protected-face shader.

The shared articulated creature skin gains a small distal ripple, covering the core creatures and the chapter-specific bosses/creature variants that use it. Existing species-specific joints, attack anticipation and recovery retain ownership. Nori gains an additional independently phased feeler-tip movement while retaining his mantle, mailbag and existing walking performance.

The dream whale, moon jelly, octopus butler, Pocketful postman and Living Reef guide paintings now use reusable animated sprites with local appendage detail. Shy gold fish, moonfish and Dozy have dedicated regions. The four optional stories and their reward ledgers remain intact. Existing procedural tiny fish, shell-choir performances and other drawn encounters retain their original animations. Dialogue portraits, buildings and menu icons remain still.

## Ownership and cost

All new detail uses the owning scene/model clock, never shader TIME or independently running timers. Paused clocks freeze poses; Gentle Motion disables the added local deformation. Sarah's rest detail respects her established action priorities. Enemy detail is gated by the existing detail/quality controls. Sprites are pooled and reused, hidden at the next presentation pass when unused, and freed with their owner. Paintings load through the existing scene setup; animation performs no texture loading. Facial masks limit deformation around eyes and mouths.

The effects add shader work. There is no new Android FPS claim: physical-device frame time, thermal behaviour and touch testing remain outstanding. Full-quality and Gentle renders were reviewed on software desktop OpenGL. The six-second, silent preview shows all sixteen Whimsy residents using the new detail material, at 24 frames per second; it is an animation inspection board rather than a gameplay recording.

## Validation

The 32 release checks pass, including the new sixteen-profile/gentle/clock/120-frame sprite-pool checks, the Sarah 2.1 suite, complete adventure, Whimsy, tutorial and saved rewards. Four checks of the final APK's packaged resources pass. The APK retains the application ID and original signing certificate, with version 0.23.0 / 2300. Its certificate, signature and 16 KiB ZIP alignment were checked.

The visual audits cover all sixteen residents in their native rooms, phone/Gentle layouts, the tutorial/story scenes, and 48 Pocketful views. Current evidence is under `verification/character-animations/`; older report directories describe earlier releases. A broader historical test sweep also contains failures outside the release gate; the baseline comparison is recorded separately rather than presenting every historical test as passing.

The broader sweep ran 54 tests: 40 passed and 14 historical tests failed. All fourteen also fail on the unmodified v0.22 baseline, with matching exit codes and error counts. `legacy-parity.json` names them; `historical-sweep.json` records the complete sweep. They include older mesh-density, chapter-length and collision assumptions. They are not silently represented as passing. The published release gate remains the 32 current checks.

An additional 48 native action/family renders cover the six core and six lagoon creature families, boss phases, Sarah bubble holds/releases and royal teachers. No shader compilation errors were found in the visual audit logs.

All 32 current release checks also pass from a clean ZIP extraction after a fresh editor import. Shader include files and the twelve 512-pixel authored import limits are included.
