extends RefCounted
## Optional, checkpoint-owned reef stories. Existing movement and attacks remain
## authoritative; this controller never moves Sarah, damages or gates a portal.
const Data=preload("res://godot/living_reef_data.gd")
const Sweep=preload("res://godot/opal_collision.gd")
const Rock=preload("res://godot/rock_collision.gd")
const Reactions=preload("res://godot/living_reef_reactions.gd")
const DISCOVERY_DISTANCE:=440.0
const GUIDE_DISTANCE:=300.0
var level: Node2D
var profile: Dictionary={}
var state:="hidden"
var progress:=0
var activated: Array[bool]=[false,false,false]
var actor:=Vector2.ZERO
var completed:=false
var glow_time:=0.0
var last_player:=Vector2.ZERO
var has_player:=false
var reactions=Reactions.new()
var empty_targets: Array[Vector2]=[]
var notes_played:=0
var completions:=0
var pending_notes: Array[int]=[]
var note_clock:=0.0
var note_lifetime:=0.0

func bind(host: Node2D) -> void:
    level=host
    profile=Data.for_chapter(level._stage_index(),level.obstacles,level._swim_bounds(),level._boss_home())
    actor=profile.get("at",level.player)
    reactions.bind(level)
    clear_transients()

func eligible() -> bool:
    if profile.is_empty() or not is_instance_valid(level):return false
    if level._stage_index()==7 and int(level.get("lesson"))<10:return false
    if level._stage_index()==6 and level.boss_hp>0:return false
    return true

func world_active() -> bool:
    return eligible() and level.state=="playing" and not level.get_tree().paused and level.waterfall_phase=="" and not level.get_node("/root/SceneFlow").busy

func quiet() -> bool:
    return not world_active() or level._whimsy_combat_active()

func advance(dt: float) -> void:
    reactions.advance(dt)
    if not is_finite(dt) or dt<=0:return
    if not world_active():has_player=false;return
    glow_time=maxf(0,glow_time-dt)
    var before: Vector2=last_player if has_player else level.player
    last_player=level.player;has_player=true
    if quiet():pending_notes.clear();return
    _advance_notes(dt)
    if completed:return
    if state=="hidden":
        if level.player.distance_to(profile["at"])>DISCOVERY_DISTANCE:return
        state="discovered";glow_time=1.3
        level._say(profile["discovery_line"],4)
        reactions.react("discovery",profile["at"])
        return
    if state=="discovered":state="active"
    # A restored/teleported position cannot sweep a whole activity in one tick.
    if before.distance_squared_to(level.player)>640000:before=level.player
    match String(profile["kind"]):
        "choir":
            if level.boost_time>0:
                for i in range(3):
                    if not activated[i] and Sweep.circle(before,level.player,profile["points"][i],78)<INF:_activate(i)
        "current":
            if progress<3 and Sweep.circle(before,level.player,profile["points"][progress],76)<INF:_activate(progress)
        "guide":_advance_guide(dt)

func _advance_guide(dt: float) -> void:
    var target: Vector2=profile["points"][progress] if progress<3 else profile["home"]
    if level.player.distance_to(actor)>GUIDE_DISTANCE:return
    # Authored guide legs are collision-clear; use the same swept/sliding rock
    # solver as Sarah nevertheless, so a map edit can never push a friend through reef.
    var speed:=clampf(level.player_velocity.length()+60,240,360)
    var wanted:=actor.move_toward(target,speed*minf(dt,.1))
    var movement:=Rock.move(actor,wanted-actor,Vector2.ZERO,level.obstacles,22,level._swim_bounds())
    actor=movement["position"]
    if actor.distance_to(target)>22 or level.player.distance_to(target)>240:return
    if progress<3:_activate(progress)
    elif level.player.distance_to(profile["home"])<150:_finish()

func bubble_targets() -> Array:
    if not world_active() or quiet() or completed or profile["kind"]!="choir" or state=="hidden":return empty_targets
    return profile["points"]

func hit_bubble(index: int, packet: Dictionary) -> bool:
    if not world_active() or quiet() or completed or profile["kind"]!="choir" or state=="hidden":return false
    if index<0 or index>=3 or activated[index] or packet.get("owner","sarah")!="sarah" or packet.get("baby",false):return false
    _activate(index)
    return true

func _activate(index: int) -> void:
    if completed or index<0 or index>=3 or activated[index]:return
    activated[index]=true;progress=activated.count(true);glow_time=.9
    if profile["kind"]=="choir":
        notes_played+=1
        if pending_notes.size()<3:pending_notes.append(index)
        note_lifetime=2.0
        _advance_notes(0)
        reactions.react("note",profile["points"][index])
    else:
        level._sfx("ui",0,1.0+progress*.08)
        reactions.react("help" if profile["kind"]=="guide" else "progress",profile["points"][index])
    if progress==3 and profile["kind"]!="guide":_finish()

func _finish() -> void:
    if completed:return
    completed=true;state="complete";progress=3;activated.fill(true);glow_time=3.0;completions+=1
    if profile["kind"]=="guide":actor=profile["home"]
    # Mark completion before callbacks; the existing ledger owns this one award.
    level._award(String(profile["id"]),"Secrets",int(profile["reward"]),profile["home"],false)
    level._say(profile["completion_line"]+"  +"+str(profile["reward"]),4)
    reactions.react("complete",profile["home"])
    level._bank_living_reef()

func hint() -> String:
    if profile.is_empty():return ""
    if completed:return "A little kindness remembered · +"+str(profile["reward"]) if glow_time>0 else ""
    if state=="hidden":return "A little reef discovery…"
    var kind: String=profile["kind"]
    if kind=="choir":
        return ("Boost or Bubble each sleepy shell" if level.bubble_unlocked else "Aim and Boost through each sleepy shell")+" · "+str(progress)+" / 3 voices"
    if kind=="current":return "Swim through the next glowing hoop · "+str(progress)+" / 3 · no timer"
    if level.player.distance_to(actor)>GUIDE_DISTANCE:return "Pip is waiting · swim back beside your little friend"
    if progress>=3:return "Nearly home! Swim beside Pip to the cosy shell"
    return "Swim beside Pip through the little flower stops · "+str(progress)+" / 3"

func snapshot() -> Dictionary:
    var enabled: bool=eligible() and level.waterfall_phase=="" and level.state in ["playing","paused"] and not level.get_node("/root/SceneFlow").busy
    var focus: Vector2=actor if profile.get("kind","")=="guide" else profile["points"][mini(progress,2)] if profile.get("kind","")=="current" else profile.get("at",level.player)
    var nearby: bool=not profile.is_empty() and level.player.distance_to(focus)<530
    return {"profile":profile,"state":state,"progress":progress,"activated":activated,"actor":actor,"glow_time":glow_time,"active_hint":hint(),"completed":completed,"visible":enabled,"quiet":quiet(),"nearby":nearby}

func export_state() -> Dictionary:
    if profile.is_empty():return {}
    return {"version":1,"id":profile["id"],"state":state,"progress":progress,"activated":activated.duplicate(),"actor":actor,"completed":completed}

func valid_state(saved: Dictionary, ledger: Dictionary={}) -> bool:
    if saved.is_empty():return true # v0.10 and earlier checkpoints.
    if profile.is_empty() or saved.get("version")!=1 or saved.get("id")!=profile["id"]:return false
    if saved.get("state","") not in ["hidden","discovered","active","complete"]:return false
    if not saved.get("progress") is int or int(saved["progress"]) not in range(4):return false
    if not saved.get("completed") is bool or not saved.get("activated") is Array or saved["activated"].size()!=3:return false
    for value in saved["activated"]:
        if not value is bool:return false
    if saved["activated"].count(true)!=int(saved["progress"]):return false
    if bool(saved["completed"])!=(saved["state"]=="complete"):return false
    if saved["completed"] and int(saved["progress"])!=3:return false
    if profile["kind"]!="guide" and (int(saved["progress"])==3)!=bool(saved["completed"]):return false
    if saved["state"]=="hidden" and int(saved["progress"])!=0:return false
    if profile["kind"]!="choir":
        for i in range(3):
            if bool(saved["activated"][i])!=(i<int(saved["progress"])):return false
    if not saved.get("actor") is Vector2 or not Vector2(saved["actor"]).is_finite():return false
    var low: Vector2=profile["at"];var high:=low
    for point in profile["points"]+[profile["home"]]:low=low.min(point);high=high.max(point)
    if not Rect2(low-Vector2(180,180),high-low+Vector2(360,360)).has_point(saved["actor"]):return false
    if not ledger.is_empty() and bool(ledger.get("seen",{}).has(profile["id"]))!=bool(saved["completed"]):return false
    return true

func restore_state(saved: Dictionary) -> void:
    state="hidden";progress=0;activated.fill(false);completed=false;actor=profile.get("at",level.player)
    if not saved.is_empty() and valid_state(saved):
        state=saved["state"];progress=saved["progress"];completed=saved["completed"]
        for i in range(3):activated[i]=saved["activated"][i]
        actor=Rock.recover(saved["actor"],level.obstacles,22,level._swim_bounds())
    clear_transients()

func clear_transients() -> void:
    has_player=false;glow_time=0.0;reactions.clear()
    pending_notes.clear();note_clock=0.0;note_lifetime=0.0

func _advance_notes(dt: float) -> void:
    note_clock=maxf(0,note_clock-dt);note_lifetime=maxf(0,note_lifetime-dt)
    if pending_notes.is_empty():return
    if note_lifetime<=0 or level.player.distance_to(profile["at"])>700:pending_notes.clear();return
    if note_clock>0:return
    var audio=level.get_node("/root/OceanAudio")
    if not audio.playback_enabled or audio.play("pearl",1,[.86,1.08,1.32][pending_notes[0]]):
        pending_notes.pop_front();note_clock=.14
    else:note_clock=.04 # Respect the shared voice/throttle budget; never add players.

func current_drift(input_dir: Vector2) -> Vector2:
    if profile.get("kind","")!="current" or state!="active" or completed or progress>=3:return Vector2.ZERO
    if not world_active() or quiet() or level.boost_time>0 or level.leap_phase!="" or input_dir.length_squared()<.02:return Vector2.ZERO
    var target: Vector2=profile["points"][progress]
    var from: Vector2=profile["at"] if progress==0 else profile["points"][progress-1]
    var direction: Vector2=(target-from).normalized()
    if input_dir.dot(direction)<=.2:return Vector2.ZERO
    var nearest:=Geometry2D.get_closest_point_to_segment(level.player,from,target)
    if nearest.distance_to(level.player)>120:return Vector2.ZERO
    return direction*55.0 # A gentle ride only while the player chooses to swim along it.
