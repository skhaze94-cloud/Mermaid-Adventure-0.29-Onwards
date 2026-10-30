extends RefCounted
## One optional, authored discovery per chapter. Positions are world-space and
## recovered once when the chapter binds; nothing here changes route geometry.
const Rock = preload("res://godot/rock_collision.gd")
const TARGET_CLEARANCE := 72.0
const ROUTE_CLEARANCE := 34.0
const MAX_SPAN := 900.0
const PROFILES := [
    {
        "chapter":0,"id":"living-reef:highland:pearl-choir","title":"The Sleepy Pearl Choir","kind":"choir",
        "at":Vector2(6360,480),"points":[Vector2(6180,400),Vector2(6360,400),Vector2(6540,400)],"home":Vector2(6360,520),
        "color":Color("f2c5d1"),"reward":250,
        "discovery_line":"Three sleepy shells! Boost through each one to wake their song — any order.",
        "progress_lines":["One little pearl voice. Two more to wake!","Two voices are humming. Find the last sleepy shell.","All three shells are singing together!"],
        "completion_line":"Sarah: A whole tiny choir, just for us!"
    },
    {
        "chapter":1,"id":"living-reef:shadow:lantern-chorus","title":"The Lantern-Shell Chorus","kind":"choir",
        "at":Vector2(5700,445),"points":[Vector2(5500,365),Vector2(5700,365),Vector2(5900,365)],"home":Vector2(5700,445),
        "color":Color("ccb6df"),"reward":250,
        "discovery_line":"The lantern shells have forgotten their tune. Bubble or Boost each one — any order.",
        "progress_lines":["A lantern begins to hum. Two are still dreaming.","Two gentle notes glow in the kingdom.","The last lantern joins the chorus!"],
        "completion_line":"Sarah: Even a shadow kingdom has a bedtime song."
    },
    {
        "chapter":2,"id":"living-reef:miguel:seahorse-home","title":"Pip’s Orchid Hideaway","kind":"guide",
        "at":Vector2(14180,650),"points":[Vector2(14340,600),Vector2(14540,680),Vector2(14740,610)],"home":Vector2(14900,600),
        "color":Color("dfbdd9"),"reward":250,
        "discovery_line":"A tiny seahorse is looking for home. Swim beside Pip and follow the little stops.",
        "progress_lines":["Pip peeks ahead. Stay close and swim along.","There’s the orchid path! Just a little farther.","Pip spots the cosy hideaway. Follow to the shell!"],
        "completion_line":"Sarah: Home sweet little seahorse home!"
    },
    {
        "chapter":3,"id":"living-reef:blackwater:lantern-current","title":"The Lantern Current","kind":"current",
        "at":Vector2(4940,622),"points":[Vector2(5100,622),Vector2(5360,622),Vector2(5620,622)],"home":Vector2(5800,622),
        "color":Color("9dc8df"),"reward":225,
        "discovery_line":"A little lantern trail! Swim through its three hoops; Boost is optional.",
        "progress_lines":["One lantern shimmers behind you. Follow the next hoop.","Two lanterns are glowing. One more gentle glide.","The whole little passage is twinkling!"],
        "completion_line":"Sarah: It’s like swimming through a pocketful of stars."
    },
    {
        "chapter":4,"id":"living-reef:palace:pearl-chimes","title":"The Pearl-Chime Waltz","kind":"choir",
        "at":Vector2(17220,660),"points":[Vector2(16990,565),Vector2(17210,625),Vector2(17430,565)],"home":Vector2(17220,660),
        "color":Color("ecc6d9"),"reward":275,
        "discovery_line":"The royal pearl chimes are waiting. Bubble or Boost each shell — any order.",
        "progress_lines":["One pearl chime rings softly through the palace.","Two royal notes! The last shell is listening.","Three pearl chimes make a miniature waltz!"],
        "completion_line":"Sarah: A royal concert — and we’re the tiny orchestra!"
    },
    {
        "chapter":5,"id":"living-reef:rana:rainbow-ride","title":"The Rainbow Ribbon Ride","kind":"current",
        "at":Vector2(29320,620),"points":[Vector2(29520,630),Vector2(29750,520),Vector2(29980,640)],"home":Vector2(30180,600),
        "color":Color("d8bddf"),"reward":250,
        "discovery_line":"A rainbow ribbon is curling through the reef. Swim through three hoops at your own pace.",
        "progress_lines":["The first ribbon curls behind you. Follow its next bend.","Two rainbow loops! One last lovely swoop.","You’ve followed the rainbow all the way through!"],
        "completion_line":"Sarah: That was the ocean’s tiniest rainbow ride!"
    },
    {
        "chapter":6,"id":"living-reef:nessie:crownfish-home","title":"Pip’s Crown Homecoming","kind":"guide",
        "at":Vector2(4100,620),"points":[Vector2(4280,585),Vector2(4480,660),Vector2(4680,590)],"home":Vector2(4860,625),
        "color":Color("b7dbe2"),"reward":250,
        "discovery_line":"The crown is safe! This little seahorse needs a swimming companion on the way home.",
        "progress_lines":["Pip gives a happy wiggle. Keep swimming together.","Its little shell home is almost in sight.","There it is! Escort Pip to its doorstep."],
        "completion_line":"Sarah: One crown returned, one little friend home safely."
    },
    {
        "chapter":7,"id":"living-reef:family:farewell-friend","title":"One Last Little Kindness","kind":"guide",
        # Lead away from the open exit so optional play cannot accidentally end
        # the lagoon. This deliberately follows decreasing world x coordinates.
        "at":Vector2(7280,710),"points":[Vector2(7160,680),Vector2(7020,745),Vector2(6880,660)],"home":Vector2(6780,700),
        "color":Color("f0d2bd"),"reward":200,
        "discovery_line":"Baby seahorse Pip needs a little company. Swim beside Pip back to the sleepy shell.",
        "progress_lines":["A little wiggle means hello! Follow your new friend.","Nearly there. The sleepy shell is just ahead.","Your tiny friend sees home. Stay close for the last swim."],
        "completion_line":"Sarah: There you go, little pearl. Sweet dreams!"
    }
]

static func for_chapter(index: int, obstacles: Array[Rect2], bounds: Rect2, boss_x: float) -> Dictionary:
    if index<0 or index>=PROFILES.size():return {}
    if not bounds.position.is_finite() or not bounds.size.is_finite() or bounds.size.x<TARGET_CLEARANCE*2 or bounds.size.y<TARGET_CLEARANCE*2:return {}
    var profile: Dictionary=PROFILES[index].duplicate(true)
    var safe_bounds:=Rect2(bounds.position+Vector2.ONE*TARGET_CLEARANCE,bounds.size-Vector2.ONE*TARGET_CLEARANCE*2)
    # A complete pre-boss diversion stays outside the boss activation band. The
    # finale and family profiles are instead enabled only after their trials.
    var right:=safe_bounds.end.x
    if index<6 and is_finite(boss_x) and boss_x>0:right=minf(right,boss_x-1350.0)
    var left:=float(profile["at"].x)
    var end:=left
    var positions: Array[Vector2]=[profile["at"]]
    for point in profile["points"]:positions.append(point)
    positions.append(profile["home"])
    for point in positions:left=minf(left,point.x);end=maxf(end,point.x)
    if right-safe_bounds.position.x<end-left:return {}
    var shift:=clampf(0.0,safe_bounds.position.x-left,right-end)
    # The authored lanes are already clear. Alternate offsets make a small map
    # adjustment safe without teleporting a target to another part of a chapter.
    for dy in [0.0,-50.0,50.0,-100.0,100.0]:
        var recovered: Array[Vector2]=[]
        for point in positions:
            recovered.append(Rock.recover(point+Vector2(shift,dy),obstacles,TARGET_CLEARANCE,safe_bounds))
        if not _route_clear(recovered,obstacles):continue
        var low:=recovered[0].x
        var high:=low
        for point in recovered:low=minf(low,point.x);high=maxf(high,point.x)
        if high-low>MAX_SPAN or high>right+0.1:continue
        profile["at"]=recovered[0]
        var targets: Array[Vector2]=[recovered[1],recovered[2],recovered[3]]
        profile["points"]=targets
        profile["home"]=recovered[4]
        return profile
    return {}

static func _route_clear(points: Array[Vector2], obstacles: Array[Rect2]) -> bool:
    for point in points:
        if not point.is_finite() or Rock.blocked(point,obstacles,TARGET_CLEARANCE):return false
    for i in range(1,points.size()):
        var a:=points[i-1]
        var b:=points[i]
        # Sarah's actual controller slides on axes. Require clearance along the
        # whole intended path as well, so following a friend is a gentle swim.
        var steps:=maxi(1,ceili(a.distance_to(b)/24.0))
        for step in range(steps+1):
            if Rock.blocked(a.lerp(b,float(step)/steps),obstacles,ROUTE_CLEARANCE):return false
    return true
