# v0.22 validation

Tested with Godot 4.3 Linux OpenGL Compatibility (Mesa llvmpipe) and headless logic. Windows, mobile hardware and newer Godot binaries were not run here.

All 17 suites pass: complete_adventure, device_layout, enemy_engagement, enemy_visuals, environment_visuals, gameplay_controls, journey, jump_animation, level1_smoke, rock_collision, sarah_breaststroke, sarah_continuity, sarah_fluid_motion, sarah_magnifique, scoring_ui, title_flow, scene_flow.

Complete adventure: 95 checks, zero failures. Rock collisions: 1,153 checks, zero failures. Sarah breaststroke: 1,449 checks; continuity: 4,325; fluid motion: 738; all zero failures.

Scene flow exercises actual background loading and animated transitions in both normal and reduced motion, duplicate requests, missing paths and return from a paused level. Headless regression suites use a synchronous handoff to keep frame-count assertions deterministic; scene_flow_test explicitly exercises the animated/threaded path.

Native rendering: 24 chapter entry/rock/boss images and three menu viewports. Preview recorded from native Godot at 960×660. Reviewed the title, chapter browser, transition cards, Highland HUD, pause presentation, Shadow Crab, Palace and Nessie. Previous tail, arm, torso and rock collision work is retained.

The ZIP is CRC checked and includes directory entries before files for Godot’s project importer. Extract into a new empty folder and import the root project.godot.
