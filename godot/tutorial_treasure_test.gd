extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,note: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error("TREASURE 031: "+note)
func frames(n:=3) -> void:
    for i in range(n):await process_frame
func run() -> void:
    root.get_node("AppPreferences").persist_enabled=false
    root.get_node("AppPreferences").intro_seen=true
    root.get_node("OceanAudio").playback_enabled=false
    root.get_node("AdventureRun").active=false
    root.get_node("AdventureRun").persist_enabled=false
    var level=load("res://godot/training_lagoon.tscn").instantiate()
    root.add_child(level)
    level.set_process(false);level.set_physics_process(false)
    await frames()
    level._close_dialogue()
    var gallery=level.treasure_gallery
    gallery.set_process(false)
    var items: Array=level.treasures.filter(func(t):return t["kind"]=="chest")
    check(items.size()==5,"three existing surface relics plus two existing cavern chests")
    check(gallery.actors.size()==5,"bounded pool exactly matches the original five pickups")
    check(level._owns_treasure_visual(items[0]),"tutorial compositor owns chest painting")
    check(not level._owns_treasure_visual({"kind":"pearl"}),"pearls keep the original renderer")
    for i in range(7):
        var actor=preload("res://godot/tutorial_treasure_chest.gd").new()
        root.add_child(actor);actor.configure(i)
        check(actor.CLOSED[i].get_size()==Vector2(256,224),"closed texture imports at documented dimensions: "+str(i))
        check(actor.LIDS[i].get_size()==Vector2(256,224),"lid texture imports: "+str(i))
        check(actor.BODIES[i].get_size()==Vector2(256,224),"body texture imports: "+str(i))
        actor.free()
    var saved_positions: Array=[]
    for item in items:saved_positions.append(Vector2(item.x,item.y))
    # Collect each real item through the existing gameplay function. Never set 'taken' here.
    for item in items:
        level.player=Vector2(item.x,item.y)
        var before: int=level.score
        var count_before: int=level.picked_count
        var expected_pickups:=0
        for pickup in level.treasures:
            if not pickup.taken and pickup.kind in ["pearl","chest"] and level.player.distance_to(Vector2(pickup.x,pickup.y))<59.0:expected_pickups+=1
        var treasure_before: int=level.score_book.categories.get("Treasure",0)
        level._update_collectibles()
        gallery.sync(true,1.0/60)
        var actor=gallery.actors[gallery.key_for(item)]
        check(bool(item.taken),"real pickup marks taken")
        check(actor.collected,"visual opens from actual taken state")
        check(actor.opening_events==1,"one opening event per reward")
        check(level.picked_count==count_before+expected_pickups,"only real nearby pickups counted")
        check(int(level.score_book.categories.get("Treasure",0))==treasure_before+100,"exact original 100-point base chest award")
        check(level.score>=before+100,"original chest points still awarded")
        for j in range(60):gallery.sync(true,1.0/60)
        check(is_equal_approx(actor.open_progress,1.0),"hinged opening settles")
        var paid: int=level.score
        level._update_collectibles();gallery.sync(true,.01)
        check(level.score==paid,"remaining near an open chest cannot pay twice")
        check(actor.opening_events==1,"remaining near a chest cannot retrigger reveal")
    check(gallery.actors.size()==5,"open chests remain in the world; no node growth")
    for i in range(items.size()):check(Vector2(items[i].x,items[i].y)==saved_positions[i],"original world position preserved")
    # Restore/respawn must snap to checkpoint data instead of replaying treasure rewards.
    level._save_checkpoint();level._respawn();gallery.sync(true,.01)
    for key in gallery.actors:
        var actor=gallery.actors[key]
        check(actor.collected and actor.open_progress==1.0,"collected state survives checkpoint respawn")
        check(actor.reveal_age>=2.35,"restored chest does not replay celebratory burst")
    # Fresh restart must close the same five chests and permit one new legitimate reward.
    level._restart();level._close_dialogue();gallery.sync(true,0)
    check(gallery.actors.size()==5,"restart reuses the bounded actor pool")
    for key in gallery.actors:check(not gallery.actors[key].collected,"fresh tutorial resets chests")
    items=level.treasures.filter(func(t):return t["kind"]=="chest")
    level.reduced_fx=true;level.high_depth_quality=false
    level.player=Vector2(items[0].x,items[0].y);level._update_collectibles();gallery.sync(true,.016)
    var gentle_actor=gallery.actors[gallery.key_for(items[0])]
    check(gentle_actor.gentle and gentle_actor.economy,"comfort and economy propagate live")
    check(gentle_actor.open_progress==1.0,"gentle motion snaps open without lid movement")
    var frozen: float=gentle_actor.clock
    gallery.sync(true,.1)
    check(gentle_actor.clock==frozen,"gentle mode stops ambient glint animation")
    var actor_count: int=gallery.get_child_count()
    for i in range(300):gallery.sync(true,.016)
    check(gallery.get_child_count()==actor_count,"long idle does not allocate extra actors")
    # The real vertical camera carries cave sprites; no double camera-Y subtraction.
    level.player=Vector2(items[-1].x,items[-1].y)
    level.camera=maxf(0,level.player.x-500)
    level.deep_routes.sync(true);gallery.sync(false)
    var cave=gallery.actors[gallery.key_for(items[-1])]
    check(cave.visible,"cavern chest survives camera culling")
    check(is_equal_approx(cave.position.y,float(items[-1].y)),"cave position stays in world Y")
    level.free();await frames()
    var other=load("res://godot/highland_level.tscn").instantiate();root.add_child(other)
    other.set_process(false);other.set_physics_process(false)
    await frames()
    check(not other.has_method("_owns_treasure_visual"),"non-tutorial render path unchanged")
    check(other.get_node_or_null("TutorialTreasureChests")==null,"other chapters do not instantiate tutorial chests")
    other.free();await frames()
    print("TREASURE 031: %d checks, %d failures" % [checks,failures])
    quit(0 if failures==0 else 1)
