# v0.8.0 Boss Polish

This update implements the requested encounter review, boss identity and victory-feedback work. Health totals, artwork, shaders, projectile/impact capacities and chapter order are retained.

| Encounter | Identity and fairness changes |
| --- | --- |
| Carlo | Claw circle, three-lane pearl fan and locked-target dash. Full-circle claw warning matches the actual hit area; the fan previews all three lanes. Windup lasts 1.1s and recovery 2.5s. Windup contact is safe. Energy-aware guidance teaches Boost before Bubble unlocks. |
| Duke and Flip | A 0.55s world-locked fan warning accompanies Flip’s visible orbit. Duke’s ordinary recovery starts at 3.3s in the 5.4s cycle, leaving 2.1s for a charge and nearby travel. Comedy collision clears queued fire and announces the shared opening. Bubble hits now earn the same per-HP rewards as boost hits. When only one partner remains, the HUD names that partner; Flip’s always-open shell remains accurately reflected. |
| Miguel | A 0.50s locked maraca-fan warning leads into the existing dance/lunge rhythm. Successful hits no longer erase his recovery window, leaving time for deliberate follow-ups. |
| Baron Bite | Crossing pincer pearls retain the moving shark. A 0.48s warning fixes both origin and heading in world space, so the subsequent attack matches the marked lanes. Volley interval: 1.0s. |
| Queen Antonella | Alternating crown fans/gates retain their distinct geometry, with 0.48s warning and 1.15s interval for breathing room. |
| Rana Rex | Rainbow fan and depth-changing laser form separate beats. New volleys stop at 2.3s; Rana’s own old pearls clear before the laser. The thin line warns; the thick line appears only during the actual 2.8–3.3s damaging interval. Unrelated enemy projectiles are preserved. |
| Nessie | Offset cresting pearls follow her movement, with world-locked warning origins, 0.48s warning and 0.95s interval. The existing decorative pulse and recovery remain. |
| Royal family trial | Existing six-move teaching routine retains its attacks and protected teachers. Intro windup contact is safe, the wave phase previews Dad Dash, move names reach the HUD, and the 600-point clear plays victory audio. |

Retreating outside the combat gate cancels queued fire and restarts anticipation without restoring boss HP. Retries clear transient warnings. One bounded three-shot warning queue is shared by the journey encounter code; its line geometry is cached when queued. The four later encounters reuse their existing three-shot storage. No new visual or audio assets, particle pools, timers or scene nodes are introduced by the warning queue.

Successful hits keep their existing authored flashes and pooled feedback. Every ledger-owned boss clear restores energy, gives 1.2 seconds of arrival protection, removes hostile shots and uses priority victory guidance. Boss reward banners identify hits/clears. Defeated portraits settle into recovery while their existing fade plays; Gentle Motion retains the quiet fade. Cooldown guidance waits for lavender arcs instead of inviting a blocked hit.

Automated validation and native capture results are recorded in `validation-boss-polish.json`. These checks establish timing, collision/ownership safeguards and visual behaviour; human difficulty/fun testing and physical-device frame-time measurements remain outstanding.
