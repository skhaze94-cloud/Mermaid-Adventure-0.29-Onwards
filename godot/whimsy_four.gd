extends RefCounted
## Local company. Visits and a single welcome reward use the host's save ledger;
## chatter, props and pantomime are transient and never become combat objects.
const Data=preload("res://godot/whimsy_four_data.gd")
const REWARD:=120
const FRIEND_POINTS:=50
var host: Node2D
var profile: Dictionary={}
var visited: Array[String]=[]
var completed:=false
var clock:=0.0
var chat_left:=0.0
var chat_wait:=1.0
var chat_index:=0
var chat_actor:=-1
var chat_line:=""
var dwell:=PackedFloat32Array([0.0,0.0])
var flourish:=0.0
var flourish_wait:=0.0
var welcomes:=0
var last_retry:=-1
var quiet:=true
var sarah_reply:=false
var reply_pending:=""
func bind(level: Node2D) -> void:
    host=level;profile=Data.for_chapter(host._stage_index());last_retry=host.retry_serial
    dwell.resize(profile["people"].size())
    clear_transients()
func active() -> bool:
    if not is_instance_valid(host) or host.state!="playing" or host.get_tree().paused or host.waterfall_phase!="":return false
    if host.get("dialogue_open")==true or host.get("playing_daddy")==true:return false
    return not host.get_node("/root/SceneFlow").busy
func eligible() -> bool:return not profile.get("after_boss",false) or host.boss_hp<=0
func hushed() -> bool:
    return not active() or not eligible() or host._whimsy_combat_active() or host.message_time>0 or host.opal.charge.held or host.living_reef.reactions.focus_left>0 or host.pocket_wonders.reactions.active
func advance(dt: float) -> void:
    if not is_finite(dt) or dt<=0:return
    if host.retry_serial!=last_retry:last_retry=host.retry_serial;clear_transients()
    quiet=hushed()
    if not active():suspend();return
    if not host.reduced_fx:clock+=minf(dt,.1)
    flourish=maxf(0,flourish-dt);flourish_wait=maxf(0,flourish_wait-dt)
    if quiet:
        chat_left=0;chat_actor=-1;reply_pending="";sarah_reply=false;dwell.fill(0);return
    _roam(minf(dt,.1))
    chat_wait=maxf(0,chat_wait-dt);chat_left=maxf(0,chat_left-dt)
    if chat_left<=0:
        if not reply_pending.is_empty():
            chat_line=reply_pending;reply_pending="";sarah_reply=true;chat_left=3.6;chat_wait=maxf(chat_wait,12)
        else:chat_actor=-1;sarah_reply=false
    if chat_actor>=0 and host.player.distance_to(profile["people"][chat_actor]["talk_at"])>360:
        chat_actor=-1;chat_left=0;reply_pending="";sarah_reply=false
    var closest:=-1;var distance:=INF
    for i in range(profile["people"].size()):
        var person: Dictionary=profile["people"][i]
        var d: float=host.player.distance_to(person["talk_at"])
        if d<distance:distance=d;closest=i
        var resting: bool=d<165 and host.player_velocity.length()<145 and host.boost_time<=0 and host.leap_phase==""
        dwell[i]=dwell[i]+minf(dt,.1) if resting else 0.0
        var first_primary: bool=i<2 and not person["id"] in visited
        var first_friend: bool=not host.score_book.seen.has(friend_key(i))
        if dwell[i]>=1.5 and (first_primary or first_friend):
            if first_primary:visited.append(person["id"])
            flourish=3.8
            _speak(i,String(person["lines"][0]));chat_index=1
            if first_friend:host._award(friend_key(i),"Secrets",FRIEND_POINTS,person["talk_at"],false)
            host._save_checkpoint()
        if d<290 and host.boost_time>0 and flourish_wait<=0:
            flourish=4.0;flourish_wait=7.0
    if visited.size()==2 and not completed:
        completed=true
        host._award(profile["id"],"Secrets",REWARD,profile["room"]["reef"].get_center()-Vector2(0,180),false)
        host._bank_pocket_wonders();welcomes+=1
        flourish=4.0
    if closest>=0 and distance<245 and host.player_velocity.length()<100 and chat_wait<=0 and chat_actor<0:
        var person: Dictionary=profile["people"][closest]
        _speak(closest,person["lines"][chat_index%person["lines"].size()]);chat_index+=1
func _speak(index: int,line: String) -> void:
    if host._stage_index()==7 and host.boost_time<=0 and host.leap_phase=="" and not host.opal.charge.held and host.native_rig.can_discovery_react():
        host.native_rig.play_discovery_gesture("greet")
    sarah_reply=false
    reply_pending=String(profile["people"][index].get("reply","Hello! What a lovely place to meet a friend."))
    if host._stage_index()==7:reply_pending="A tiny stroll sounds lovely, Mallow." if index==0 else "Hello, Tilly! I will save a gentle hello for Dozy too."
    chat_actor=index;chat_line=line;chat_left=clampf(1.5+line.length()/21.0,4.5,7.0);chat_wait=16.0
func suspend() -> void:
    quiet=true;chat_actor=-1;chat_left=0;reply_pending="";sarah_reply=false;dwell.fill(0)
func clear_transients() -> void:
    reply_pending="";sarah_reply=false
    for person in profile.get("people",[]):
        if person.get("roam",false):person["foot"]=person["home"];person["talk_at"]=person["foot"]+person.get("talk_offset",Vector2(0,-110))
    clock=0;chat_left=0;chat_wait=1;chat_actor=-1;chat_line="";chat_index=0
    flourish=0;flourish_wait=0;dwell.fill(0);quiet=true
func export_state() -> Dictionary:return {"version":1,"visited":visited.duplicate(),"completed":completed}
func friend_key(index: int) -> String:return "friends-cavern:%s:%s" % [host._stage_index(),profile["people"][index]["id"]]
func valid_state(saved: Dictionary,ledger: Dictionary={}) -> bool:
    if saved.is_empty():return true
    if not saved.get("version") is int or saved["version"]!=1 or not saved.get("visited") is Array or saved["visited"].size()>2 or not saved.get("completed") is bool:return false
    var ids: Array[String]=[]
    for i in range(2):ids.append(profile["people"][i]["id"])
    var seen: Dictionary={}
    for id in saved["visited"]:
        if not id is String or not id in ids or seen.has(id):return false
        seen[id]=true
    var owned: Dictionary=ledger.get("seen",ledger)
    return bool(saved["completed"])==(saved["visited"].size()==2) and bool(saved["completed"])==owned.has(profile["id"])
func restore_state(saved: Dictionary) -> void:
    clear_transients();visited.clear();completed=false
    if saved.is_empty():return
    for id in saved.get("visited",[]):visited.append(String(id))
    completed=saved.get("completed",false)

func _roam(dt: float) -> void:
    if host.reduced_fx:return
    for i in range(profile["people"].size()):
        var person: Dictionary=profile["people"][i]
        if host.player.distance_to(person["talk_at"])<235 or chat_actor==i:continue
        var home: Vector2=person["home"]
        var target:=home+Vector2(sin(clock*.28+i*2.1)*(22 if i%2==0 else 18),0)
        person["foot"]=Vector2(person["foot"]).move_toward(target,dt*(14 if i==0 else 18))
        person["talk_at"]=person["foot"]+person.get("talk_offset",Vector2(0,-110))
