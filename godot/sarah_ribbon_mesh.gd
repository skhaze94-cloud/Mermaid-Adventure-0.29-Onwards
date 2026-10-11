extends Polygon2D
## Small textured strip with a fixed attachment edge. UVs never leave its atlas crop.
var rest := PackedVector2Array()
var weights := PackedFloat32Array()
var mesh_updates := 0
func configure(source: Texture2D, region: Rect2, destination: Rect2, columns: int = 8, rows: int = 3) -> void:
    texture = source
    texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    antialiased = true
    var coordinates := PackedVector2Array()
    var faces: Array[PackedInt32Array] = []
    for row in range(rows):
        for column in range(columns + 1):
            var u := float(column) / columns
            var v := float(row) / (rows-1)
            rest.append(destination.position + Vector2(u,v) * destination.size)
            coordinates.append(region.position + Vector2(0.5,0.5) + Vector2(u,v) * (region.size - Vector2.ONE))
            weights.append(pow(1.0-u,2.0))
    for row in range(rows-1):
        for column in range(columns):
            var a := row * (columns+1) + column
            var b := a + columns + 1
            faces.append(PackedInt32Array([a,a+1,b+1]))
            faces.append(PackedInt32Array([a,b+1,b]))
    polygon = rest
    uv = coordinates
    polygons = faces
func deform(phase: float, amplitude: float, inertia: float) -> void:
    var points := rest.duplicate()
    for i in range(points.size()):
        var weight := weights[i]
        # The seam remains fixed; flutter grows gently toward the free edge.
        points[i].y += weight * (sin(phase - weight * 2.8) * amplitude + inertia)
        points[i].x += weight * sin(phase * 0.7 - weight) * amplitude * 0.11
        # Three layered current responses; roots remain pinned, tips move most.
        var ripple := sin(phase*1.37-weight*5.1)*.18+sin(phase*2.11-weight*8.7)*.08
        points[i].y += weight*weight*amplitude*ripple
        points[i].x += weight*weight*amplitude*(sin(phase*1.13-weight*3.9)*.025+sin(phase*1.83-weight*7.3)*.012)
    polygon = points
    mesh_updates += 1
func reset_shape() -> void:
    polygon = rest

