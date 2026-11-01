extends SceneTree
## Native design-system board built from production theme, art and HUD controls.
const Pearl=preload("res://godot/pearl_storybook.gd")
var output:=OS.get_environment("PEARL_QA_DIR")
var board: Control
var huds: Array=[]
func _initialize() -> void:call_deferred("run")
func text(value: String,at: Vector2,size_px:=22,tint:=Pearl.INK) -> Label:
    var label:=Pearl.label(value,size_px,tint);label.position=at;board.add_child(label);return label
func panel(at: Vector2,size: Vector2) -> Panel:
    var p:=Panel.new();p.position=at;p.size=size;p.add_theme_stylebox_override("panel",Pearl.panel(Pearl.PAPER,Pearl.SEAFOAM,24,20));p.mouse_filter=Control.MOUSE_FILTER_IGNORE;board.add_child(p);return p
func icon(name: String,at: Vector2,size:=Vector2(44,44)) -> TextureRect:
    var image:=Pearl.icon(name,size);image.position=at;image.size=size;board.add_child(image);return image
func action(value: String,at: Vector2,size: Vector2,primary:=false) -> Button:
    var button:=Button.new();button.text=value;button.position=at;button.size=size;button.custom_minimum_size=size;Pearl.button(button,primary);board.add_child(button);return button
func production_hud(info: Dictionary):
    var hud=load("res://godot/premium_hud.gd").new();root.add_child(hud);hud.set_process(false);hud.update_hud(info);hud._process(100);hud.canvas.hide();huds.append(hud);return hud
func move_control(control: Control,at: Vector2,size: Vector2) -> void:
    control.reparent(board,false);control.position=at;control.size=size;control.show()
func run() -> void:
    if output.is_empty():push_error("PEARL_QA_DIR required");quit(1);return
    DirAccess.make_dir_recursive_absolute(output)
    root.size=Vector2i(1440,1000);root.content_scale_size=Vector2i(1440,1000);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
    var prefs=root.get_node("AppPreferences");prefs.persist_enabled=false;prefs.intro_seen=true
    root.get_node("AdventureRun").persist_enabled=false;root.get_node("OceanAudio").playback_enabled=false
    board=Control.new();board.theme=Pearl.theme();board.size=Vector2(1440,1000);root.add_child(board)
    var background:=ColorRect.new();background.color=Color("#133c49");background.size=board.size;board.add_child(background)
    text("Pearl Storybook",Vector2(40,26),38,Pearl.IVORY)
    text("MERMAID ADVENTURE  ·  v0.38",Vector2(1010,44),19,Pearl.MINT)
    text("Warm words. Clear little signals. Room for wonder.",Vector2(42,80),21,Pearl.MINT)
    # Speech and replies use the exact production theme and shared painted assets.
    panel(Vector2(36,128),Vector2(664,278))
    icon("shell",Vector2(58,148),Vector2(38,38));text("King Daddy",Vector2(110,150),23,Pearl.GOLD)
    text("Over here, little pearl!",Vector2(68,205),30)
    text("Three glowing rings first. Take your time.",Vector2(68,252),22,Pearl.MUTED)
    action("Say something…",Vector2(62,330),Vector2(226,54))
    action("Let’s swim  ›",Vector2(435,330),Vector2(235,54),true)
    panel(Vector2(36,428),Vector2(664,280))
    text("A little Sarah personality",Vector2(62,448),22,Pearl.GOLD)
    action("I’m ready, Dad!",Vector2(62,493),Vector2(610,54),true)
    var focused:=action("Is the rock on the teaching staff?",Vector2(62,558),Vector2(610,54));focused.grab_focus()
    action("Can you show me how?",Vector2(62,623),Vector2(610,54))
    # These are the same health and charge nodes used during play, not imitations.
    panel(Vector2(724,128),Vector2(680,190));text("Health & boost energy",Vector2(748,148),22,Pearl.GOLD)
    var health=production_hud({"health":4,"energy":.64,"bubble":true,"score":240,"pearls":24,"tutorial":false,"touch":false})
    move_control(health.health_card,Vector2(750,198),Vector2(200,90))
    move_control(health.score_card,Vector2(990,198),Vector2(230,90))
    panel(Vector2(724,340),Vector2(680,194));text("Bubble power · distinct from boost energy",Vector2(748,359),22,Pearl.GOLD)
    var charge=production_hud({"health":5,"energy":1.0,"bubble":true,"touch":false,"charge_tier":3,"charge_progress":1.0})
    var cool=production_hud({"health":5,"energy":1.0,"bubble":true,"touch":false,"charge_tier":0,"cooldowns":{"bubble":.1},"bubble_recovery":.2})
    move_control(charge.charge_card,Vector2(748,420),Vector2(292,76))
    move_control(cool.charge_card,Vector2(1070,420),Vector2(308,76))
    panel(Vector2(724,556),Vector2(680,152));text("Only active gifts appear",Vector2(748,576),22,Pearl.GOLD)
    var badge=load("res://godot/pearl_charm.gd").new();board.add_child(badge);badge.position=Vector2(750,621);badge.size=Vector2(226,60)
    badge.set_powerup({"id":"royal_boost","label":"Royal boost","remaining":8.0,"duration":8.0},true)
    text("Eight seconds of royal zoomies.",Vector2(1000,638),20,Pearl.MUTED)
    # Painted input symbols maintain the actual three-action vocabulary.
    panel(Vector2(36,730),Vector2(664,220));text("Friendly controls",Vector2(62,750),22,Pearl.GOLD)
    for i in range(3):
        var names: Array=["bubble","boost","jump"];var words: Array=["Bubble","Boost","Jump"]
        var x: float=80+i*205
        icon(names[i],Vector2(x,797),Vector2(66,66));text(words[i],Vector2(x-1,876),20)
    panel(Vector2(724,730),Vector2(680,220));text("Small celebrations",Vector2(748,750),22,Pearl.GOLD)
    icon("slug",Vector2(752,805),Vector2(80,70));text("A new friend!",Vector2(850,813),27)
    text("A little hello, then back to exploring.",Vector2(850,862),20,Pearl.MUTED)
    for i in range(4):await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(output+"/design-board.png")
    print("PEARL STORYBOOK PRODUCTION DESIGN BOARD COMPLETE")
    quit()
