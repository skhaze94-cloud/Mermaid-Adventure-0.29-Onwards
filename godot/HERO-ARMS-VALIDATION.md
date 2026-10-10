# v0.25 Hero Arms validation

Godot 4.3 Linux, OpenGL Compatibility (Mesa llvmpipe). All twenty regression suites pass without script or resource errors. The arm suite now has 1,689 checks: synchronized breaststroke, extended hand travel, relaxed recovery limits, smooth dash transitions, forward reach, stable dash poses, fixed shoulder attachment, finite geometry, unchanged texture UVs and reduced-motion/restart reset.

Sarah continuity: 4,325 checks; fluid motion: 1,914. New depth-motion suite: 1,086 checks. All eighteen 24-pose loops are distinct, correctly selected by actions/movement, smooth through transitions, and reset in reduced motion/restart. Jump and expression/gesture suites pass. Rock rescue: 1,153; grounding: 487; full adventure: 95; ocean life: 117. Chapter routes, collision geometry and movement controls are unchanged.

Native in-game renders cover greeting, swimming, rising, turning, dash, cast, impact, reward, celebration, gentle mode, economy mode and a motion loop. The Movie Maker preview uses the actual in-game rig and audio, enlarged only for presentation. All video frames decode after export.

The package is CRC-checked, extracted with Godot’s directory-entry sequence, and freshly imported into the native editor. The fresh copy reruns breaststroke, continuity and chapter-completeness checks.

Windows, newer Godot binaries and physical mobile hardware were not tested here.
