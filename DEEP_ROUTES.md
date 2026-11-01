# v0.14.0 — The Ocean Below

The Family Lagoon tutorial, Highland Gold (Stage 1), Shadow Crab Kingdom interlude and Miguel’s Lagoon (Stage 2) now have real optional underground routes. Swim down at the shell-and-arrow markers. Each complex has two surface connections, a broad central room, an upper gallery, a reef to swim above or below, and a lower treasure pocket. Bubble chevrons mark the route upward.

| Area | Cavern | Entry x | Return x |
|---|---|---:|---:|
| Family Lagoon | The Pearl Nursery | 580 | 1160 |
| Family Lagoon | Bellflower Hollow | 2100 | 2860 |
| Highland Gold | Nori’s Root Garden | 1200 | 2260 |
| Highland Gold | The Sunken Bell Cathedral | 6240 | 7400 |
| Highland Gold | Ribbonlight Archive | 11940 | 13020 |
| Shadow Crab Kingdom | The Lantern-Well Caverns | 1900 | 2960 |
| Shadow Crab Kingdom | The Upside-Down Moonpool | 5060 | 6240 |
| Shadow Crab Kingdom | The Lost Postbox Grotto | 8770 | 9890 |
| Miguel’s Lagoon | The Orchid Rootways | 2360 | 3440 |
| Miguel’s Lagoon | The Coral Amphitheatre | 8200 | 9410 |
| Miguel’s Lagoon | Silverstream Hollow | 16200 | 17500 |

Markers sit around y810, near the original seabed. Rooms extend down to roughly y2100 inside a playable world bounded at y2214 for Sarah. A real Camera2D follows vertical travel; the HUD and tutorial dialogue remain on their screen-space layers. Original water effects are repositioned to cover the viewport at depth. Sarah, her wakes and Avina retain world coordinates; Avina can follow into the lower rooms.

Collision and art share the same authored room rectangles. The underside of the seabed is solid outside the entrances and room paths. Surface rocks are cut only where new entrances need room. Caverns are drawn with rounded painted-water outlines, dark stone, planted terraces, hanging pearl lights and small jelly neighbours. No new raster artwork replaces the original paintings.

Every complex contains an optional chest and a short trail of pearls. The chest banks its stable reward and the actual underground berth. Retry and title-screen Continue restore the deep position and camera; rewards cannot be farmed. Old checkpoint treasure arrays gain new optional cavern items without changing the order or IDs of their old pickups.

The original lesson gates, switches, bosses, waterfall and exits remain on the main route. The tutorial’s first room fits before its first x gate; the second fits inside its ring lesson. The Highland opening room returns before the waterfall; the two later rooms lie beyond it. Later chapters retain their original vertical bounds.

Gentle Motion retains essential camera travel and playable routes while settling decorative motion. Economy retains all routes and rewards. Pause freezes travel and effects. Physical-device FPS requires testing.
