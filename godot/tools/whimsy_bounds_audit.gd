extends SceneTree
const Garden=preload("res://godot/whimsy_garden.gd")
var checks:=0
func good(ok: bool) -> void:
    checks+=1
    assert(ok)
func _initialize() -> void:call_deferred("run")
func run() -> void:
    root.size=Vector2i(4000,960)
    var garden=Garden.new();root.add_child(garden)
    var identity: int=garden.batch_mesh.get_instance_id()
    var points:=[]
    for chapter in range(7):
        garden.set_world(0,280,Vector2(500,650),chapter,false,false,true,false)
        good(garden.station_count==4)
        garden.batch_used=0
        var colour: Array=garden.PALETTES[chapter]
        for i in range(4):
            var at:=Vector2(300+i*780,880)
            match chapter:
                0:garden._clam(at,colour,1.25,1.4,1)
                1:garden._lanterns(at,colour,1.25,1.4,1)
                2:garden._orchids(at,colour,1.25,1.4,1)
                3:garden._corals(at,colour,1.25,1.4,1)
                4:garden._mobile(at,colour,1.25,1.4,1)
                5:garden._tadpoles(at,colour,1.25,1.4,1)
                6:garden._stars(at,colour,1.25,1.4,1)
        good(garden.batch_used>0 and garden.batch_used<=garden.BATCH_VERTEX_CAP)
        good(garden.batch_overflows==0)
        good(garden.batch_vertices.size()==garden.BATCH_VERTEX_CAP and garden.batch_colours.size()==garden.BATCH_VERTEX_CAP*4)
        good(garden.batch_mesh.get_surface_count()==1 and garden.batch_mesh.get_instance_id()==identity)
        points.append({'chapter':chapter,'vertices':garden.batch_used})
    garden.free();await process_frame
    print('GARDEN BATCH: ',checks,' checks ',JSON.stringify(points));quit()
