# v8.2 source data

Input: `Sarah-Maria-Family-Adventure-8.2(1).html`
SHA-256: `5349f152f33cdfa2b491500e1e306bc7b70af9c901cd2a826ef0813d1c9e343f`

The original embedded scripts were executed in a local Node VM with DOM, audio and rendering stubbed out. The actual `setup()` functions for training, Highland, Miguel, Palace and Rana, plus `setupShadowCrabKingdom()`, `setupDarkTunnelChapter()` and `beginNessieFinal()`, produced `levels-v82.json`. It preserves source metadata, obstacles, enemy spawn states, rewards, launch pads and boss parameters. No online game code was executed.

`chapter_data.gd` adapts this data into Godot arrays and native creature types. Ordinary pickups and enemy spawns are moved outside solid collision margins. Six existing Miguel creature-pack types occupy original encounter anchors. The Nessie twist originally inherits Rana’s 41,600-unit world but confines its fight to x=2730–3650; the separate native final chapter keeps those arena coordinates and uses a 5,500-unit bounds/exit route. Old unreachable pre-finale rewards are omitted there. Tutorial lesson state machines, full dialogue trees, exact boss choreography, moving palace architecture and advanced Blackwater lighting remain later polish work.
