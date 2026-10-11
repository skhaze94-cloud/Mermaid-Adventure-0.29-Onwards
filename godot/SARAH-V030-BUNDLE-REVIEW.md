# v0.30 — Ultimate Definitive Sarah Maria bundle

## Swimming, elbows and hands

Ordinary horizontal swimming follows a repeating seven-stroke pattern: two ordinary strokes, one breaststroke, three ordinary strokes, one breaststroke. A separate horizontal stroke clock keeps boost, vertical travel and waterfall activity from consuming that cadence. The animation phase continues across changes, and the existing stroke blend prevents hard switches. Directional swimming and waterfall balancing retain their appropriate strokes.

Breaststroke recovery folds the elbows more deeply inward. The authored fold reaches approximately 71 degrees, with a bounded, damped runtime response. The two arms keep coordinated breaststroke timing, while crawl and climbing strokes retain their alternating motion. Hand cupping is a small deformation of the original painted finger fan: it closes slightly during the catch and releases during recovery. It does not replace Sarah's hand artwork or add separate floating fingers.

## Connected shoulders and torso–tail art

The sleeve roots now blend over opaque bodice paint instead of covering it with a hard second edge. The blend follows each arm's rotation, scale and chest transform. It samples conservative neighbouring alpha before feathering, so the outside shoulder contour keeps its original opacity. Shoulders also load inward during the catch and release with the elbows through a bounded, damped roll. The existing shoulder glide, independent ribs, neck follow and anchored sleeve band remain active.

The waist treatment goes beyond the previous colour gradient. The lower bodice scales fade over the actual tail beneath them, while both pieces share a stronger blue-pearl transition. This removes much of the rounded pasted-cap appearance without inserting another waist band or duplicate tail layer. The original outer silhouette is retained wherever the tail is not safely opaque behind it. The separate meshes remain useful for animation; the new treatment makes their visible overlap read more continuously.

All original binary artwork is preserved. The redesign uses the existing paint, geometry and native shaders.

## Opening refresh

The opening now uses the complete gameplay Sarah instead of moving a static title image. She swims in, greets the player, performs several breaststrokes, then returns to a relaxed hover with a later hand gesture. Face, hair, arms, shoulders, torso and tail use the same controllers as gameplay. The performance repeats gently on the menu.

The opening remains skippable and the menu buttons are immediately usable. Gentle Motion and Economy present a quiet character instead of the entrance and recurring performance. Replaying the opening resets its performance. Compact landscape layouts use a smaller heading and tighter spacing, making the desktop 720p menu actions visible together; smaller phones retain native scrolling. The footer now identifies v0.30.

## Review and verification

- 32 regression suites passed, including a new bundle test for actual recurring breaststroke, hand cupping, moving shoulder-blend registration, cadence reset, boost exclusion, live opening animation and comfort settings.
- The arm review passed 9,188,399 checks across twelve strokes, five gestures and six aerial styles in both facings, plus input transitions and 30/60/120 Hz comparisons. Painted skin triangles stayed finite and did not collapse or invert in the sampled poses. Source-alpha checks kept shoulder/waist joins connected and front arms clear of facial landmarks.
- Native compatibility rendering reviewed the shader-driven shoulder and waist blends, which source-alpha geometry checks alone cannot validate. The preview includes the opening, 16 seconds of automatic stroke selection, all twelve strokes, six aerial performances, gestures, waterfall climb, turning and recovery.
- Desktop, phone, tablet and portrait menu renders were checked, alongside the existing keyboard, controller, mouse, skip and scene-transition tests. Native waterfall gameplay renders cover climb, dive and boost.
- The packaged project is freshly extracted, checked byte-for-byte, imported, started and validated with nine suites against the extracted copy. `project.godot` is at the archive root.

Validation results are in `validation-v030.json`. The preview's right panel is an intentional close-up; the left panel provides the full-body review. These checks cover the current library and tested transitions, rather than guaranteeing every possible future pose or artwork change.
