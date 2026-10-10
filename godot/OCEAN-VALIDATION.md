# v0.23 validation

Godot 4.3 Linux: all 17 retained suites and the new Ocean Alive suite pass. The new suite has 117 checks with no failures, covering all eight chapters, independent audio mutes, valid looping WAV streams, the fixed voice/ripple pools, rejected actions, duplicate rewards, boss hit/departure/retry presentation, and reduced motion.

Original WAV assets: all sixteen decode, contain audible samples without clipping, and have valid channel/sample rates. One-shot endpoints fade to zero. Ambient loop boundary differences stay within normal filtered sample-to-sample variation.

Native OpenGL Compatibility/llvmpipe: twenty-four chapter entry/rock/boss captures and three menu sizes. Native Movie Maker preview records the actual scene art, mesh shaders and mixed game audio at 24 FPS; captures include Carlo, Miguel, Queen Antonella and Nessie. The mixed track is checked for silence and clipping. Movie audio is normalized for comfortable preview playback.

Packaging: CRC, explicit directory-first extraction and fresh editor import are checked. No attack timings, source routes or collision shapes are changed by the presentation actors or decorative fish. Previous rock rescue and Sarah arm/tail continuity suites remain passing.

Windows, mobile hardware, newer Godot binaries and physical speaker/controller output were not tested in this environment. Final device performance and sound balance should be confirmed on the intended device.
