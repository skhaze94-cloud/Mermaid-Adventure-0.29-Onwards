extends Node
## The single route catalog owns chapter selection, continuation and ending.
const Data = preload("res://godot/chapter_data.gd")
const SCENES := ["res://godot/highland_level.tscn","res://godot/shadow_kingdom.tscn","res://godot/miguel_lagoon.tscn","res://godot/blackwater_tunnel.tscn","res://godot/pearl_palace.tscn","res://godot/rana_ruin.tscn","res://godot/nessie_finale.tscn","res://godot/training_lagoon.tscn"]
const NAMES := Data.TITLES
var tutorial_complete := false
var avina_along := false
var active := false
var completed: Dictionary = {}
var start_index := 0
func begin(index := 0) -> void:
    tutorial_complete = false
    avina_along = false
    active = true
    start_index = clampi(index,0,SCENES.size()-1)
    completed.clear()
func next_index(index: int) -> int:
    if index == 7: return 0
    return index+1 if index < 6 else -1
func next_scene(index: int) -> String:
    var next := next_index(index)
    return SCENES[next] if next >= 0 else ""
func next_name(index: int) -> String:
    var next := next_index(index)
    return NAMES[next] if next >= 0 else ""
func complete_stage(index: int, points: int) -> void:
    completed[index] = points
func total() -> int:
    var result := 0
    for points in completed.values(): result += int(points)
    return result
