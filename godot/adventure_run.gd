extends Node
signal save_finished(success: bool)
## The single route catalog owns chapter selection, continuation and ending.
const Data = preload("res://godot/chapter_data.gd")
const Store = preload("res://godot/progress_store.gd")
const WriteJob = preload("res://godot/progress_write_job.gd")
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
var last_save_ms := 0.0
var last_enqueue_ms := 0.0
var last_queued: Dictionary = {}
var queued_state: Dictionary = {}
var queued_path := ""
var save_task := -1
var save_job: RefCounted

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_process(false)
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
    return Store.valid_session(saved)

func load_progress() -> bool:
    flush_saves()
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
    last_queued = last_written.duplicate(true)
    save_message = "Your previous checkpoint was recovered." if loaded["recovered"] else ""
    return true

func _commit() -> bool:
    if not _can_persist(): return true
    var started := Time.get_ticks_usec()
    var saved := export_state()
    if saved == last_queued or (save_task<0 and saved==last_written): return true
    if not _valid_state(saved):
        save_message = "Your checkpoint could not be saved. Keep this adventure open."
        return false
    resume_state = saved.duplicate(true)
    last_queued = saved
    if save_task>=0:
        # At most one active write and one newest snapshot; never overlap writers.
        queued_state=saved;queued_path=storage_path
    else: _start_save(saved,storage_path)
    last_enqueue_ms=(Time.get_ticks_usec()-started)/1000.0
    return true

func _start_save(saved: Dictionary, path: String) -> void:
    save_job=WriteJob.new();save_job.snapshot=saved;save_job.path=path
    save_task=WorkerThreadPool.add_task(save_job.execute,false,"Sarah checkpoint")
    set_process(true)

func _process(_dt: float) -> void:
    if save_task>=0 and WorkerThreadPool.is_task_completed(save_task):
        WorkerThreadPool.wait_for_task_completion(save_task)
        _finish_save()

func _finish_save() -> void:
    var finished=save_job
    save_task=-1;save_job=null
    last_save_ms=finished.duration_ms
    var success: bool=finished.result==OK
    if success:
        last_written=finished.snapshot
        save_message=""
    else:
        save_message="Your checkpoint could not be saved. Keep this adventure open."
        if queued_state.is_empty():last_queued={}
    if not queued_state.is_empty():
        var next:=queued_state;var path:=queued_path
        queued_state={};queued_path=""
        _start_save(next,path)
    else:set_process(false)
    save_finished.emit(success)

func flush_saves() -> void:
    # Only explicit exits, reloads and developer checks join outstanding I/O.
    while save_task>=0:
        WorkerThreadPool.wait_for_task_completion(save_task)
        _finish_save()

func _exit_tree() -> void: flush_saves()

func store_checkpoint(index: int, point: Dictionary) -> bool:
    if not active or index != current_index: return true
    checkpoint_data = point
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
