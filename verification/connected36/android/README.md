# Android v0.36 — unsigned ARM64 build

The Android package was exported with official Godot4.5.1, using a separate cold-import cache. The Windows/source4.4 tests remain separate. The preserved source uses compatible APIs; the royal reference-position mapping handles the exact vertex reordering introduced by4.5.1 imports without changing the canonical paintings or GLBs.

Application ID: com.samkhaze.mermaidadventure. Version0.36.0 /3600. ARM64 only. TargetSDK35. ZIP alignment at16KiB and PT_LOAD alignment at16KiB for both native libraries are verified. A4.4.1 native-template probe had only4KiB ELF alignment; it was not used for the final APK.

The file is UNSIGNED. The recorded original Mermaid certificate is SHA256 f55e6daa265976ca65badf6ca6e9a6d653eaaa33ffc3d5d581d281062e3064b9, but its private signing key is not supplied in the complete source or this workspace. No replacement identity was generated. Sign with the original identity before installation or updating an existing installation. Do not treat this unsigned file as an installable signed release.

The final APK archive passes CRC, app ID/version/ARM64, native alignment and exact byte checks for world/cast and all six royal binding/reference blobs. Its actual exported resources pass105 chapter/world/animation checks and2115 additional bone/weight/remapping/articulation checks with the matching Linux engine (2220 total). Physical-device launch, touch, FPS, memory and thermals are untested.

## Reproduce

Install official Godot4.5.1 and its matching Android export templates. Configure a supported Android SDK and Java17 in the editor. Open the source project using an isolated import cache; let the editor import resources. The Android Unsigned preset retains the established application ID/version and includes JSON, skin36 and pos36 binding data. Export a release APK with that preset. The public source export clears machine-specific custom-template and keystore paths. Configure the original signing identity when it becomes available; do not substitute another certificate for an existing installation.

The APK is a build derivative of the same runtime source. No platform-specific replacement character artwork or per-platform weight files were required. Canonical reference positions are runtime assets, permitting exact remapping and cache reuse after import.
