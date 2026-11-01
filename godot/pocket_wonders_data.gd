extends RefCounted
## Sixteen authored, optional pockets of wonder. These are local presentation and
## interaction anchors, never new collision bodies or required route gates.
## Authored against source/levels-v82.json, Chapter/Journey bounds and Living
## Reef anchors. Object feet are display coordinates: villages/posts intentionally
## sit on Terrain.ground_y below Sarah's centre bounds; only at/points are swim
## locations. points are optional art details, not a new interaction sequence.
const Rock=preload("res://godot/rock_collision.gd")
const Terrain=preload("res://godot/terrain_painter.gd")
const CHAPTER_IDS:=["highland","shadow","miguel","blackwater","palace","rana","nessie","training"]
const CLEARANCE:=64.0
const NEIGHBOUR_LINES:={
    "post":["Nori: Special delivery! One tiny hello, just for you.","Nori: Express post? I am expressing my very best effort.","Nori: Your hat looks lovely, Sarah. Mine keeps catching the current!","Nori: A letter for the whale. I hope I don't wake him."],
    "tea":["Bramble the butler: One sugar pearl, or a terribly extravagant two?","Lumi the moonjelly: We saved the wobbliest cup for you!","Bramble: The cake is imaginary. The welcome is quite real.","Lumi: I'm practising a very graceful wobble. How am I doing?"],
    "village":["Pipkin the little crab: Morning, Sarah! These socks won't dry themselves.","A shell neighbour: We put the kettle on whenever you swim past.","Pipkin: Three houses, six curtains, and absolutely no hurry.","A shell neighbour: Would you look at that! A mermaid in our front garden."],
    "dream":["A tiny dream-fish: Shhh… the whale is dreaming of being a little smaller.","A tiny dream-fish: You're allowed to take the scenic swim.","A tiny dream-fish: We keep our biggest wishes in the smallest bubbles."],
    "mirror":["A little fish: That was my best mermaid face!","A little fish: Your bubbles are very round today, Sarah.","A little fish: One more silly face? I'll go first next time."]}
const PROFILES:=[
    [
        {"kind":"dream","variant":"whale","title":"The Pocket Whale","at":Vector2(10800,600),"color":Color("d6c2e3"),"reward":100,
        "discovery_line":"A bubble is dreaming of a very small whale. Shall we float and watch?",
        "progress_lines":["One sleepy flipper waves hello.","The whale is sailing through its little dream.","A tiny tail, a soft goodnight."],
        "completion_line":"Sarah: Such a big dream for such a little bubble!"},
        {"kind":"tea","variant":"thimble","title":"The Thimble Tea Party","at":Vector2(15800,650),"color":Color("e7c6d6"),"reward":125,
        "discovery_line":"Three thimble cups and a table for tiny friends. There’s room for one more smile.",
        "progress_lines":["The little cups give a polite clink.","Someone has brought a crumb of mooncake.","A perfectly silly little tea party!"],
        "completion_line":"Sarah: Thank you! That was a very dignified sip of make-believe."}
    ],
    [
        {"kind":"village","variant":"lantern","title":"Drowsy Lantern Lane","at":Vector2(3730,736),"color":Color("cbb9df"),"reward":150,
        "discovery_line":"A whole village smaller than Sarah’s hand. Little curtains are beginning to twitch.",
        "progress_lines":["One lantern window opens.","Another sleepy neighbour peeks outside.","The lane is full of tiny good-evenings."],
        "completion_line":"Sarah: Good evening, little neighbours!"},
        {"kind":"post","variant":"lantern","title":"Nori’s Lantern Post","at":Vector2(9700,746),"color":Color("d3bfdc"),"reward":100,
        "discovery_line":"Nori the little mail-slug has a letter tucked beneath a lantern.",
        "progress_lines":["Nori straightens a very small stamp.","The envelope smells faintly of sea flowers.","A little letter, a lovely thought."],
        "letter":["Dear passing friend,","A little kindness is never too small.","With a very slow wave, Nori."],
        "completion_line":"Sarah: I’ll carry that little kindness with me."}
    ],
    [
        {"kind":"dream","variant":"carousel","title":"The Shell Carousel","at":Vector2(9000,600),"color":Color("d9c1dc"),"reward":100,
        "discovery_line":"A dream-bubble has made a carousel out of shells. Nobody is in a hurry.",
        "progress_lines":["A tiny shell takes its first turn.","Around goes a very gentle little parade.","The carousel settles into a happy dream."],
        "completion_line":"Sarah: One more turn? Perhaps in another dream."},
        {"kind":"mirror","variant":"orchid","title":"The Orchid Looking Pool","at":Vector2(22100,580),"color":Color("d4c5df"),"reward":100,
        "discovery_line":"The reef has made a looking pool. Its reflection seems ready for a little joke.",
        "progress_lines":["A curious face looks back.","A tiny smile becomes a matching smile.","Even the orchids seem to be giggling."],
        "completion_line":"Sarah: The ocean has a wonderful sense of humour."}
    ],
    [
        {"kind":"dream","variant":"rain","title":"A Rain of Sleeping Stars","at":Vector2(7540,620),"color":Color("c5c9e2"),"reward":100,
        "discovery_line":"In a quiet bubble, stars are falling as softly as feathers.",
        "progress_lines":["One star drifts into the dream.","A soft shower of little wishes follows.","The last star curls up for a nap."],
        "completion_line":"Sarah: We found a pocketful of night-sky wishes."},
        {"kind":"post","variant":"glow","title":"Nori’s Star-Mail","at":Vector2(2550,746),"color":Color("c4c4e0"),"reward":100,
        "discovery_line":"A little mail-slug is keeping a lantern lit for the next friendly swimmer.",
        "progress_lines":["Nori pats the glowing envelope.","A carefully folded note is waiting inside.","The tunnel has a little more warmth in it."],
        "letter":["Dear travelling friend,","Even a small light can help someone along.","A star-sized hello, from Nori."],
        "completion_line":"Sarah: Thank you, Nori. That little light is lovely."}
    ],
    [
        {"kind":"village","variant":"pearl","title":"Pearl-Petal Hamlet","at":Vector2(11400,736),"color":Color("e2c8df"),"reward":150,
        "discovery_line":"Pearl roofs, petal curtains and the tiniest front doors in the palace.",
        "progress_lines":["A pearl window glows softly.","Another neighbour brings a little lantern.","The hamlet offers a twinkling welcome."],
        "completion_line":"Sarah: What a lovely place to be very, very small."},
        {"kind":"tea","variant":"royal","title":"One Spoonful of Stardust","at":Vector2(31000,650),"color":Color("e8cfde"),"reward":125,
        "discovery_line":"The royal tea party has polished its smallest spoons. Everyone may be wonderfully silly.",
        "progress_lines":["A spoon makes one little silver ting.","A very important crumb is passed around.","The tiny guests approve of the company."],
        "completion_line":"Sarah: A royal occasion, with excellent imaginary cake."}
    ],
    [
        {"kind":"dream","variant":"whale","title":"The Rainbow Whale’s Nap","at":Vector2(13900,600),"color":Color("d2c1e1"),"reward":100,
        "discovery_line":"A little whale has borrowed the colours of a rainbow for its afternoon dream.",
        "progress_lines":["A sleepy rainbow fin unfolds.","The whale drifts past a cloud of wishes.","Its little dream is ready for a rest."],
        "completion_line":"Sarah: Sweet dreams, little rainbow whale."},
        {"kind":"village","variant":"rainbow","title":"The Rainbow-Shell Village","at":Vector2(25800,736),"color":Color("d8c5df"),"reward":150,
        "discovery_line":"Three little shell houses are tucked beneath the rainbow reef. Shall we say hello?",
        "progress_lines":["A little door peeks open.","Two neighbours are sharing the view.","A whole tiny village waves good day."],
        "completion_line":"Sarah: Three small houses, and such a warm welcome."}
    ],
    [
        {"kind":"post","variant":"homeward","title":"Nori’s Homeward Letter","at":Vector2(2850,746),"color":Color("c9cfdf"),"reward":100,
        "discovery_line":"Now that the crown is safe, Nori has a quiet homeward letter to share.",
        "progress_lines":["Nori finds the right little envelope.","The stamp is a painted seashell.","A homeward hello is ready to travel."],
        "letter":["Dear friend heading home,","There is always room for one more kind hello.","Safe swimming, from Nori."],
        "completion_line":"Sarah: A kind hello is a lovely thing to bring home."},
        # The compact finale cannot give both stations a 1100-unit horizontal
        # berth from Living Reef. This after-clear pool sits high at y440,
        # separate from Pip’s y585–660 route beginning at x4100.
        {"kind":"mirror","variant":"crown","title":"A Crown-Sized Reflection","at":Vector2(3650,440),"color":Color("d3cbe2"),"reward":100,
        "discovery_line":"A little looking pool is waiting beyond the quiet arena. There’s a smile in it already.",
        "progress_lines":["A brave little face looks back.","The water adds a perfectly tiny wink.","The reflection looks rather pleased."],
        "completion_line":"Sarah: That’s the face of a mermaid ready to go home."}
    ],
    [
        # Both family pockets appear only after lesson 10; backtracking is
        # optional and does not move or close the tutorial’s open exit.
        {"kind":"tea","variant":"family","title":"A Teacup Before Goodbye","at":Vector2(3200,620),"color":Color("e8ceda"),"reward":125,
        "discovery_line":"The little reef guests have saved a thimble cup for one last make-believe tea.",
        "progress_lines":["A tiny guest offers a polite little bow.","The smallest cup is passed with great care.","There’s always time for a friendly thank-you."],
        "completion_line":"Sarah: A little tea, a little kindness, and off we go."},
        {"kind":"mirror","variant":"family","title":"Two Very Silly Mermaids","at":Vector2(5570,600),"color":Color("e0c9df"),"reward":100,
        "discovery_line":"A little looking pool is ready for the family’s silliest face. Shall we try one?",
        "progress_lines":["Someone in the water looks very curious.","One little smile invites another.","What a wonderfully silly little moment."],
        "completion_line":"Sarah: We shall have to practise that face again."}
    ]
]

static func for_chapter(index: int, obstacles: Array[Rect2], bounds: Rect2, boss_x: float) -> Array[Dictionary]:
    var result: Array[Dictionary]=[]
    if index<0 or index>=PROFILES.size():return result
    if not bounds.position.is_finite() or not bounds.size.is_finite() or bounds.size.x<500 or bounds.size.y<200:return result
    var safe_bounds:=Rect2(bounds.position+Vector2(40,40),bounds.size-Vector2(80,80))
    for authored in PROFILES[index]:
        var profile: Dictionary=authored.duplicate(true)
        profile["chapter"]=index
        profile["neighbour_lines"]=NEIGHBOUR_LINES.get(profile["kind"],[]).duplicate()
        profile["id"]="wonders:%s:%s" % [CHAPTER_IDS[index],profile["kind"]]
        profile["after_boss"]=index==6
        profile["after_lesson"]=10 if index==7 else 0
        if not profile.has("letter"):profile["letter"]=[]
        var at: Vector2=profile["at"]
        var kind: String=profile["kind"]
        # Reserve the whole authored vignette's horizontal footprint outside
        # boss activation, rather than just clamping its interaction centre.
        var half_width:=205.0 if kind=="village" else 200.0 if kind=="tea" else 130.0 if kind=="dream" else 105.0 if kind=="mirror" else 60.0
        var right:=safe_bounds.end.x-half_width
        if index<6 and is_finite(boss_x) and boss_x>0:right=minf(right,boss_x-1350.0-half_width)
        if right<safe_bounds.position.x+half_width:return []
        at.x=clampf(at.x,safe_bounds.position.x+half_width,right)
        if kind=="village":at.y=Terrain.ground_y(at.x)-160.0
        elif kind=="post":at.y=Terrain.ground_y(at.x)-150.0
        at=Rock.recover(at,obstacles,CLEARANCE,safe_bounds)
        profile["at"]=at
        match kind:
            "village":profile["prop_at"]=Vector2(at.x,Terrain.ground_y(at.x))
            "post":profile["prop_at"]=Vector2(at.x,Terrain.ground_y(at.x))
            "tea":profile["prop_at"]=at+Vector2(0,120)
            _:profile["prop_at"]=at
        var details: Array[Vector2]=[]
        var offsets: Array[Vector2]=[Vector2(-85,-20),Vector2(0,25),Vector2(85,-20)]
        if kind=="tea":offsets=[Vector2(-80,50),Vector2(0,38),Vector2(80,50)]
        elif kind=="mirror":offsets=[Vector2(-70,0),Vector2(0,-35),Vector2(70,0)]
        elif kind=="post":offsets=[Vector2(-55,-10),Vector2(0,10),Vector2(55,-10)]
        elif kind=="village":offsets=[Vector2(-135,55),Vector2(0,45),Vector2(135,55)]
        for offset in offsets:
            details.append(Rock.recover(at+offset,obstacles,CLEARANCE,safe_bounds))
        profile["points"]=details
        result.append(profile)
    return result
