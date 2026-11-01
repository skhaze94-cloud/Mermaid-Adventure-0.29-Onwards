# Rebuilding the royal skins

The original GLBs are unchanged. Bindings depend on Godot imported vertex order, which differs from the raw GLB buffer order. Do not bind raw GLB vertices by index.

1. Import this project using its tested Godot version.
2. Create `../audit36/royals` relative to the Godot project folder.
3. Run `godot --headless --path . --script godot/tools/royal36/mesh_probe.gd`. The included probe writes king/queen imported positions there.
4. Run `python godot/tools/royal36/generate_bindings36.py` with NumPy installed. This rewrites the two .skin36 files and .bind.json metadata under godot/assets/royal-connected36.
5. Re-run the royal articulation tests and native pose review before packaging.

The generator authors broad body transitions, separate limb capsules, restrained cloth/hair regions, rigid staff binding and explicit rigid distal palm/finger zones with soft wrist transitions. Pivots are authored from textured anatomical maps rather than an automatically assumed T-pose.


Cross-version import order: `.pos36` stores the exact audited reference positions as 3*N little-endian float32 values (12*N bytes); SHA-256 is the `source_vertices_sha256` in the adjacent bind JSON. The normal importer fast path verifies that hash and uses stored weights directly. If another Godot importer changes only vertex ordering, `royal_connected_skin.gd` reconstructs the mapping once by exact Vector3 equality. Duplicate positions must have identical joints/weights. Missing vertices, altered geometry, conflicting duplicates or an invalid reference hash are rejected. This is not a nearest-neighbour approximation. The cached derivative then uses normal GPU skinning. Original GLBs, UVs and materials stay intact.

Godot 4.4/4.4.1 RenderingServer.mesh_get_surface reports self-referential arrays for imported LOD entries, so the runtime derivative does not retain those automatic LODs. Its full topology remains unchanged, and the reviewed fixed orthographic tutorial cameras rendered the same baseline 299,824 3D triangles. Profiling materially different camera distances still requires checking this limitation.
