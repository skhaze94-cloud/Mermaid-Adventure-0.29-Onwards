extends RefCounted
const SHADER=preload("res://godot/shaders/character_details.gdshader")
# Fin/tentacle/ear region, independently phased shell or secondary appendage,
# protected face. Coordinates were reviewed against the actual paintings.
const ZONES={
 "coda":[Vector4(.24,.76,.22,.23),Vector4(.83,.35,.14,.18),Vector4(.57,.24,.30,.20)],
 "folio":[Vector4(.52,.82,.40,.16),Vector4(.31,.37,.27,.37),Vector4(.70,.32,.23,.20)],
 "luma":[Vector4(.47,.80,.40,.20),Vector4(.48,.13,.36,.16),Vector4(.50,.35,.29,.20)],
 "pipette":[Vector4(.16,.51,.15,.30),Vector4(.30,.78,.20,.25),Vector4(.63,.36,.25,.25)],
 "tango":[Vector4(.86,.28,.14,.24),Vector4(.29,.32,.25,.28),Vector4(.56,.44,.27,.23)],
 "rill":[Vector4(.20,.66,.20,.25),Vector4(.35,.20,.25,.18),Vector4(.72,.38,.25,.22)],
 "vesper":[Vector4(.30,.80,.29,.22),Vector4(.24,.28,.18,.18),Vector4(.68,.27,.25,.18)],
 "saffron":[Vector4(.32,.72,.27,.26),Vector4(.30,.34,.20,.22),Vector4(.63,.28,.23,.18)],
 "dot":[Vector4(.34,.75,.26,.23),Vector4(.25,.39,.18,.22),Vector4(.57,.32,.25,.20)],
 "peep":[Vector4(.18,.58,.16,.27),Vector4(.48,.85,.22,.13),Vector4(.67,.38,.25,.21)],
 "button":[Vector4(.28,.79,.26,.20),Vector4(.20,.28,.18,.18),Vector4(.57,.34,.26,.20)],
 "crumb":[Vector4(.32,.80,.26,.19),Vector4(.19,.48,.18,.26),Vector4(.52,.38,.23,.20)],
 "oona":[Vector4(.24,.82,.22,.18),Vector4(.31,.45,.17,.25),Vector4(.63,.35,.25,.22)],
 "bibi":[Vector4(.22,.47,.19,.36),Vector4(.42,.82,.20,.17),Vector4(.57,.43,.22,.22)],
 "ludo":[Vector4(.32,.82,.29,.16),Vector4(.20,.45,.17,.26),Vector4(.64,.40,.25,.21)],
 "miri":[Vector4(.45,.83,.35,.17),Vector4(.17,.47,.15,.23),Vector4(.49,.34,.22,.23)],
 "mallow":[Vector4(.72,.18,.26,.22),Vector4(.32,.48,.28,.3),Vector4(.77,.47,.21,.19)],
 "tilly":[Vector4(.39,.77,.4,.23),Vector4(.29,.47,.22,.25),Vector4(.68,.34,.25,.24)],
 "posy":[Vector4(.59,.23,.28,.19),Vector4(.30,.40,.27,.28),Vector4(.64,.48,.25,.20)],
 "purl":[Vector4(.63,.82,.32,.22),Vector4(.28,.43,.20,.30),Vector4(.65,.3,.25,.22)],
 "hush":[Vector4(.5,.78,.4,.24),Vector4(.26,.44,.24,.20),Vector4(.52,.30,.25,.18)],
 "thimble":[Vector4(.65,.81,.35,.18),Vector4(.29,.43,.26,.33),Vector4(.68,.39,.19,.20)],
 "shy-fish":[Vector4(.78,.48,.23,.36),Vector4(.45,.20,.20,.16),Vector4(.29,.46,.25,.27)],
 "moonfish":[Vector4(.19,.51,.18,.28),Vector4(.43,.85,.20,.13),Vector4(.66,.44,.30,.26)],
 "dozy":[Vector4(.61,.8,.28,.19),Vector4(.19,.25,.17,.23),Vector4(.64,.42,.26,.22)]}
static func surface(id: String,texture: Texture2D=null) -> ShaderMaterial:
 var m:=ShaderMaterial.new();m.shader=SHADER
 var zones: Array=ZONES.get(id,[Vector4(.3,.77,.3,.23),Vector4(.23,.35,.20,.23),Vector4(.65,.32,.26,.23)])
 m.set_shader_parameter("fin_zone",zones[0]);m.set_shader_parameter("shell_zone",zones[1]);m.set_shader_parameter("face_zone",zones[2]);m.set_shader_parameter("detail_seed",float(absi(id.hash())%997)/101)
 if texture is AtlasTexture:
  var size: Vector2=texture.atlas.get_size();var area: Rect2=texture.region
  m.set_shader_parameter("bounds",Vector4(area.position.x/size.x,area.position.y/size.y,area.size.x/size.x,area.size.y/size.y))
 return m
static func update(m: ShaderMaterial,time: float,still: bool) -> void:
 m.set_shader_parameter("detail_clock",time);m.set_shader_parameter("detail_strength",0.0 if still else 1.0)
