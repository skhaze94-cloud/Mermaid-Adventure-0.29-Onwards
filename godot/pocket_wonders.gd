extends RefCounted
## Optional storybook encounters. Only memories/reward ownership are saved;
## cups, rain, laundry and decorative bubbles never enter combat or physics.
const Data=preload("res://godot/pocket_wonders_data.gd")
const Sweep=preload("res://godot/opal_collision.gd")
const Reactions=preload("res://godot/pocket_wonders_reactions.gd")
const DISCOVER_DISTANCE:=430.0
const VISIT_DISTANCE:=520.0
const REPLAY_DELAY:=18.0
var level: Node2D
var records: Array[Dictionary]=[]
var reactions=Reactions.new()
var last_player:=Vector2.ZERO
var has_player:=false
var active_index:=-1
var completed_count:=0
var note_queue: Array[Dictionary]=[]
var note_wait:=0.0

func bind(host: Node2D) -> void:
    level=host;records.clear()
    for profile in Data.for_chapter(level._stage_index(),level.obstacles,level._swim_bounds(),level._boss_home()):
        records.append({"profile":profile,"state":"dormant","discovered":false,"completed":false,
            "phase":0,"timer":0.0,"elapsed":0.0,"progress":0,"glow_time":0.0,"cooldown":0.0,
            "was_near":false,"reenter":true,"gag_time":0.0,"mirror_serial":0,
            "chat_wait":9.0,"chat_left":0.0,"chat_index":0,"chat_line":""})
    reactions.bind(level)
    clear_transients()

func eligible(record: Dictionary) -> bool:
    if not is_instance_valid(level):return false
    var profile: Dictionary=record["profile"]
    if profile.get("after_boss",false) and level.boss_hp>0:return false
    if int(profile.get("after_lesson",0))>0 and int(level.get("lesson"))<int(profile["after_lesson"]):return false
    return true

func world_active() -> bool:
    if not is_instance_valid(level) or not level.is_inside_tree():return false
    if level.state!="playing" or level.get_tree().paused or level.waterfall_phase!="":return false
    var flow=level.get_node_or_null("/root/SceneFlow")
    if is_instance_valid(flow) and flow.busy:return false
    if level.get("dialogue_open")==true or level.get("playing_daddy")==true:return false
    return true

func quiet() -> bool:return not world_active() or level._whimsy_combat_active()

func suspend() -> void:
    # The host calls this on pause even though physics has stopped. Never let
    # a paused optional performance retain ownership of Sarah's expression.
    reactions.clear();has_player=false;note_queue.clear()
    if active_index>=0 and active_index<records.size() and records[active_index]["profile"]["kind"]=="mirror":
        _stop(records[active_index]);active_index=-1

func advance(dt: float) -> void:
    if not is_finite(dt) or dt<=0:return
    reactions.advance(dt)
    if not world_active():has_player=false;return
    var previous: Vector2=last_player if has_player else level.player
    if previous.distance_squared_to(level.player)>640000:previous=level.player
    last_player=level.player;has_player=true
    if quiet():
        note_queue.clear()
        if active_index>=0 and records[active_index]["profile"]["kind"]=="mirror":_stop(records[active_index]);active_index=-1
        return
    _advance_notes(dt)
    for neighbour in records:
        neighbour["chat_wait"]=maxf(0,float(neighbour["chat_wait"])-dt)
        neighbour["chat_left"]=maxf(0,float(neighbour["chat_left"])-dt)
    var nearest:=-1
    var distance:=VISIT_DISTANCE*VISIT_DISTANCE
    for index in range(records.size()):
        var record: Dictionary=records[index]
        record["cooldown"]=maxf(0,float(record["cooldown"])-dt)
        record["glow_time"]=maxf(0,float(record["glow_time"])-dt)
        if not eligible(record):continue
        var squared: float=level.player.distance_squared_to(record["profile"]["at"])
        if squared>VISIT_DISTANCE*VISIT_DISTANCE:record["reenter"]=true
        if record["completed"] and (not record["reenter"] or float(record["cooldown"])>0):continue
        if squared<distance:distance=squared;nearest=index
    if active_index>=0:
        var current: Dictionary=records[active_index]
        if not eligible(current) or level.player.distance_to(current["profile"]["at"])>VISIT_DISTANCE:
            _stop(current);active_index=-1
    if active_index<0:active_index=nearest
    if active_index<0:
        _neighbour_chat()
        return
    var record: Dictionary=records[active_index]
    var profile: Dictionary=record["profile"]
    var near: float=level.player.distance_to(profile["at"])
    if not record["discovered"]:
        if near>DISCOVER_DISTANCE:return
        record["discovered"]=true;record["state"]="invited";record["glow_time"]=1.8
        level._say(String(profile["discovery_line"]),3.5)
        if profile["kind"]!="mirror":reactions.play("delight",profile["at"])
        _note("ui",.94)
        return
    if record["state"]=="complete":
        if not record["reenter"] or float(record["cooldown"])>0:return
        record["state"]="invited";record["reenter"]=false
    match String(profile["kind"]):
        "dream":
            if record["state"]=="invited" and Sweep.circle(previous,level.player,profile["at"],148)<INF:_start(record)
            if record["state"]=="playing" and near<290:_sequence(record,dt,6.6)
        "tea":
            if near<270 and _relaxed():
                if record["state"]=="invited":_start(record)
                _sequence(record,dt,9.0)
        "village":_village(record,previous,dt,near)
        "mirror":_mirror(record,near)
        "post":
            if near<235 and _relaxed():
                if record["state"]=="invited":_start(record)
                _sequence(record,dt,9.6)

func _relaxed() -> bool:
    return level.player_velocity.length()<145 and level.boost_time<=0 and level.leap_phase=="" and level._input_vector().length()<.28

func _neighbour_chat() -> void:
    # Neighbours remain company after their little story. A single local caption
    # yields to travel, combat and existing speech; it never casts or awards.
    if not _relaxed() or level.message_time>0 or reactions.active:return
    if level.opal.charge.held or level.living_reef.reactions.focus_left>0:return
    for record in records:
        if not eligible(record) or not record["completed"]:continue
        var near: float=level.player.distance_to(record["profile"]["at"])
        if near>290 or float(record["glow_time"])>0 or float(record["chat_wait"])>0:continue
        var lines: Array=record["profile"].get("neighbour_lines",[])
        if lines.is_empty():continue
        record["chat_line"]=String(lines[int(record["chat_index"])%lines.size()])
        record["chat_index"]=int(record["chat_index"])+1
        record["chat_left"]=5.5;record["chat_wait"]=24.0
        return

func _start(record: Dictionary) -> void:
    record["state"]="playing";record["phase"]=0;record["timer"]=0.0;record["elapsed"]=0.0;record["progress"]=0
    record["reenter"]=false
    _note("bubble",.92)

func _sequence(record: Dictionary,dt: float,duration: float) -> void:
    var before:=int(record["phase"])
    record["elapsed"]=minf(duration,float(record["elapsed"])+dt)
    var beat:=duration/6.0
    record["phase"]=mini(5,int(float(record["elapsed"])/beat))
    record["timer"]=fmod(float(record["elapsed"]),beat)
    record["progress"]=mini(3,int(float(record["elapsed"])/(duration/3.0)))
    if int(record["phase"])!=before:
        _note("pearl",.86+int(record["phase"])*.075)
        if int(record["phase"]) in [1,4]:reactions.play("delight",record["profile"]["at"])
    if float(record["elapsed"])>=duration:_finish(record)

func _village(record: Dictionary,previous: Vector2,dt: float,near: float) -> void:
    var at: Vector2=record["profile"]["at"]
    if level.boost_time>0 and Sweep.circle(previous,level.player,at,315)<INF:
        if float(record["gag_time"])<=0:
            if record["state"]=="invited":_start(record)
            record["gag_time"]=4.5;record["phase"]=4;record["timer"]=0.0;_note("ui",1.25)
    if float(record["gag_time"])>0:
        record["gag_time"]=maxf(0,float(record["gag_time"])-dt)
        record["phase"]=4 if float(record["gag_time"])>1.5 else 5
        record["timer"]=4.5-float(record["gag_time"])
        return
    if near>=355:return
    if record["state"]=="invited":_start(record)
    if level.boost_time<=0:_sequence(record,dt,8.4)

func _mirror(record: Dictionary,near: float) -> void:
    if record["state"]=="invited":
        if near>255 or not _relaxed() or float(record["cooldown"])>0:return
        var before: int=reactions.snapshot().get("finished_serial",0)
        if not reactions.play("bubble_game",record["profile"]["at"]):return
        _start(record);record["mirror_serial"]=before
    if record["state"]!="playing":return
    var view: Dictionary=reactions.snapshot()
    if int(view.get("finished_serial",0))>int(record["mirror_serial"]):_finish(record)
    elif not bool(view.get("active",false)) or String(view.get("kind",""))!="bubble_game":
        _stop(record);record["cooldown"]=.8
    else:
        record["phase"]=clampi(int(view.get("phase",0)),0,5)
        record["timer"]=float(view.get("phase_time",0))
        record["elapsed"]=float(view.get("elapsed",0))
        record["progress"]=mini(3,int(record["phase"])/2)

func _finish(record: Dictionary) -> void:
    var profile: Dictionary=record["profile"]
    var first:=not bool(record["completed"])
    record["completed"]=true;record["discovered"]=true;record["state"]="complete"
    record["phase"]=5;record["timer"]=0.0;record["progress"]=3;record["glow_time"]=3.5
    record["cooldown"]=REPLAY_DELAY;record["reenter"]=false
    record["chat_wait"]=9.0;record["chat_left"]=0.0
    _note("heart",1.08);reactions.play("delight",profile["at"])
    if first:
        completed_count+=1
        level._award(String(profile["id"]),"Secrets",int(profile["reward"]),profile["at"],false)
        level._say(String(profile["completion_line"])+"  +"+str(profile["reward"]),4.0)
        level._bank_pocket_wonders()
    active_index=-1

func _stop(record: Dictionary) -> void:
    record["state"]="complete" if record["completed"] else "invited" if record["discovered"] else "dormant"
    record["phase"]=0;record["timer"]=0.0;record["elapsed"]=0.0;record["progress"]=0;record["gag_time"]=0.0
    if record["profile"]["kind"]=="mirror":reactions.clear()

func hint(record: Dictionary) -> String:
    var kind: String=record["profile"]["kind"]
    if record["state"]=="dormant":return ""
    if record["state"]=="complete":
        if float(record.get("chat_left",0))>0 and _relaxed() and level.message_time<=0 and not quiet():return String(record.get("chat_line",""))
        return "A little wonder remembered · +"+str(record["profile"]["reward"]) if float(record["glow_time"])>0 else ""
    if record["state"]=="invited":
        return {"dream":"Swim into the dream bubble and wake its tiny world.","tea":"Float beside the table · your cup is waiting.","village":"Meet the shy neighbours · Boost makes a little mischief.","mirror":"Rest beside this bubble for a little game.","post":"Pause beside our postman · there’s a letter for Sarah."}.get(kind,"")
    var phase:=clampi(int(record["phase"]),0,5)
    match kind:
        "dream":return ["A tiny dream is waking…","Look at its little world!","The sea is dreaming with you.","A pocketful of impossible things.","One more little twinkle…","A dream to carry with you."][phase]
        "tea":return ["A cup of moonlight? Do float beside us.","One very polite cup for Sarah.","A single sugar pearl, carefully served.","That cup is growing rather large…","Oh! An extremely bubbly tea party.","Thank you for taking tea with us."][phase]
        "village":return ["Someone is peeking through the curtains.","A tiny neighbour waves hello.","The anemones need their morning watering.","Such a lovely, very ordinary little village.","Whoosh! Bring in the washing!","There. Perfectly dignified again."][phase]
        "mirror":return ["Sarah has a small idea…","A bubble makes a lovely little mirror.","Your turn!","Sarah copies the funny face.","Excuse me, fish! That is our mirror.","Some giggles are better shared."][phase]
        "post":
            var letter: Array=record["profile"].get("letter",["To Sarah, from the sea."])
            return String(letter[mini(letter.size()-1,phase/2)])
    return ""

func snapshot() -> Dictionary:
    var visible: bool=is_instance_valid(level) and level.state in ["playing","paused"] and level.waterfall_phase=="" and not level.get_node("/root/SceneFlow").busy
    var hushed:=quiet()
    var views: Array[Dictionary]=[]
    for record in records:
        var view: Dictionary=record.duplicate()
        view["visible"]=visible and eligible(record);view["quiet"]=hushed
        view["focus"]=record["profile"]["at"]
        view["nearby"]=level.player.distance_to(view["focus"])<VISIT_DISTANCE
        view["active_hint"]=hint(record)
        views.append(view)
    var baby: bool=is_instance_valid(level.avina) and level.avina.visible and level.avina.follow_enabled
    return {"records":views,"quiet":hushed,"visible":visible,"mirror":reactions.snapshot(),"has_baby":baby}

func export_state() -> Dictionary:
    var memories: Array[Dictionary]=[]
    for record in records:memories.append({"id":record["profile"]["id"],"discovered":record["discovered"],"completed":record["completed"]})
    return {"version":1,"memories":memories}

func valid_state(saved: Dictionary,ledger: Dictionary={}) -> bool:
    if saved.is_empty():return true
    if not saved.get("version") is int or saved["version"]!=1 or not saved.get("memories") is Array or saved["memories"].size()>records.size():return false
    var ids: Dictionary={}
    for memory in saved["memories"]:
        if not memory is Dictionary or not memory.get("id") is String or ids.has(memory["id"]):return false
        var found:=false
        for record in records:
            if record["profile"]["id"]==memory["id"]:found=true;break
        if not found or not memory.get("discovered") is bool or not memory.get("completed") is bool:return false
        if memory["completed"] and not memory["discovered"]:return false
        ids[memory["id"]]=memory["completed"]
    if not ledger.is_empty():
        if not ledger.get("seen") is Dictionary:return false
        for record in records:
            var id: String=record["profile"]["id"]
            if bool(ids.get(id,false))!=ledger["seen"].has(id):return false
    return true

func restore_state(saved: Dictionary) -> void:
    for record in records:record["discovered"]=false;record["completed"]=false
    if not saved.is_empty() and valid_state(saved):
        for memory in saved["memories"]:
            for record in records:
                if memory["id"]==record["profile"]["id"]:
                    record["discovered"]=memory["discovered"];record["completed"]=memory["completed"]
    clear_transients()

func clear_transients() -> void:
    reactions.clear();active_index=-1;has_player=false;note_queue.clear();note_wait=0.0
    for record in records:
        _stop(record);record["glow_time"]=0.0;record["cooldown"]=8.0 if record["completed"] else 0.0
        record["chat_left"]=0.0;record["chat_wait"]=9.0;record["chat_line"]=""
        record["reenter"]=not bool(record["completed"]);record["was_near"]=false

func _note(effect: String,pitch: float) -> void:
    if note_queue.size()<3:note_queue.append({"effect":effect,"pitch":pitch,"life":1.2})

func _advance_notes(dt: float) -> void:
    note_wait=maxf(0,note_wait-dt)
    for note in note_queue:note["life"]=float(note["life"])-dt
    while not note_queue.is_empty() and float(note_queue[0]["life"])<=0:note_queue.pop_front()
    if note_queue.is_empty() or note_wait>0:return
    var note: Dictionary=note_queue[0]
    var audio=level.get_node("/root/OceanAudio")
    if not audio.playback_enabled or audio.play(String(note["effect"]),0,float(note["pitch"])):
        note_queue.pop_front();note_wait=.16
    else:note_wait=.04
