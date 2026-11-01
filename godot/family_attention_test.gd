extends SceneTree
const Attention=preload("res://godot/family_attention.gd")
class Actor extends Node2D:
    var cues: Array[String]=[]
    func react(kind: String) -> void:cues.append(kind)
class Stage extends RefCounted:
    var dialogue_open:=false
    var lesson:=1
    var player:=Vector2.ZERO
    var king_world:=Vector2(350,0)
    var queen_world:=Vector2(6100,0)
    var king=Actor.new()
    var queen_teacher=Actor.new()
    var leap_phase:=""
    var queen_demo:=0.0
var checks:=0
var failures:=0
func check(ok: bool,note: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(note)
func _initialize() -> void:
    var scene=Stage.new();var attention=Attention.new()
    attention.advance(scene,.016);check(scene.king.cues==["wave"],"Approach has no single greeting")
    for i in range(1200):attention.advance(scene,1.0/60)
    check(scene.king.cues.size()==1,"Idle proximity repeats waves on a timer")
    scene.lesson=2;attention.advance(scene,.016)
    check(scene.king.cues==["wave","celebrate"],"Lesson success has no proud response")
    scene.lesson=6;scene.player=Vector2(5800,0);scene.king_world=scene.player+Vector2(350,0);attention.advance(scene,.016)
    check(scene.queen_teacher.cues==["acknowledge"],"Mum lacks a distinct response beside Daddy")
    var count: int=scene.king.cues.size()+scene.queen_teacher.cues.size();var clock: float=attention.lesson_elapsed
    scene.dialogue_open=true
    for i in range(100):attention.advance(scene,.05)
    check(scene.king.cues.size()+scene.queen_teacher.cues.size()==count and attention.lesson_elapsed==clock,"Scene events fight the paused conversation")
    scene.dialogue_open=false;attention.advance(scene,0);check(attention.lesson_elapsed==clock,"Zero-delta pause advances family timing")
    for i in range(1200):attention.advance(scene,1.0/60)
    scene.player=Vector2(2000,0);attention.advance(scene,.05);scene.player=Vector2(5800,0);attention.advance(scene,.05)
    check(scene.queen_teacher.cues.back()=="wave","A genuine return lacks a greeting")
    check(scene.queen_teacher.cues.size()==2,"Mum repeats spontaneous gestures between encounters")
    scene.queen_demo=10;attention.advance(scene,.05)
    scene.queen_demo=6.5;attention.advance(scene,.05)
    scene.queen_demo=3;attention.advance(scene,.05)
    check(scene.queen_teacher.cues.slice(-3)==["cast","cast","cast"],"Gift demonstrations do not get distinct action cues")
    attention.reset();check(attention.last_lesson==-1 and attention.cue_count==Vector2i.ZERO,"Retry retains cues")
    scene.king.free();scene.queen_teacher.free()
    print("FAMILY ATTENTION: ",checks," checks, ",failures," failures");quit(1 if failures else 0)
