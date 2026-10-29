extends RefCounted
## Worker-owned data only: no scene nodes, textures or live game containers.
const Store = preload("res://godot/progress_store.gd")
var path := ""
var snapshot: Dictionary = {}
var result: Error = ERR_BUSY
var duration_ms := 0.0
func execute() -> void:
    var started := Time.get_ticks_usec()
    result = Store.write(path, snapshot, Store.valid_session)
    duration_ms = (Time.get_ticks_usec()-started)/1000.0
