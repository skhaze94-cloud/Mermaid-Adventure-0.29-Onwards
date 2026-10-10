extends "res://godot/highland_level.gd"
## Layout-first native chapters. Shared Sarah, controls, scoring and collision.
const Terrain = preload("res://godot/terrain_painter.gd")
const Chapter = preload("res://godot/chapter_data.gd")
const PAINTINGS := {
    "palace":preload("res://dist/assets/pearl-palace.webp"),
    "rana":preload("res://dist/assets/colombia.webp"),
    "nessie":preload("res://dist/assets/colombia.webp"),
    "blackwater":preload("res://godot/assets/waterfall-cavern-v07.webp"),
    "training":preload("res://dist/assets/training-lagoon.webp")}
const BOSS_ART := {
    "palace":preload("res://godot/assets/characters-v027/queen-antonella.png"),
    "rana":preload("res://dist/assets/rana-rex.webp"),
    "nessie":preload("res://dist/assets/nessie.webp"),
    "blackwater":preload("res://godot/assets/enemy-shark-v09.webp"),
    "training":preload("res://godot/assets/characters-v027/king-daddy.png")}
@export_enum("palace","rana","nessie","blackwater","training") var chapter_id := "palace"
var performance: Node2D
var chapter_boss_art: Texture2D
var attack_clock := 0.0
var laser_y := 560.0
var pulse_radius := 0.0
var shot_sequence := 0

func _ready() -> void:
    fallen = true
    bubble_unlocked = chapter_id != "training"
    boss_hp = _boss_max_health()
    boss_position = Vector2(_boss_home(),570)
    if chapter_id == "nessie":
        player = Vector2(2920,600)
        checkpoint = 2820
    var texture: Texture2D = BOSS_ART[chapter_id]
    if chapter_id == "blackwater":
        chapter_boss_art = preload("res://godot/creature_art.gd").atlas("shark",0)
    else: chapter_boss_art = texture
    performance = preload("res://godot/boss_performance.gd").new()
    add_child(performance)
    var character_bounds := Vector2(390,230) if chapter_id in ["nessie","blackwater"] else Vector2(360,360)
    if chapter_id=="palace": character_bounds=Vector2(230,300)
    performance.configure(chapter_boss_art,character_bounds,chapter_id)
    super._ready()
    _say(_intro_line(),6)

func _intro_line() -> String:
    return {"palace":"Queen Antonella’s royal test — dodge pearls, boost when her ring turns green.","rana":"Rana Rex awaits — watch the laser warning, then boost in the green opening.","nessie":"Nessie stole the crown! Dodge the rush and pearls, then boost to return it.","blackwater":"Stay in Sarah’s light. Baron Bite waits at the end of the tunnel.","training":"Collect three relic chests, practise Jump and Boost, then spar with King Daddy."}[chapter_id]
func _level_length() -> float: return Chapter.length_for(chapter_id)
func _boss_home() -> float: return Chapter.boss_x(chapter_id)
func _portal_x() -> float: return _level_length()-170
func _boss_max_health() -> int: return Chapter.boss_health(chapter_id)
func _left_bound() -> float: return 2730.0 if chapter_id=="nessie" else 50.0
func _has_waterfall() -> bool: return false
func _water_line() -> float: return Chapter.waterline(chapter_id)
func _stage_obstacles() -> Array[Rect2]: return Chapter.obstacles_for(chapter_id)
func _stage_enemies() -> Array[Dictionary]: return Chapter.enemies_for(chapter_id)
func _stage_treasure() -> Array[Dictionary]: return Chapter.treasure_for(chapter_id)
func _stage_index() -> int: return Chapter.IDS.find(chapter_id)
func _chapter_name() -> String: return Chapter.TITLES[_stage_index()].to_upper()
func _boss_name() -> String: return String(Chapter.source(chapter_id).get("boss",{}).get("name","Boss"))
func _hud_snapshot() -> Dictionary:
    var result := super._hud_snapshot()
    result["journey_final"] = chapter_id=="nessie"
    return result
func _sync_native_visuals() -> void:
    super._sync_native_visuals()
    if is_instance_valid(performance):
        performance.set_state(boss_hp,boss_phase,boss_position-Vector2(camera,0),time,reduced_fx)
    for node in [world_depth,foreground_depth,relief_obstacles,water_surface,waterfall_world,environment_landmarks,native_boss]:
        if is_instance_valid(node): node.hide()
func _update_swimming(dt: float) -> void:
    super._update_swimming(dt)
    if state=="victory":
        _say("The crown is safe! Adventure complete." if chapter_id=="nessie" else _chapter_name()+" complete!",1000)
        return
    if boss_hp > 0 and player.x > _boss_home()+350:
        player.x = _boss_home()+350
        player_velocity.x = minf(0,player_velocity.x)
    if chapter_id=="blackwater" and leap_phase=="":
        player.y = maxf(player.y,_water_line()+45)
func _check_checkpoints() -> void:
    if state!="playing" or chapter_id=="nessie": return
    var factor := _level_length()/7600.0
    var stops: Array[float] = [1460*factor,2820*factor,4320*factor,5920*factor]
    if chapter_id=="blackwater": stops = [4660.0,7640.0]
    for stop in stops:
        if player.x > stop+70 and checkpoint < stop:
            checkpoint = stop
            health = MAX_HEALTH
            _save_checkpoint()
            _say("Checkpoint — "+_chapter_name(),2.5)
func _respawn() -> void:
    super._respawn()
    fallen = true
    player = RockCollision.recover(player,obstacles,HERO_RADIUS*.73,_swim_bounds())
func _restart() -> void:
    if state=="victory" and _advance_journey(): return
    super._restart()
    fallen = true
    bubble_unlocked = chapter_id != "training"
    if chapter_id=="nessie":
        player = Vector2(2920,600)
        checkpoint = 2820
    _save_checkpoint()
    _say(_intro_line(),5)
func _reset_transients() -> void:
    super._reset_transients()
    attack_clock = 0
    shot_sequence = 0
    pulse_radius = 0
    laser_y = 560
func _boss_vulnerable() -> bool:
    return boss_hp > 0 and fmod(boss_clock,7.0)>=4.0
func _update_boss(dt: float) -> void:
    if boss_hp<=0 or player.x < _boss_home()-850: return
    var serial := retry_serial
    boss_clock += dt
    attack_clock += dt
    var cycle := fmod(boss_clock,7.0)
    boss_phase = "recover" if cycle>=4 else ("windup" if cycle<1.3 else "attack")
    boss_position = Vector2(_boss_home(),570+sin(boss_clock*.8)*70)
    if cycle<1.3:
        laser_y = player.y
    elif cycle<4:
        if chapter_id in ["nessie","blackwater"]:
            boss_position.x -= sin((cycle-1.3)/2.7*PI)*430
        if attack_clock>.8:
            attack_clock = 0
            shot_sequence += 1
            var aim := (player-boss_position).normalized()
            for angle in ([-.35,0,.35] if chapter_id!="training" else [0]):
                _spawn_hostile(boss_position,aim.rotated(float(angle)),270)
        if chapter_id=="rana" and cycle>=2.8 and cycle<3.3 and absf(player.y-laser_y)<23 and player.x>_boss_home()-800 and boost_time<=0:
            _damage(boss_position)
        if chapter_id=="nessie": pulse_radius = (cycle-1.3)*190
    else:
        pulse_radius = 0
    if serial != retry_serial: return
    if player.distance_to(boss_position)<170:
        if boost_time>0 and _boss_vulnerable() and boss_hit_cooldown<=0:
            boss_hp -= 1
            boss_hit_cooldown = 1.1
            invulnerable = 1
            hostile_shots.clear()
            _award("boss:%s:%s" % [chapter_id,boss_hp],"Boss",300,boss_position,false)
            if boss_hp<=0:
                bubble_unlocked = true
                _award("boss:clear:%s" % chapter_id,"Boss",1000,boss_position,false)
                _say("Boss defeated — the portal is open!",6)
        elif not _boss_vulnerable() and boost_time<=0: _damage(boss_position)

func _draw_world(view: Vector2) -> void:
    var background: Texture2D = PAINTINGS[chapter_id]
    var progress := clampf(camera/maxf(1,_level_length()-view.x),0,1)
    if chapter_id=="blackwater":
        var cover := maxf(view.x/background.get_width(),view.y/background.get_height())*1.12
        var size := background.get_size()*cover
        draw_texture_rect(background,Rect2(Vector2(-(size.x-view.x)*progress,(view.y-size.y)*.5),size),false)
    else:
        var source_line := 285.0 if chapter_id in ["palace","training"] else 350.0
        Terrain.panorama(self,background,view,_water_line(),source_line,progress)
    draw_rect(Rect2(0,_water_line(),view.x,view.y-_water_line()),Color(.04,.09,.2,.16))
    draw_line(Vector2(0,_water_line()),Vector2(view.x,_water_line()),Color(.65,.94,1,.6),2)
    texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
    Terrain.seabed(self,view,camera,chapter_id)
    for i in range(obstacles.size()):
        var block := obstacles[i]
        var rect := Rect2(block.position-Vector2(camera,0),block.size)
        if rect.end.x<0 or rect.position.x>view.x: continue
        Terrain.rock(self,rect,i,chapter_id)
    # Reused painted flora adds depth even in the open Nessie arena.
    for i in range(int(ceil(_level_length()/390.0))):
        var x := 180+i*390-camera
        if x < -200 or x > view.x+200: continue
        Terrain.garden(self,Vector2(x,Terrain.ground_y(x+camera)),i+_stage_index(),chapter_id,115+(i%3)*20)
    for treasure in treasures:
        if treasure.taken: continue
        var pos := Vector2(treasure.x-camera,treasure.y)
        if pos.x > -100 and pos.x<view.x+100: _draw_collectible(pos,treasure.kind)
    for enemy in enemies:
        if enemy.hp<=0: continue
        var pos := Vector2(enemy.x-camera,enemy.y)
        if pos.x > -200 and pos.x<view.x+200: _draw_enemy_cue(enemy,pos)
    for shot in hostile_shots:
        draw_circle(shot["pos"]-Vector2(camera,0),10,Color("#e6aaff"))
    for shot in bubble_shots:
        draw_arc(shot["pos"]-Vector2(camera,0),12 if shot.get("baby",false) else 18,0,TAU,24,Color("#efd0ff") if shot.get("baby",false) else Color("#caffff"),3)
    _paint_chapter_boss()
    if chapter_id=="palace": _paint_palace_gates(view)
    if chapter_id=="blackwater":
        # Modest darkness keeps the basic route readable while marking the tunnel.
        draw_rect(Rect2(Vector2.ZERO,view),Color(.005,.015,.04,.25))
        draw_arc(player-Vector2(camera,0),220,0,TAU,64,Color(.48,.92,1,.22),6)
    var portal := Vector2(_portal_x()-camera,530)
    if portal.x > -100 and portal.x<view.x+150:
        Terrain.portal(self,portal,_portal_is_open())
        _draw_text(portal+Vector2(-70,160),_portal_hint(),19)
func _paint_palace_gates(view: Vector2) -> void:
    for gate in Chapter.source("palace").get("palace",{}).get("gates",[]):
        var x := float(gate.x)-camera
        if x < -120 or x>view.x+120: continue
        Terrain.contact(self,Vector2(x,Terrain.GROUND_Y),35,.35)
        Terrain.contact(self,Vector2(x+float(gate.w),Terrain.GROUND_Y),35,.35)
        # Decorative open columns. Static source rocks own collision, so no hidden gate traps.
        draw_line(Vector2(x,360),Vector2(x,Terrain.GROUND_Y),Color(.9,.82,1,.4),10)
        draw_line(Vector2(x+float(gate.w),360),Vector2(x+float(gate.w),Terrain.GROUND_Y),Color(.9,.82,1,.4),10)
func _paint_chapter_boss() -> void:
    if boss_hp<=0 or chapter_boss_art==null: return
    var pos := boss_position-Vector2(camera,0)
    if pos.x < -500 or pos.x>get_viewport_rect().size.x+500: return
    # Shared mesh actor supplies connected fins, breathing and hit/defeat reactions.
    draw_arc(pos,190,0,TAU,48,Color(.5,1,.7) if _boss_vulnerable() else Color(1,.7,.5),4)
    _draw_text(pos+Vector2(-110,-210),"BOOST NOW!" if _boss_vulnerable() else "DODGE & WAIT",19)
    if chapter_id=="rana" and boss_phase!="recover":
        draw_line(Vector2(pos.x-850,laser_y),Vector2(pos.x,laser_y),Color(1,.3,.55,.65),5 if boss_phase=="attack" else 2)
    if chapter_id=="nessie":
        draw_texture_rect(preload("res://godot/assets/ui-v014/crown.png"),Rect2(pos+Vector2(84,-166),Vector2(80,60)),false)
        if pulse_radius>0: draw_arc(pos,pulse_radius,0,TAU,48,Color(.75,.5,1,.45),4)

func _portal_is_open() -> bool: return boss_hp<=0
func _portal_hint() -> String: return "CONTINUE" if _portal_is_open() else "DEFEAT BOSS"
