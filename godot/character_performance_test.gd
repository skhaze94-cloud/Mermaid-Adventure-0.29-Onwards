extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
    var Script=load("res://godot/character_performance.gd")
    assert(Script.TRAITS.size()==16)
    for id in Script.TRAITS:
        var p=Script.new(id);var states: Dictionary={}
        p.advance(0,0,false,false,1)
        for i in range(1,601):
            p.advance(float(i)/60,1,false,false,1);states[p.state]=true
            assert(p.offset.is_finite() and is_finite(p.tilt))
            assert(p.offset.length()<12 and absf(p.tilt)<.09)
        assert(states.has("notice") and states.has("hello") and states.has("shy") and p.state=="rest")
        p.advance(10.1,1,true,false,1);assert(p.state=="delight")
        for i in range(1,241):p.advance(10.1+float(i)/60,1,true,false,1)
        assert(p.state=="rest")
        p.advance(14.2,1,false,true,1);assert(p.offset==Vector2.ZERO and p.tilt==0 and p.look==0 and p.joy==0)
        p.advance(14.3,1,false,false,1);assert(p.state=="rest")
        p.advance(0,0,false,false,-1);assert(p.offset.is_finite())
    print("CHARACTER PERFORMANCE: 16 residents; ordered greetings, bounded poses, no repeated celebration, quiet/resume and retry passed")
    quit()
