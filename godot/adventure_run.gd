extends Node
## The single route catalog owns chapter selection, continuation and ending.
const Data = preload("res://godot/chapter_data.gd")
const Store = preload("res://godot/progress_store.gd")
const SCENES := ["res://godot/highland_level.tscn","res://godot/shadow_kingdom.tscn","res://godot/miguel_lagoon.tscn","res://godot/blackwater_tunnel.tscn","res://godot/pearl_palace.tscn","res://godot/rana_ruin.tscn","res://godot/nessie_finale.tscn","res://godot/training_lagoon.tscn"]
const NAMES := Data.TITLES
var tutorial_complete := false
var avina_along := false
var active := false
var completed: Dictionary = {}
var start_index := 0
var current_index := -1
var records: Dictionary = {}
var adventure_best := 0
var resume_state: Dictionary = {}
var checkpoint_data: Dictionary = {}
var pending_restore: Dictionary = {}
var pending_index := -1
var storage_path := "user://sarah-adventure.json"
var persist_enabled := true
var save_message := ""
var last_written: Dictionary = {}

func _ready() -> void:
    persist_enabled = not OS.has_environment("SARAH_DISABLE_SAVES")
    load_progress()

func begin(index := 0) -> void:
    tutorial_complete = false
    avina_along = false
    active = true
    start_index = clampi(index,0,SCENES.size()-1)
    current_index = start_index
    completed.clear()
    checkpoint_data.clear()
    pending_restore.clear()
    pending_index = -1

func has_resume() -> bool:
    return _valid_state(resume_state) and int(resume_state["current"]) >= 0

func resume_chapter() -> int:
    return int(resume_state.get("current", -1)) if has_resume() else -1

func continue_saved() -> int:
    if not has_resume(): return -1
    var saved := resume_state.duplicate(true)
    begin(int(saved["start"]))
    current_index = int(saved["current"])
    tutorial_complete = saved["tutorial"]
    avina_along = saved["avina"]
    completed = saved["completed"].duplicate(true)
    checkpoint_data = saved["checkpoint"].duplicate(true)
    pending_restore = checkpoint_data.duplicate(true)
    pending_index = current_index
    return current_index

func take_restore(index: int) -> Dictionary:
    if pending_index != index: return {}
    var saved := pending_restore
    pending_restore = {}
    pending_index = -1
    return saved

func _can_persist() -> bool:
    var prefs := get_node_or_null("/root/AppPreferences")
    return persist_enabled and (not prefs or prefs.persist_enabled)

func export_state() -> Dictionary:
    return {"start": start_index, "current": current_index, "tutorial": tutorial_complete,
        "avina": avina_along, "completed": completed.duplicate(true),
        "checkpoint": checkpoint_data.duplicate(true), "records": records.duplicate(true),
        "adventure_best": adventure_best}

func _valid_state(saved: Dictionary) -> bool:
    for key in ["start", "current", "adventure_best"]:
        if not saved.get(key) is int: return false
    if int(saved["start"]) not in range(8) or int(saved["current"]) not in range(-1, 8): return false
    if not saved.get("tutorial") is bool or not saved.get("avina") is bool: return false
    for key in ["completed", "checkpoint", "records"]:
        if not saved.get(key) is Dictionary: return false
    if saved["completed"].size() > 8 or saved["records"].size() > 8: return false
    for key in saved["completed"]:
        if not key is int or key not in range(8) or not saved["completed"][key] is int or saved["completed"][key] < 0: return false
    for key in saved["records"]:
        if not key is int or key not in range(8) or not saved["records"][key] is Dictionary: return false
        var record: Dictionary = saved["records"][key]
        if not record.get("best") is int or record["best"] < 0: return false
        if not record.get("stars") is int or record["stars"] not in range(1, 4): return false
    return int(saved["adventure_best"]) >= 0

func load_progress() -> bool:
    var loaded := Store.read(storage_path)
    var saved: Dictionary = loaded["state"]
    if not _valid_state(saved):
        # A syntactically valid but incompatible primary must not hide a good backup.
        saved = Store._read_file(storage_path + ".bak")
        if not _valid_state(saved):
            save_message = "Your saved adventure could not be read. You can still choose a chapter." if loaded["invalid"] or not loaded["state"].is_empty() else ""
            return false
        loaded["recovered"] = true
    resume_state = saved.duplicate(true)
    records = saved["records"].duplicate(true)
    adventure_best = int(saved["adventure_best"])
    last_written = {} if loaded["recovered"] else saved.duplicate(true)
    save_message = "Your previous checkpoint was recovered." if loaded["recovered"] else ""
    return true

func _commit() -> bool:
    if not _can_persist(): return true
    var saved := export_state()
    if saved == last_written: return true
    var error := Store.write(storage_path, saved, _valid_state)
    if error != OK:
        save_message = "Your checkpoint could not be saved. Keep this adventure open."
        return false
    last_written = saved.duplicate(true)
    resume_state = saved.duplicate(true)
    save_message = ""
    return true

func store_checkpoint(index: int, point: Dictionary) -> bool:
    if not active or index != current_index: return true
    checkpoint_data = point.duplicate(true)
    return _commit()

func chapter_best(index: int) -> int:
    return int(records.get(index, {}).get("best", 0))

func chapter_stars(index: int) -> int:
    return int(records.get(index, {}).get("stars", 0))

func record_stage(index: int, result: Dictionary) -> void:
    var points := int(result.get("total", 0))
    records[index] = {"best": maxi(chapter_best(index), points),
        "stars": maxi(chapter_stars(index), int(result.get("stars", 1)))}
    if active:
        complete_stage(index, points)
        if index == 6:
            if range(7).all(func(chapter): return completed.has(chapter)):
                adventure_best = maxi(adventure_best, total())
            current_index = -1
            checkpoint_data.clear()
        elif index != 7:
            current_index = next_index(index)
            checkpoint_data.clear()
        _commit()

func advance_stage(index: int, points: int) -> void:
    complete_stage(index, points)
    current_index = next_index(index)
    checkpoint_data.clear()
    _commit()

func total_with_stage(index: int, points: int) -> int:
    if not active: return points
    return total() - int(completed.get(index, 0)) + points

func campaign_breakdown(index: int, points: int) -> Dictionary:
    var result := {}
    for chapter in [7,0,1,2,3,4,5,6]:
        if completed.has(chapter) or chapter == index:
            result[NAMES[chapter]] = points if chapter == index else int(completed[chapter])
    return result

func next_index(index: int) -> int:
    if index == 7: return 0
    return index+1 if index < 6 else -1
func next_scene(index: int) -> String:
    var next := next_index(index)
    return SCENES[next] if next >= 0 else ""
func next_name(index: int) -> String:
    var next := next_index(index)
    return NAMES[next] if next >= 0 else ""
func complete_stage(index: int, points: int) -> void:
    completed[index] = points
func total() -> int:
    var result := 0
    for points in completed.values(): result += int(points)
    return result
