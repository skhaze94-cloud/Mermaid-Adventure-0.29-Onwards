# v0.4 — Ultimate Mega-Max Polish

## Visible cleanup

The touch pad is now a restrained circular control with a clear thumb marker. Jump uses an upward arrow and water mark; Boost uses two forward chevrons; Bubble uses outlined bubbles; Pause uses two bars. Locked Bubble has a clear lock. Low energy and cooldown cues remain distinct. Enlarged action controls separate vertically to avoid overlap at the largest touch-size setting. Input and artwork continue to use the same geometry. Diagonals and multitouch remain active.

The oversized painted joystick, thumb, tail-shaped jump icon, lightning badge and ornamental pause icon are removed from gameplay. Decorative icons are also removed from menu and modal action buttons. The five useful score/health/result symbols remain. Eleven unused UI images are no longer loaded or included in the playable ZIP.

Reward feedback uses a compact, readable toast rather than the old stretched floral ribbon and floating star decorations. Chapter names have quieter capitalization, sit below the score and move below the combo meter when needed. Boss names and vulnerability cues appear in one compact HUD card. A new regression catches the wrapped-title panel expansion found during rendering.

Large permanent rings, world health strips and duplicate boss instruction text are removed. Small brackets mark vulnerability without surrounding the whole creature. Attack aim lines, claw sweep warnings, Rana’s laser and Nessie’s actual attack pulse remain. Shadow switches use Bubble/checked symbols instead of a keyboard-specific B. Launch spots use a small upward water cue instead of the floating green JUMP oval.

The ghost copies around attacking cuttlefish are removed; the real enemy keeps its warning cue and artwork. Nessie’s extra disconnected UI crown is removed. Portal instructions appear once the route opens. Repeated chapter footer text, teacher name labels and the unused hand-painted legacy HUD/control/overlay functions are removed.

Shadow Kingdom and Blackwater now tint their already-underwater paintings continuously, removing the false horizontal surface stripe and abrupt rectangular tint boundary. The unnecessary pale procedural palace columns and tunnel ring are removed. Foreground plants have stronger paint opacity; distant atmospheric layers retain their intended depth. Elevated reef supports retain their recessed background treatment; collision-bearing caps stay clear. Collider locations are preserved.

Dialogue cards are opaque, keeping the character behind them from ghosting through text. HUD, touch labels and remaining world hints use the same scalable story typography. The tutorial’s controller instructions now match the actual inputs: B for Boost and A for Jump. Reef instructions describe the visible landmark instead of exposing internal world coordinates.

## Scope and checks

Reviewed all eight chapters at entry, reef and boss positions, chapter selection, menu/opening, options, credits, desktop/phone/tablet/portrait layout, touch controls, long scores, pause/results, waterfall climb/dive/boost, family dialogue, teacher demonstrations, peekaboo, companion choice and farewell.

22 regression suites cover visual layout, gameplay controls, every chapter, scene transitions, scoring, collisions, enemy behavior, environmental grounding, family interaction and Sarah continuity. The new polish suite checks that the boss panel stays compact, chapter/combo spacing is clear, action targets stay inside the safe viewport and controls hide during pause. Eight suites also run on a freshly extracted release after byte comparison, Godot asset import and startup.

Native rendered views validate the actual shaders, art placement and text. They simulate window layouts on the Windows compatibility renderer; they are not physical phone performance tests. Existing intentional translucency in water, bubbles, mist, distant scenery and brief damage response remains part of the game. The reviewed routes and states do not guarantee all possible future edits or device combinations.

Scene-transition cleanup also tolerates an incoming scene being removed during its reveal, releasing the overlay without touching a freed actor. A regression exercises this interrupted reveal. The family capture waits for the actual transition to finish before photographing the next chapter.

## Clean playable package

The ZIP has project.godot at its root, with godot/ and dist/ beside it. It excludes capture scripts, tests, historical reports, previews, import caches, development Python helpers and the eleven unused control images. The repository retains development history and the original assets. Original artwork and audio are preserved byte-for-byte; no changes are made to the old MermaidADVENTURE repository.
