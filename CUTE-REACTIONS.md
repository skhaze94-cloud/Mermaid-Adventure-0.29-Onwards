# v0.24.0 — Cute Reactions

A focused personality pass for the sixteen Whimsy residents, built on the complete v0.23 character-animation source. Sarah, her family, story creatures, existing fin/shell detail, world, conversations, progression and saves are retained.

Each resident now owns a small scene-clock performance controller. Approaching their conversation area starts a notice, hello, shy settling and rest sequence. A rising edge of the existing activity flourish starts a short delighted response. A fourteen-second greeting cooldown and proximity hysteresis prevent repeated greetings while Sarah stays nearby. A held celebration signal does not continually restart its animation.

| Resident | Character of the performance |
|---|---|
| Mallow | Small shy inclination, ear response, gentle lift |
| Tilly | Friendly buoyant flipper greeting |
| Posy | A perkier feeler hello and welcoming lean |
| Purl | Restrained nod with a softer tentacle response |
| Ludo | A small bob and fin greeting |
| Vesper | A quiet inclined look with ribbon-fin movement |
| Peep | A brighter buoyant greeting and cheek warmth |
| Saffron | A softer lean with leaf-fin response |
| Button | A more playful arm greeting |
| Hush | One of the quietest, gentlest responses |
| Sir Crumb | A modest polite bow and claw response |
| Dot | A small attentive inclination |
| Miri | A stronger conductor-like arm response |
| Oona | A quieter dreamy lift |
| Bibi | The most buoyant greeting and stronger fin response |
| Grandmother Thimble | A restrained, unhurried-feeling nod |

The shared sequence uses separate per-character tilt, lift and greeting strengths, plus the existing independently phased appendage detail. Small gaze-like shifts within the painted face region and subtle cheek warmth accompany the poses. These are conservative painted expressions: the original eyes and mouths remain intact, with no newly painted facial frames or blink artwork. Local gaze direction accounts for the second actor's mirrored artwork, while body inclination uses world direction.

The controller uses the neighbourhood's clock and attention/flourish signals. It owns no gameplay inputs, saved state, rewards or independent timers. Quiet/Gentle mode clears the added offsets and expression values. Resuming nearby does not automatically replay a greeting. Rewinding the scene clock resets transient state. Hidden rooms retain the existing visibility controls. There are no new texture loads or character nodes during animation.

The twelve-second silent inspection preview shows staggered greetings followed by a shared happy response, at 24 fps. Native room views also cover all sixteen residents, phone layouts and Gentle/Economy. The update adds shader work; physical Android frame time, thermal behaviour and touch testing remain unmeasured.

Current validation is recorded under `verification/cute-reactions/`. Earlier directories, including the documented fourteen historical failures in v0.23, describe previous releases and are retained for provenance. The new performance test checks all sixteen controllers for greeting order, bounded transforms, no repeated celebrations, quiet/resume behaviour and clock rewinds.

Validation: all 33 release checks pass in the working source and clean ZIP extraction. Four final APK resource checks pass. The original certificate and app ID are retained, with version 0.24.0 / 2400; APK signature and 16 KiB ZIP alignment pass. All 141 inherited art/audio/font files are byte-identical. The 32-view room batch emitted its completion message but timed out during process shutdown on the software desktop display. A separate native room smoke test captured four settled/happy views and exited successfully, as did the twelve-second preview. This desktop audit shutdown limitation is retained in the evidence rather than claimed as a clean batch exit. Physical-device testing remains outstanding.
