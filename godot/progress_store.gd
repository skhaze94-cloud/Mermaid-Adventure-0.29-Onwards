extends RefCounted
## Checked, atomic save files. Native JSON retains Vector2 and integer ledger keys.
const VERSION := 1
const MAX_BYTES := 4 * 1024 * 1024

static func valid_session(saved: Dictionary) -> bool:
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

static func _same_value(a, b) -> bool:
    if typeof(a) != typeof(b): return false
    if a is float:
        # Godot's JSON number parser can differ by one double-precision ULP.
        return is_finite(a) and is_finite(b) and absf(a-b) <= maxf(1.0,absf(a))*1e-12
    if a is Dictionary:
        if a.size()!=b.size(): return false
        for key in a:
            if not b.has(key) or not _same_value(a[key],b[key]): return false
        return true
    if a is Array:
        if a.size()!=b.size(): return false
        for i in range(a.size()):
            if not _same_value(a[i],b[i]): return false
        return true
    return a == b

static func _read_file(path: String) -> Dictionary:
    if not FileAccess.file_exists(path): return {}
    var file := FileAccess.open(path, FileAccess.READ)
    if not file or file.get_length() > MAX_BYTES: return {}
    var document := JSON.new()
    if document.parse(file.get_as_text()) != OK: return {}
    file.close()
    if not document.data is Dictionary: return {}
    var envelope: Dictionary = document.data
    if envelope.get("version", 0) != VERSION or not envelope.get("payload") is String: return {}
    var payload: String = envelope["payload"]
    if payload.sha256_text() != envelope.get("sha256", ""): return {}
    var native := JSON.new()
    if native.parse(payload) != OK: return {}
    var state = JSON.to_native(native.data, false)
    return state if state is Dictionary else {}

static func read(path: String) -> Dictionary:
    var state := _read_file(path)
    if not state.is_empty(): return {"state": state, "recovered": false, "invalid": false}
    state = _read_file(path + ".bak")
    return {"state": state, "recovered": not state.is_empty(),
        "invalid": state.is_empty() and (FileAccess.file_exists(path) or FileAccess.file_exists(path + ".bak"))}

static func write(path: String, state: Dictionary, validate: Callable = Callable()) -> Error:
    if validate.is_valid() and not validate.call(state): return ERR_INVALID_DATA
    var payload := JSON.stringify(JSON.from_native(state, false), "", true, true)
    var text := JSON.stringify({"version": VERSION, "payload": payload, "sha256": payload.sha256_text()})
    if text.to_utf8_buffer().size() > MAX_BYTES: return ERR_OUT_OF_MEMORY
    var temporary := path + ".tmp"
    var file := FileAccess.open(temporary, FileAccess.WRITE)
    if not file: return FileAccess.get_open_error()
    file.store_string(text)
    file.flush()
    var error := file.get_error()
    file.close()
    if error != OK: return error
    if not _same_value(_read_file(temporary),state): return ERR_FILE_CORRUPT
    # Never replace a good recovery file with a damaged primary save.
    var previous := _read_file(path)
    if not previous.is_empty() and (not validate.is_valid() or validate.call(previous)):
        error = DirAccess.copy_absolute(path, path + ".bak")
        if error != OK: return error
    return DirAccess.rename_absolute(temporary, path)
