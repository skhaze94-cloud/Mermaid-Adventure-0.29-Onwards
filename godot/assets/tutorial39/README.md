# Supplied Meshy models — tutorial runtime derivatives

`PROVENANCE.json` maps all twelve user attachments to their derived GLB and tutorial role, including source hashes. The five creature attachments contain Skeleton3D skins but no animation clips. `tutorial39_actor.gd` authors restrained offsets relative to cached bone poses. The moon whale and cottages are static meshes; the whale only rocks gently. Four chest models have separate lid hinges.

The original attachments were not edited. Runtime copies have embedded painted textures capped at 1024px. The higher-detail cottage is simplified to 30k triangles. Extracted PNGs and Godot import sidecars are included for reproducible editor import.

The adapter is installed only by the tutorial. Existing logic remains the owner of interactions and rewards. Daddy, Antonella, Avina and Sarah retain their existing models/rigs. See `LIVING-TUTORIAL-039.md` for review and limitations.
