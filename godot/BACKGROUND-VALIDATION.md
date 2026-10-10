# v0.24 validation

Godot 4.3 Linux, OpenGL Compatibility (Mesa llvmpipe). All nineteen regression suites pass. The new grounding suite runs 487 checks covering unchanged source collisions across eight chapters, exact plant/terrace height alignment at three camera positions, stable foreground root placement, unified Highland formation art, and near-floor treasure pedestal bounds. Rock rescue: 1,153 checks; Sarah continuity: 4,325; breaststroke: 1,449; fluid motion: 738; chapter adventure: 95; ocean life: 117.

Native renderer review covers entry, obstacle and boss views in all eight chapters, three chapter-menu sizes, and the eight chapter exits. The native Movie Maker preview includes every chapter and portal with the actual game art and mixed audio. World UVs keep support and seabed texture detail at a fixed scale; muted recessed supports remain decorative, while original rectangles retain collision ownership. The waterfall keeps its continuous dedicated painting and phase transitions.

The nineteen logic/visual regression logs finish without script or resource errors. The audio-pool test uses a 60 FPS frame limit so the dummy audio driver can flush its stopped WAV playbacks before shutdown. Screenshot capture disables audio playback; the recorded preview includes audio.

ZIP CRC, Godot directory-entry extraction, and a clean native editor import are checked. A fresh extracted project reruns chapter completeness, grounding and rock rescue.

Windows, newer Godot binaries and physical mobile hardware were not tested here. This is a presentation update: imported collision shapes, boss attacks and chapter routes are preserved.
