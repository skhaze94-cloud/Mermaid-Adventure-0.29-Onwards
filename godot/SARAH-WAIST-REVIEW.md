# Sarah v0.29.6 — Unified Waist

The purple bodice and turquoise tail previously met with a strong palette change. A narrow blue-pearl transition now crosses their overlap: the lower bodice gradually picks up the tail's cool tones, and the proximal tail picks up the same pearl colour. Both masks follow the existing painted UVs, so the transition bends with the scales instead of sliding over them.

Source luminance, scale highlights, texture alpha, mesh shape and the anchored hip socket are preserved. The treatment remains active in both quality settings and with reduced motion. Other body pieces do not opt in. The original binary artwork is unchanged.

This is a targeted colour treatment, rather than new painted anatomy or a change to the motion system. The existing rounded bodice hem and different scale sizes remain visible.

`capture_sarah_waist.gd` renders matched before/after poses from the production rig: idle, swimming, rising, boost, waterfall climb and turning. The before view disables only the new palette treatment. Both views use the same movement and independent torso controllers.

Validation: the existing 30 regression suites, fresh package extraction/import/startup and seven fresh-copy suites. Native compatibility rendering checks shader compilation and the waist in motion. Results are recorded in `validation-v0296.json`.
