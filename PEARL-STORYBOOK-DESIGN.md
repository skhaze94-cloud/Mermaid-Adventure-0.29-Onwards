# v0.38 · Pearl Storybook — design before implementation

Selected direction: warm ivory and seafoam storybook UI, restrained Coral Charms accents. The original paintings and character likenesses remain the visual focus.

## Component specification

| Element | Shape and hierarchy | States and behaviour |
|---|---|---|
| Family conversation | Ivory rounded bottom dock; small painted portrait, ink speaker name, dark body text, small beat count; safe speech-tail cue only where space permits | One speaker and one authored beat at a time. Complete text immediately readable with a short fade. Continue always available. No forced typing delay. |
| Sarah's replies | Spacious outlined seafoam choices, ink text, visible focus ring | Optional, secondary to listening; wraps or scrolls at phone widths; all original branch callbacks retained. |
| Lesson hint | Short, two-line ivory cue and Help button at top-centre | One current instruction. Trial meter only during relevant lesson. Does not compete with open dialogue. |
| Health | Five pink painted pearl-heart icons in a small ivory card | Full, empty, damage, healing and low health readable without relying on colour alone. Brief restrained feedback; Gentle Motion stays quiet. |
| Boost/Jump energy | Slim turquoise meter beneath hearts, explicitly named Boost energy | Reflects real energy; low/ready state communicated by actual action availability. Kept distinct from bubble charge. |
| Bubble charge | Iridescent bubble icon and context meter | Locked, ready, held charge tiers, release and cooldown. Appears when useful; touch button owns its charge state on mobile. |
| Active gift | Golden fin charm with a thin duration ring and short label | Only real active effects. Tutorial Royal boost uses actual eight-second gift timer. No invented shield mechanics. |
| Score and pearls | Small shell/pearl card near pause | Existing counters and scoring retained; secondary during tutorial. Large values remain bounded. |
| Touch controls | Restrained ivory/seafoam enamel shapes, painted fin/bubble/jump icons, dark labels | Existing hit rectangles, analogue joystick, multitouch and cooldown semantics unchanged. Separate jump remains present. |
| Reward | Small warm toast and short floating points near discovery | One brief celebration, safe edges and distance from controls; no accumulating banners or constant sparkle. |
| Pause/results | Same ivory/seafoam family, dark type, clear primary action | Keyboard focus visible; modal input ownership and result scoring retained. |
| Cavern friend captions | Same ivory small speech treatment with occasional shell/slug accent | One visible caption owner, no overlapping duplicate speech or persistent decoration. |

Palette: ink #173e4b, warm ivory #fff4dc, paper #fff9ee, seafoam #83bdb0, mint #bce7d7, rose #c7567d and restrained gold #c99953. Existing story-serif body and bold fonts preserve the book-like identity. Text is live Godot text, not baked into art. Painted atlas icons remain crisp and reusable.

Layout: design for safe areas, 44px physical touch targets, phone landscape and desktop. Typography, wrapping and scroll reachability take priority over fitting fixed ornamental frames. The design board is aspirational; screenshots in the final review show implemented behaviour.

Animation: short ease-in entrances, brief finite health/reward responses, natural holds. Gentle Motion suppresses decorative movement. No expensive per-frame texture loading, blur or panel rebuilding.

Validation: review every tutorial conversation and choice, long replies, hearts/energy changes, all bubble tiers/cooldown, actual gift expiry, pause/results, phone safe areas and touch input. Check original world, animation, save and progression files for unintended changes.
