extends "res://godot/highland_level.gd"
## Playable HTML 9.2 chapters on the existing native Sarah/control/checkpoint foundation.
const Journey := preload("res://godot/journey_data.gd")
const LagoonArt := preload("res://godot/lagoon_art.gd")
const CreatureArt := preload("res://godot/creature_art.gd")
const SHADOW_BACKGROUND := preload("res://dist/assets/shadow-kingdom-v751.webp")
const LAGOON_BACKGROUND := preload("res://dist/assets/colombia.webp")
const MIGUEL := preload("res://dist/assets/miguel.webp")
@export var shadow := false
var performance: Node2D
var flip_performance: Node2D
var switches: Array[Dictionary] = []
var duke_hp := 10
var flip_hp := 8
var flip_position := Vector2(13682,440)
var flip_stun := 0.0
var crab_stun := 0.0
var boss_shot_clock := 0.0
var combo_clock := 0.0
var terrain_keys: Array[String] = []
var flora_keys: Array[String] = []

func _ready() -> void:
    fallen = true
    bubble_unlocked = true
    boss_hp = _boss_max_health()
    boss_position = Vector2(_boss_home(),690 if shadow else 540)
    switches.clear()
    if shadow: switches.assign(Journey.switches())
    LagoonArt.load_pack()
    terrain_keys = LagoonArt.keys("lagoon-terrain-atlas")
    flora_keys = LagoonArt.keys("lagoon-flora-atlas")
    performance = preload("res://godot/boss_performance.gd").new()
    add_child(performance)
    performance.configure(CreatureArt.atlas("carlo",0) if shadow else MIGUEL,Vector2(380,310) if shadow else Vector2(440,290),"duke" if shadow else "miguel")
    if shadow:
        performance.modulate = Color(.82,.72,1)
        flip_performance = preload("res://godot/boss_performance.gd").new()
        add_child(flip_performance)
        var flip_art := AtlasTexture.new()
        flip_art.atlas = FLIP_ART
        flip_art.region = Rect2(34,99,1487,811)
        flip_performance.configure(flip_art,Vector2(280,153),"flip")
    super._ready()
    _say("Shadow Crab Kingdom — bubbles open shell switches!" if shadow else "Miguel’s Lagoon — follow the pearls through the jungle reef!",5)

func _level_length() -> float: return Journey.SHADOW_LENGTH if shadow else Journey.LAGOON_LENGTH
func _boss_home() -> float: return 13455.0 if shadow else Journey.sx(7000)
func _portal_x() -> float: return _level_length()-170
func _boss_max_health() -> int: return 18 if shadow else 4
func _left_bound() -> float: return 50.0
func _has_waterfall() -> bool: return false
func _water_line() -> float: return 250.0 if shadow else 310.0
func _stage_obstacles() -> Array[Rect2]: return Journey.obstacles(shadow)
func _stage_enemies() -> Array[Dictionary]: return Journey.enemies(shadow)
func _stage_treasure() -> Array[Dictionary]: return Journey.treasure(shadow)
func _chapter_name() -> String: return "SHADOW CRAB KINGDOM · INTERLUDE" if shadow else "MIGUEL’S LAGOON · STAGE 2"
func _boss_name() -> String: return "DUKE CLAW & FLIP" if shadow else "MIGUEL THE MANTA"
func _stage_index() -> int: return 1 if shadow else 2
func _hud_snapshot() -> Dictionary:
    var result := super._hud_snapshot()
    result["journey_final"] = false
    result["boss_active"] = player.x > (12870.0 if shadow else Journey.sx(6420)) and boss_hp > 0
    return result
func _sync_native_visuals() -> void:
    super._sync_native_visuals()
    if is_instance_valid(performance):
        performance.set_state(duke_hp if shadow else boss_hp,boss_phase,boss_position-Vector2(camera,0),time,reduced_fx)
        if shadow:
            flip_performance.set_state(flip_hp,"recover" if flip_stun>0 else "attack",flip_position-Vector2(camera,0),time,reduced_fx)
    # Keep Sarah, native HUD, input and jump choreography; these chapters own their scenery.
    for node in [world_depth,foreground_depth,relief_obstacles,water_surface,waterfall_world,environment_landmarks,native_boss]:
        if is_instance_valid(node): node.hide()
func _update_swimming(dt: float) -> void:
    super._update_swimming(dt)
    if state == "victory":
        _say("Shadow Crab Kingdom clear! Onward to Miguel’s Lagoon." if shadow else "Miguel’s Lagoon clear — chapter complete!",1000)
        return
    if not shadow and leap_phase == "" and boost_time <= 0:
        var before := player
        player.x += sin(time*.9+player.x*.001)*30*dt
        var current_collision := _move_around_rocks(before, player)
        player = current_collision["position"]
        player_velocity = current_collision["velocity"]
    # Pads give a readable, optional launch route to the above-water rewards.
    for x in Journey.pads(shadow):
        if absf(player.x-x)<100 and player.y < 430 and leap_phase == "ascent":
            player_velocity.y = -850
            energy = minf(1,energy+dt*.5)

func _check_checkpoints() -> void:
    if state != "playing": return
    var stops: Array = [[2860,"Outer Kingdom"],[7098,"Royal Market"],[11440,"Royal Approach"],[12600,"Duke & Flip’s Court"]] if shadow else [[Journey.sx(1550),"Orchid Shallows"],[Journey.sx(3550),"Jungle Reef"],[Journey.sx(5150),"Ribbon Gardens"],[Journey.sx(6420),"Miguel’s Arena"]]
    for stop in stops:
        if player.x > float(stop[0])+60 and checkpoint < float(stop[0]):
            checkpoint = stop[0]
            health = MAX_HEALTH
            _release_all_loot()
            _save_checkpoint()
            _say("Checkpoint — "+stop[1],3)
func _save_checkpoint() -> void:
    super._save_checkpoint()
    checkpoint_snapshot["switches"] = switches.duplicate(true)
    checkpoint_snapshot["duke"] = duke_hp
    checkpoint_snapshot["flip"] = flip_hp
func _respawn() -> void:
    super._respawn()
    fallen = true
    switches.assign(checkpoint_snapshot.get("switches",[]).duplicate(true))
    duke_hp = checkpoint_snapshot.get("duke",10)
    flip_hp = checkpoint_snapshot.get("flip",8)
    _release_all_loot()
func _reset_transients() -> void:
    super._reset_transients()
    boss_position = Vector2(_boss_home(),690 if shadow else 540)
    flip_position = Vector2(13682,440)
    flip_stun = 0
    crab_stun = 0
    boss_shot_clock = 0
    combo_clock = 0
func _restart() -> void:
    if state == "victory" and _advance_journey(): return
    duke_hp = 10
    flip_hp = 8
    switches.clear()
    if shadow: switches.assign(Journey.switches())
    super._restart()
    bubble_unlocked = true
    _save_checkpoint()
    _say("Shadow Crab Kingdom — the kingdom below!" if shadow else "Miguel’s Lagoon — the enchanted jungle reef!",4)

func _update_enemies(dt: float) -> void:
    var serial := retry_serial
    for enemy in enemies:
        if int(enemy["hp"]) <= 0 or absf(float(enemy["x"])-player.x)>1500: continue
        enemy["hit_cd"] = maxf(0,float(enemy.get("hit_cd",0))-dt)
        var kind := String(enemy["kind"])
        var variant := String(enemy.get("variant",""))
        var combat_kind := kind
        if kind in Journey.PACK_KINDS:
            combat_kind = {"maraca-snapper":"puffer","ribbon-ambusher":"eel","bubble-bandit-otter":"crab","orchid-hermit":"puffer","drumback-turtle":"jelly","disco-cuttlefish":"jelly"}[kind]
        elif shadow and variant in ["spear","bubble","shadow","guard","hermit"]: combat_kind = "puffer"
        enemy["kind"] = combat_kind
        var event := Combat.step(enemy,player,time,dt,obstacles)
        enemy["kind"] = kind
        var pos := Vector2(enemy["x"],enemy["y"])
        if event == "fire":
            var aim: Vector2 = enemy["aim"]
            if kind == "maraca-snapper" or variant in ["bubble","shadow"]:
                # The sound fan leaves a clear dodge lane above/below its three notes.
                for angle in [-.3,0,.3]: _spawn_hostile(pos,aim.rotated(angle),230)
            elif kind == "drumback-turtle":
                _say("Drum current — swim across the lane!",1.2)
            else: _spawn_hostile(pos,aim,210 if kind == "orchid-hermit" else 270)
        if kind == "drumback-turtle" and enemy.get("mode","") == "attack" and absf(player.y-pos.y)<75 and absf(player.x-pos.x)<430:
            var previous := player
            player.x += float(enemy.get("dir",-1))*110*dt
            for block in obstacles:
                if block.grow(32).has_point(player): player = previous
        if kind == "bubble-bandit-otter":
            if enemy.get("mode","") == "windup" and not enemy.has("loot"):
                enemy["loot"] = []
                for i in range(treasures.size()):
                    var item: Dictionary = treasures[i]
                    if not item["taken"] and item["kind"] == "pearl" and pos.distance_to(Vector2(item["x"],item["y"]))<330 and enemy["loot"].size()<3:
                        enemy["loot"].append(i)
                        item["taken"] = true
            if enemy.get("mode","") == "recover": _release_loot(enemy)
        if pos.distance_to(player)<72 and leap_phase != "airborne":
            if boost_time>0: _hit_enemy(enemy,2,true)
            elif enemy.get("mode","") != "recover": _damage(pos)
        if serial != retry_serial: return
func _guarded(enemy: Dictionary) -> bool:
    return (enemy["kind"] == "orchid-hermit" or enemy.get("variant","") in ["guard","armoured"]) and enemy.get("mode","") != "recover" and signf(player.x-float(enemy["x"])) == float(enemy.get("dir",-1))
func _hit_enemy(enemy: Dictionary, damage: int, boosted: bool) -> void:
    if float(enemy.get("hit_cd",0))>0: return
    if _guarded(enemy):
        enemy["mode"] = "recover"
        enemy["mode_time"] = 0.0
        enemy["hit_cd"] = .25
        _say("Shell guard! Strike again while it recovers.",1.8)
        return
    _ocean_event("impact",Vector2(enemy["x"],enemy["y"]))
    enemy["hp"] = max(0,int(enemy["hp"])-damage)
    enemy["hit_cd"] = .6
    enemy["mode"] = "recover"
    enemy["mode_time"] = 0.0
    if boosted: invulnerable = maxf(invulnerable,.5)
    if int(enemy["hp"]) <= 0:
        _release_loot(enemy)
        _award("enemy:%s" % enemies.find(enemy),"Enemies",75,Vector2(enemy["x"],enemy["y"]),true)
func _release_loot(enemy: Dictionary) -> void:
    for i in enemy.get("loot",[]): treasures[int(i)]["taken"] = false
    enemy.erase("loot")
func _release_all_loot() -> void:
    for enemy in enemies: _release_loot(enemy)

func _boss_vulnerable() -> bool:
    if boss_hp<=0: return false
    return crab_stun>0 or fmod(boss_clock,5.4)>4.1 if shadow else fmod(boss_clock,6.8)>=3.8
func _update_boss(dt: float) -> void:
    if boss_hp<=0 or player.x<(12870 if shadow else Journey.sx(6420)): return
    boss_clock += dt
    boss_shot_clock += dt
    flip_stun = maxf(0,flip_stun-dt)
    crab_stun = maxf(0,crab_stun-dt)
    if shadow: _update_duo(dt)
    else:
        var cycle := fmod(boss_clock,6.8)
        boss_phase = "recover" if cycle>=3.8 else ("attack" if cycle>=.9 else "windup")
        boss_position = Vector2(_boss_home()-(sin((cycle-2.8)*PI)*310 if cycle>=2.8 and cycle<3.8 else 0.0),540+sin(boss_clock*1.1)*90)
        if cycle>=.9 and cycle<2.8 and boss_shot_clock>.7:
            boss_shot_clock = 0
            var aim := (player-boss_position).normalized()
            for angle in [-.28,0,.28]: _spawn_hostile(boss_position,aim.rotated(angle),310)
        if player.distance_to(boss_position)<160:
            if boost_time>0 and _boss_vulnerable() and boss_hit_cooldown<=0:
                boss_hp -= 1
                boss_hit_cooldown = 1.1
                invulnerable = .8
                boss_clock = 0
                _award("boss:miguel:%s" % boss_hp,"Boss",200,boss_position,false)
            elif boost_time<=0 and not _boss_vulnerable(): _damage(boss_position)
    if boss_hp<=0: _finish_boss()
func _update_duo(dt: float) -> void:
    boss_phase = "recover" if _boss_vulnerable() else "windup"
    boss_position = Vector2(13455+sin(boss_clock*.55)*100,690+sin(boss_clock*1.1)*30)
    if flip_stun<=0:
        flip_position = flip_position.move_toward(Vector2(13358+sin(boss_clock*.9)*560,430+sin(boss_clock*1.65)*165),dt*380)
    combo_clock += dt
    if boss_shot_clock>.9 and duke_hp>0 and fmod(boss_clock,5.4)<3:
        boss_shot_clock = 0
        var aim := (player-boss_position).normalized()
        for angle in [-.2,0,.2]: _spawn_hostile(boss_position,aim.rotated(angle),245)
    if combo_clock>5.8 and flip_hp>0 and duke_hp>0:
        combo_clock = 0
        flip_position = boss_position+Vector2(-100,-30)
        flip_stun = 2.2
        crab_stun = 2.2
        _say("Comedy collision! Duke and Flip are open to boost!",2.2)
    if player.distance_to(boss_position)<155 and duke_hp>0:
        if boost_time>0 and _boss_vulnerable() and boss_hit_cooldown<=0:
            duke_hp = maxi(0,duke_hp-2)
            boss_hit_cooldown = .9
            invulnerable = .8
            _award("duke:%s" % duke_hp,"Boss",120,boss_position,false)
        elif boost_time<=0 and not _boss_vulnerable(): _damage(boss_position)
    if player.distance_to(flip_position)<85 and flip_hp>0:
        if boost_time>0 and boss_hit_cooldown<=0:
            flip_hp -= 1
            flip_stun = .8
            boss_hit_cooldown = .7
            invulnerable = .8
            _award("flip:%s" % flip_hp,"Boss",100,flip_position,false)
        elif boost_time<=0 and flip_stun<=0: _damage(flip_position)
    boss_hp = duke_hp+flip_hp
    if (duke_hp<=0 and flip_hp<=2) or (flip_hp<=0 and duke_hp<=2):
        duke_hp = 0
        flip_hp = 0
        boss_hp = 0

func _update_bubbles(dt: float) -> void:
    for shot in bubble_shots:
        shot["pos"] = Vector2(shot["pos"])+Vector2(float(shot["direction"])*700*dt,0)
        shot["life"] = float(shot["life"])-dt
        var pos: Vector2 = shot["pos"]
        for block in obstacles:
            if block.grow(20).has_point(pos): shot["life"] = 0
        if float(shot["life"])<=0: continue
        for i in range(switches.size()):
            var switch: Dictionary = switches[i]
            if not switch["on"] and pos.distance_to(switch["pos"])<48:
                switch["on"] = true
                shot["life"] = 0
                _award("switch:%s" % i,"Secrets",150,switch["pos"],false)
                treasures.append(Journey.pickup(switch["pos"].x+140,switch["pos"].y-40,"chest"))
                _say("Shell switch — secret treasure revealed!",2.8)
        if float(shot["life"])<=0: continue
        for enemy in enemies:
            if int(enemy["hp"])>0 and pos.distance_to(Vector2(enemy["x"],enemy["y"]))<70:
                _hit_enemy(enemy,1,false)
                shot["life"] = 0
                break
        if float(shot["life"])<=0 or boss_hp<=0 or not shadow: continue
        if flip_hp>0 and pos.distance_to(flip_position)<100 and boss_hit_cooldown<=0:
            flip_hp -= 1
            flip_stun = .8
            boss_hit_cooldown = .4
            shot["life"] = 0
        elif duke_hp>0 and _boss_vulnerable() and pos.distance_to(boss_position)<150 and boss_hit_cooldown<=0:
            duke_hp -= 1
            boss_hit_cooldown = .4
            shot["life"] = 0
        boss_hp = duke_hp+flip_hp
    bubble_shots = bubble_shots.filter(func(shot): return float(shot["life"])>0)
    if boss_hp<=0: _finish_boss()

func _finish_boss() -> void:
    hostile_shots.clear()
    # The ledger makes this idempotent, including a last hit from a bubble.
    if not score_book.seen.has("boss:clear"):
        _say("Boss clear — follow the glowing portal!",6)
        _award("boss:clear","Boss",1000,boss_position,false)

const FLIP_ART = preload("res://godot/assets/flip-dolphin-v018.png")
const Terrain = preload("res://godot/terrain_painter.gd")

func _draw_world(s: Vector2) -> void:
    var background: Texture2D = SHADOW_BACKGROUND if shadow else LAGOON_BACKGROUND
    var progress := clampf(camera/maxf(1,_level_length()-s.x),0,1)
    if shadow:
        var cover := maxf(s.x/background.get_width(),s.y/background.get_height())*1.12
        var panorama_size := background.get_size()*cover
        draw_texture_rect(background,Rect2(Vector2(-(panorama_size.x-s.x)*progress,(s.y-panorama_size.y)*.5),panorama_size),false)
    else:
        Terrain.panorama(self,background,s,_water_line(),350.0,progress)
    draw_rect(Rect2(0,_water_line(),s.x,s.y-_water_line()),Color(.015,.06,.15,.25) if shadow else Color(.015,.2,.22,.18))
    draw_line(Vector2(0,_water_line()),Vector2(s.x,_water_line()),Color(.5,.95,.95,.65),3)
    texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
    Terrain.seabed(self,s,camera,"shadow" if shadow else "miguel")
    for i in range(obstacles.size()):
        var block := obstacles[i]
        var rect := Rect2(block.position-Vector2(camera,0),block.size)
        if rect.end.x< -20 or rect.position.x>s.x+20: continue
        Terrain.rock(self,rect,i,"shadow" if shadow else "miguel")
    for i in range(46 if shadow else 76):
        var x := 195+i*(306 if shadow else 305)-camera
        if x< -180 or x>s.x+180: continue
        if shadow:
            Terrain.garden(self,Vector2(x,Terrain.ground_y(x+camera)),i,"shadow",125+(i%3)*22)
        else:
            var texture: Texture2D = LagoonArt.frames[flora_keys[i%flora_keys.size()]]
            Terrain.planted(self,texture,Vector2(x,Terrain.ground_y(x+camera)+5),170*texture.get_height()/maxf(texture.get_width(),texture.get_height()),Color(.86,.98,.94))
    for x in Journey.pads(shadow):
        if x-camera< -160 or x-camera>s.x+160: continue
        var pos := Vector2(x-camera,_water_line()+75)
        _paint_oval(pos,Vector2(80,18),Color("#65c9a0"))
        draw_arc(pos,55,PI,TAU,24,Color("#fff1a8"),3)
        _draw_text(pos+Vector2(-27,6),"JUMP",14,Color("#123f47"))
    for switch in switches:
        var pos: Vector2 = switch["pos"]-Vector2(camera,0)
        if pos.x< -100 or pos.x>s.x+100: continue
        draw_circle(pos,29,Color("#89ffca") if switch["on"] else Color("#b799ed"))
        draw_arc(pos,36,0,TAU,30,Color("#fff0be"),3)
        _draw_text(pos+Vector2(-12,7),"✓" if switch["on"] else "B",20)
    # Draw ordinary rewards and both projectile types using the original native icons.
    super._draw_world(s)
    for enemy in enemies:
        if enemy["hp"]<=0 or not enemy["kind"] in Journey.PACK_KINDS: continue
        var pos := Vector2(enemy["x"]-camera,enemy["y"])
        if pos.x< -220 or pos.x>s.x+220: continue
        var texture := LagoonArt.enemy_frame(enemy)
        var scale := 165/float(LagoonArt.sizes[enemy["kind"]])
        var size := texture.get_size()*scale
        if enemy["kind"] == "disco-cuttlefish" and enemy.get("mode","") in ["windup","attack"]:
            for side in [-1,1]: draw_texture_rect(texture,Rect2(pos+Vector2(side*115,-20)-size*.5,size),false,Color(1,1,1,.25))
        draw_texture_rect(texture,Rect2(pos-size*.5,size),false)
        if enemy.get("mode","") == "windup": draw_arc(pos,100,0,TAU,32,Color(1,.85,.45,.7),2)
    var portal := Vector2(_portal_x()-camera,540)
    if portal.x> -180 and portal.x<s.x+180:
        Terrain.portal(self,portal,boss_hp<=0)
        _draw_text(portal+Vector2(-76,145),"PORTAL OPEN" if boss_hp<=0 else "DEFEAT THE BOSS",17)
    var label := "DESCENT"
    if shadow:
        for section in [[2860,"OUTER KINGDOM"],[5720,"CRAB MARKET"],[8580,"SHADOW TUNNELS"],[11440,"ROYAL APPROACH"]]:
            if player.x>=section[0]: label = section[1]
    else: label = "COLOMBIA · THE ENCHANTED LAGOON"
    _draw_text(Vector2(30,s.y-30),label,16,Color(.85,.97,1,.85))
func _paint_oval(pos: Vector2, size: Vector2, color: Color) -> void:
    var vertices := PackedVector2Array()
    for i in range(40): vertices.append(pos+Vector2(cos(i*TAU/40),sin(i*TAU/40))*size)
    draw_colored_polygon(vertices,color)
func _draw_boss() -> void:
    if boss_hp<=0: return
    var pos := boss_position-Vector2(camera,0)
    if shadow:
        if duke_hp>0:
            # Artwork is rendered by the expressive boss mesh actor.
            draw_arc(pos,175,0,TAU,48,Color("#9dffd5") if _boss_vulnerable() else Color("#d2b8f4"),3)
            _draw_text(pos+Vector2(-70,-170),"DUKE CLAW  %s/10" % duke_hp,16)
        if flip_hp>0:
            var flip := flip_position-Vector2(camera,0)
            # Flip has a connected tail performance and independent hit reaction.
            _draw_text(flip+Vector2(-70,-95),"FLIP  %s/8" % flip_hp,16)
            if flip_stun>0: draw_arc(flip,115,0,TAU,32,Color("#a8ffe2"),3)
    else:
        # Miguel’s wing mesh remains anchored at its shared centre.
        draw_arc(pos,195,0,TAU,48,Color("#96ffd1") if _boss_vulnerable() else Color("#e3a5ff"),4)
        _draw_text(pos+Vector2(-100,-185),"MIGUEL · BOOST NOW!" if _boss_vulnerable() else "MIGUEL · DODGE THE STARS",17)
