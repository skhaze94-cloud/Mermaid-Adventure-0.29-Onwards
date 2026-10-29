extends "res://godot/tools/opal_stress_audit.gd"
## Isolate one unchanged dense workload to investigate a noisy paired result.
func stress_case(name: String, path: String) -> void:
    var selected := OS.get_environment("ADVENTURE_AUDIT_CASE")
    if selected.is_empty() or selected == name:
        await super.stress_case(name,path)
