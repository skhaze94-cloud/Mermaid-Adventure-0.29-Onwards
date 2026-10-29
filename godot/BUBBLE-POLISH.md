# v0.7.0 Bubble Polish

This pass focuses on Sarah’s bubble combat. Artwork, shaders, animation detail, render settings, projectile pools and impact pools are retained.

| Bubble | Hold | Enemy damage | Boss damage cap | Speed | Recovery | Enemy hit recovery |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Pearl Pop | Quick release | 1 | 1 | 700 | 0.20s | 0.16s |
| Prism Bloom | 0.35s | 2 | 1 | 780 | 0.35s | 0.28s |
| Royal Aurora | 1.35s | 4 | 2 | 860 | 0.45s | 0.36s |

Pearl Pop remains the fast repeated shot. Prism delivers a two-point burst with a shorter commitment. Royal Aurora can defeat an ordinary four-HP enemy in one clean hit, travels faster and recovers in 0.45s instead of 0.65s. It is a charged burst, not a replacement for every quick shot.

Previously ordinary enemy hit recovery lasted 0.60s even when Sarah recovered in 0.20s, wasting accepted follow-up bubbles. Successful Sarah bubble hits now use 80% of that tier’s firing recovery. Boost and Avina retain their existing hit recovery. Guard blocks still open a recovery opportunity without losing HP; bosses retain their damage caps, vulnerability windows and shared hit cooldown. Each packet is consumed before damage callbacks, so shorter enemy recovery cannot duplicate rewards or hits. Swept collision remains authoritative at the faster travel speeds.

Prism has a one-time soft readiness cue. The three releases use distinct pitches of the existing bubble recording; no new audio streams or voices are allocated. Successful charged hits provide brief controller feedback, omitted in Gentle Motion. Existing tiered impact art remains unchanged. Charge thresholds, cancellation on pause/focus loss/Boost/Jump, pool refusal and protected tutorial characters retain their safeguards.

Validation is recorded in `validation-bubble-polish.json`. The new live-combat suite checks actual released packets, travel distances, damage, recovery, release pitch, guard preservation, cancellation and reward ownership. Existing Opal, adventure, tutorial and controls checks cover all boss gates and input routes. Native checks do not replace human balance playtesting or real-device FPS measurement.
