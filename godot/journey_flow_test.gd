extends SceneTree
## Geometry/progression traversal with the real swim controller and touch steering.
## Enemy combat is covered separately; this is not a human balance playthrough.
const Rock = preload("res://godot/rock_collision.gd")
var checks := 0
var failures := 0
var ticks := 0
var records: Array[Dictionary] = []
var retried: Dictionary = {}
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error("JOURNEY FLOW: "+message)
func frames(count := 3) -> void:
    for i in range(count): await process_frame
func unique_sorted(values: Array[float]) -> Array[float]:
    values.sort()
    var result: Array[float] = []
    for value in values:
        if result.is_empty() or absf(value-result[-1])>.01: result.append(value)
    return result
func route(level: Node, destination: Vector2) -> Array[Vector2]:
    # Exact obstacle-edge graph, inflated beyond Sarah's collision radius.
    var bounds: Rect2 = level._swim_bounds()
    var margin: float = level.HERO_RADIUS*.73
    var start: Vector2 = level.player
    var goal := Vector2(clampf(destination.x,bounds.position.x+1,bounds.end.x-1),clampf(destination.y,bounds.position.y+1,bounds.end.y-1))
    var xs: Array[float] = [start.x,goal.x]
    var ys: Array[float] = [start.y,goal.y,bounds.position.y+15,bounds.end.y-15,480,620]
    for rock in level.obstacles:
        var box: Rect2 = rock.grow(margin)
        for value in [box.position.x-13,box.end.x+13]:
            if value>bounds.position.x and value<bounds.end.x:xs.append(value)
        for value in [box.position.y-13,box.end.y+13]:
            if value>bounds.position.y and value<bounds.end.y:ys.append(value)
    xs=unique_sorted(xs);ys=unique_sorted(ys)
    var width := xs.size()
    var points: Array[Vector2] = []
    var valid: Array[bool] = []
    for y in ys:
        for x in xs:
            var p := Vector2(x,y)
            points.append(p)
            valid.append(bounds.has_point(p) and not Rock.blocked(p,level.obstacles,margin))
    var first := points.find(start)
    var last := points.find(goal)
    if first<0 or last<0:return []
    var queue: Array[int] = [first]
    var seen := {first:-1}
    var cursor := 0
    while cursor<queue.size() and not seen.has(last):
        var here := queue[cursor];cursor+=1
        for next in [here-1,here+1,here-width,here+width]:
            if next<0 or next>=points.size() or seen.has(next) or not valid[next]:continue
            if abs(next-here)==1 and next/width!=here/width:continue
            var middle: Vector2 = (points[here]+points[next])*.5
            if Rock.blocked(middle,level.obstacles,margin):continue
            seen[next]=here;queue.append(next)
    if not seen.has(last):return []
    var path: Array[Vector2] = []
    var end := last
    while end!=-1:
        path.push_front(points[end]);end=int(seen[end])
    # Drop collinear grid points, keeping every actual turn.
    var compact: Array[Vector2] = []
    for p in path:
        if compact.size()>1 and (compact[-1]-compact[-2]).normalized().is_equal_approx((p-compact[-1]).normalized()):compact.pop_back()
        compact.append(p)
    return compact
func swim(level: Node, goal: Vector2) -> bool:
    var path := route(level,goal)
    if path.is_empty():return false
    for point in path:
        var local_ticks := 0
        var limit := int(level.player.distance_to(point)/3)+300
        while level.player.distance_to(point)>6 and local_ticks<limit:
            var delta: Vector2 = point-level.player
            level.touch_vectors[99]=delta.normalized()*minf(1,delta.length()/30)
            var previous_checkpoint: float = level.checkpoint
            level._update_swimming(1.0/60)
            level._update_collectibles()
            level._check_checkpoints()
            ticks+=1;local_ticks+=1
            if level.checkpoint!=previous_checkpoint and not retried.has(level.checkpoint) and level.waterfall_phase=="":
                retried[level.checkpoint]=true
                var safe: Vector2 = level.checkpoint_position
                check(not Rock.blocked(safe,level.obstacles,level.HERO_RADIUS*.73),"checkpoint snapshot has collision-free berth")
                level._respawn()
                check(level.player.distance_to(safe)<2,"each checkpoint retry uses saved berth")
                check(level.health==level.MAX_HEALTH and is_equal_approx(level.energy,1),"each retry refreshes fins")
                return swim(level,goal)
            if level.waterfall_phase!="":
                # Advance the actual inlet/descent/outflow; protect the traversal
                # fixture from hazard damage instead of disabling the sequence.
                level.touch_vectors.clear()
                for waterfall_tick in range(1400):
                    level.invulnerable=2
                    level._update_waterfall(1.0/60)
                    if level.waterfall_phase=="":break
                return swim(level,goal)
            if level.state=="victory":return true
        if local_ticks>=limit:return false
        # A neutral brake at each planned corner prevents test steering overshoot.
        level.player_velocity=Vector2.ZERO
    level.touch_vectors.clear()
    return true
func run() -> void:
    var prefs = root.get_node("AppPreferences")
    prefs.persist_enabled=false;prefs.intro_seen=true
    var catalog = root.get_node("AdventureRun")
    for index in range(7):
        paused=false
        catalog.begin(index)
        var level = load(catalog.SCENES[index]).instantiate()
        root.add_child(level);current_scene=level
        level.set_process(false);level.set_physics_process(false)
        await frames()
        # Real control and collision integration; no player-position teleport.
        retried.clear()
        level._prepare_journey_stops()
        var previous_stop: float = level._route_start()
        for stop in level.journey_stops:
            check(float(stop["x"])>previous_stop,"rest stops advance along chapter "+str(index))
            check(float(stop["x"])-previous_stop<=5800,"retry leg remains under roughly fourteen seconds of open swimming "+str(index))
            check(not Rock.blocked(stop["position"],level.obstacles,level.HERO_RADIUS*.73),"rest stop is outside reef collision "+str(index))
            previous_stop=float(stop["x"])
        check(level._portal_x()-level._boss_home()<=3000,"clear has a short portal epilogue "+str(index))
        var before_ticks := ticks
        var start: Vector2 = level.player
        var arena := Vector2(level._boss_home()-550,620)
        var reached := swim(level,arena)
        check(reached,"continuous swim reaches encounter in chapter "+str(index))
        check(level.state=="playing","boss gate remains closed before encounter "+str(index))
        var saved: Vector2 = level.checkpoint_position
        var cp: float = level.checkpoint
        level._respawn()
        check(not Rock.blocked(level.player,level.obstacles,level.HERO_RADIUS*.73),"immediate retry is collision-free "+str(index))
        check(level.player.distance_to(saved)<2,"retry uses the safe checkpoint position "+str(index)+" actual="+str(level.player)+" saved="+str(saved))
        check(level.hostile_shots.is_empty() and level.bubble_shots.is_empty(),"retry clears transient shots "+str(index))
        check(swim(level,arena),"encounter is reachable again after retry "+str(index))
        # Boss battle mechanics are exercised by boss_polish/Opal suites. This
        # phase fixture validates the real post-clear travel and portal event.
        level.boss_hp=0
        if index==1:level.duke_hp=0;level.flip_hp=0
        check(swim(level,Vector2(level._portal_x()+12,620)),"post-clear swim reaches portal "+str(index))
        check(level.state=="victory" and paused,"portal enters results "+str(index))
        check(level._hud_snapshot().progress>=.999,"route progress ends at 100 percent "+str(index))
        records.append({"chapter":index,"start":str(start),"checkpoint":cp,"ticks":ticks-before_ticks,"checkpoints_retried":retried.size(),"finish":str(level.player)})
        level.free();current_scene=null;paused=false
    print("JOURNEY FLOW: ",checks," checks, ",failures," failures; ",ticks," native swim ticks")
    print(JSON.stringify(records))
    quit(1 if failures else 0)
