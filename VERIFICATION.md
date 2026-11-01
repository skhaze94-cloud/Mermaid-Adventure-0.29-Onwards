# v0.36 current verification

Supplied Linux4.4 native rendering and164,916 counted source checks pass, plus title/layout suites. Windows embedded pack117 checks; Android exported resources2,220 checks. Original247 asset/core hashes matchv0.35. Native matching-size review and clean software-rendering comparisons are supplied separately. Android APK is unsigned; physical Windows/Android tests remain outstanding. Read CONNECTED-GRACE-036.md.

Earlier notes follow.

# v0.35 current verification

65,316 counted source checks, layout/title suites and 100 Windows embedded-pack checks pass. All 247 checked inherited assets/scenes and protected world/physics/save files match v0.34. Native matching-size before/after review and a 33-second preview are supplied separately. Desktop software-rendering measurements and remaining device limits are in SARAH-GRACE-035.md and verification/grace35. Physical Windows and Android device testing remain outstanding.

Earlier verification notes follow.

# v0.34 current verification

Read FRIENDS-CAVERN-034.md and verification/cavern34. The source passes 1,916 counted checks plus layout/title suites; the Windows embedded pack passes another 76 checks. All 15 cavern loops and 23 named friends are covered.

Earlier verification notes follow.

# v0.33 current verification

See TUTORIAL-BEAUTY-033.md and verification/tutorial33 for current native review, source tests, exported-pack checks, preservation and rendering counters. Earlier verification notes follow.

v0.32: 843 counted source checks, the title-flow suite, and 16 exported-pack checks pass. Native review covers all eleven lessons, both grottoes, dialogue and widescreen. See TUTORIAL-BEAUTY-032.md and verification/tutorial32/. Windows device launch/performance remains untested.

v0.27.1 — Family Tutorial Load Fix: fixed a GDScript parse error in the compact-phone tutorial dialogue layout that blocked the entire tutorial scene from loading. Existing `avina_tutorial_test.gd` passes 112 checks on Godot 4.5.1. Android package rebuilt with version code 2701. See verification/tutorial-load-fix.md. Physical Android device testing remains outstanding.

v0.27.0 — Family Tutorial in Motion: source and Android release prepared from the complete v0.26 source. Tutorial-only royal performance update. Rendered character and dialogue review recorded under verification/family-tutorial/. Physical Android device testing remains outstanding.

v0.26.0 — Sarah Flow & Continuity: 35 clean-package suites and five final APK resource suites pass, including 56,738 Sarah Flow checks and the existing 5,688 Sarah 2.1 checks. Import from an empty editor cache and startup pass. Signed APK original identity/certificate, version 2600 / 0.26.0 and 16 KiB ZIP alignment verified. All 143 inherited art/audio/font files are byte-identical; two connected Sarah paintings added. Matched-size stills, rapid reversals, actual chained jumps, moving bubble release and phone layouts reviewed. Desktop measurements and limits: SARAH-FLOW.md and verification/sarah-flow/. Physical Android touch/performance testing remains outstanding. Earlier reports follow.

v0.25.0 — Tutorial Overhaul: 34 final clean-package suites pass, including 15 tutorial-overhaul checks; five final APK resource suites pass. Clean import/startup, all extraction hashes and ZIP CRC pass. Signed APK identity/certificate, version 2500 / 0.25.0 and 16 KiB ZIP alignment verified. All 141 inherited art/audio/font files are byte-identical; two painted grotto backgrounds added. Non-tutorial cavern geometry, openings, solids and treasures match v0.24. Rendered review covers both grottoes, replies, parents and phone layouts; current still and movie viewers exit 0. Physical Android touch/performance testing remains outstanding. Current evidence: verification/tutorial-overhaul/ and TUTORIAL-OVERHAUL.md. Earlier reports follow.

v0.24.0 — Cute Reactions: 33 release checks and 33 clean-package checks pass; four final APK resource checks pass. Sixteen resident controllers, all 141 inherited art/audio/font files preserved, original signing identity, version 2400 / 0.24.0. Current evidence and the desktop batch-viewer shutdown limitation are documented in verification/cute-reactions/ and CUTE-REACTIONS.md. The native smoke and preview exit successfully; physical Android testing remains outstanding. Earlier release reports follow.

v0.23.0 — Character Animations: 32 current release checks pass; four final APK resource checks pass. Current evidence and historical-baseline parity: verification/character-animations/. All fourteen failures in the broader historical sweep also occur on v0.22 with matching error counts. Native GPU visual audits cover resident rooms, tutorial, Pocketful and action/family views. All 141 inherited art/audio/font files are unchanged. Physical Android testing remains outstanding. Earlier release reports follow.

v0.22.0 — The Painted Reef: all 31 clean-package suites, clean import/startup, ZIP CRC and extraction hashes pass. Four desktop checks of final APK resources pass. Signature, original certificate, version 2200 / 0.22.0 and 16 KiB ZIP alignment verified. Rendered tutorial, Highland and cavern views inspected. All 141 inherited art/audio/font files and collision data unchanged. Physical Android testing remains outstanding. Current evidence: verification/painted-reef/. Earlier reports below describe v0.21.

v0.21.0 — Little Moments of Magic: 31 native release suites pass. They include the new story/ownership/tutorial/layering checks, 5,688 Sarah 2.1 checks, 269 dialogue checks covering 33 reply branches, and 334 Whimsy 4.0 neighbourhood checks. Current logs are in verification/; this release's comparisons and measurements are in verification/little-moments/. verification/sarah-21/ is retained historical v0.20 evidence.

All 129 visual/audio/font files from the complete v0.20 archive are byte-identical. The historical 105 baseline art/audio hashes and sixteen Whimsy paintings remain recorded in ASSET_PRESERVATION.json, with twelve additional Little Moments paintings recorded separately. Five Sarah 2.1 paintings retain their separate provenance. Save location, app ID and release signing identity are preserved.

Desktop measurements are reported in LITTLE-MOMENTS.md; they are not Android device results. Physical Android performance and touch testing remain outstanding. The source package includes twelve full-resolution new PNGs, exact ImageGen prompts and their 512-pixel runtime import settings. All eleven tutorial lesson states and all 33 replies are covered in the rendered review.

All 31 clean-package suites pass, along with clean import/startup, ZIP CRC, extraction hashes, public export-preset redaction, and all twelve new runtime import limits. The final APK passes signature/certificate and 16 KiB ZIP alignment checks, plus five desktop checks of its packaged resources (startup, stories, Sarah 2.1, Whimsy 4.0 and the complete adventure). These resource checks are not physical Android testing. Final package and APK check results are recorded under verification/little-moments/. The normal package-validation tool uses a separate preferences/save directory for each suite. The retained v0.20 checks in verification/sarah-21/ describe that prior release.
