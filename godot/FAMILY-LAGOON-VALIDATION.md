# Family Lagoon — v0.26 verification

## Tested

Godot 4.3 stable Linux, Compatibility renderer. Clean native asset import; all 22 gameplay, animation, environment, UI and journey validation suites passed. Family tutorial adds 122 behavioral checks and 20 layout checks.

The family suite exercises actual accepted swimming/boost/jump actions, three steering rings, reef crossing, powered-jump gifts, real boost hits on all three volunteers, all seven Daddy cycle phases, three successful green-window hits, parental dialogue and follow-up branches, actual coral peekaboo finding, companion/solo selection, tone-sensitive family farewells, and chapter continuation. It verifies that conversations freeze gameplay, baby is absent from the fight, learned bubbles remain unlocked, and companions survive retries and every chapter transition.

The original adventure suite covers every real chapter-selection button and the complete training-to-Nessie continuation chain. The original terrain collision coordinates are preserved. Sarah’s 18-loop / 432-pose movement, rock recovery, scoring, mobile controls, ocean effects and scene transitions remain covered by their existing suites.

Layout checks simulate 640×360, 844×390, 1024×768, 1920×1080 and 390×844 windows. Dialogue/choice panels fit, options scroll with controller focus, and companion buttons meet a 44-pixel simulated touch target. Native captures reviewed desktop parents/dialogue, gift demonstrations, Daddy’s green opening, real texture occlusion in peekaboo, companion choice, farewell and Highland following. Native 844×390 screenshots verify crisp fonts and readable scrollable dialogue.

## Release checks

The ZIP is CRC checked, contains directory entries required by Godot ZIPReader, and has a root project.godot. Final clean extraction/import and fresh tutorial/journey tests are recorded in the delivery check.

## Limits

Windows, Android/iOS hardware, web export and newer Godot versions have not been run in this environment. The new body gestures use connected weighted meshes rather than a separate skeletal animation editor. Queen’s tutorial Pearl Fan/Crown Halo/Pearl Wave are safe demonstrations; her independent Pearl Palace combat remains the existing basic encounter with upgraded body artwork. Avina’s single bubble shares the original projectile collision and scoring rules. Existing chapter gameplay outside the tutorial retains the prior release’s scope.
