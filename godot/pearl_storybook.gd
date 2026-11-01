extends RefCounted
## Shared storybook presentation. Game rules and input routing stay with their owners.
const INK=Color('#173e4b')
const MUTED=Color('#496b70')
const IVORY=Color('#fff4dc')
const PAPER=Color('#fff9ee')
const SEAFOAM=Color('#83bdb0')
const MINT=Color('#bce7d7')
const GOLD=Color('#c99953')
const ROSE=Color('#c7567d')
const FONT=preload('res://dist/fonts/story-serif.ttf')
const BOLD=preload('res://dist/fonts/story-serif-bold.ttf')
const ATLAS=preload('res://godot/assets/pearl38/charms.png')
const CELLS={'heart':Vector2i(0,0),'empty_heart':Vector2i(1,0),'bubble':Vector2i(2,0),'boost':Vector2i(3,0),'jump':Vector2i(0,1),'pearl':Vector2i(1,1),'shell':Vector2i(2,1),'slug':Vector2i(3,1)}
static var textures: Dictionary={}
static var shared_theme: Theme
static func texture(name: String) -> Texture2D:
    if not textures.has(name):
        var t:=AtlasTexture.new();t.atlas=ATLAS
        var tile:=Vector2(ATLAS.get_size())/Vector2(4,2)
        t.region=Rect2(Vector2(CELLS.get(name,Vector2i(2,1)))*tile,tile);t.filter_clip=true
        textures[name]=t
    return textures[name]
static func icon(name: String,size:=Vector2(36,36)) -> TextureRect:
    var node:=TextureRect.new();node.texture=texture(name);node.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    node.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;node.custom_minimum_size=size;node.mouse_filter=Control.MOUSE_FILTER_IGNORE
    return node
static func panel(fill:=IVORY,edge:=SEAFOAM,radius:=20,margin:=14) -> StyleBoxFlat:
    var s:=StyleBoxFlat.new();s.bg_color=fill;s.border_color=edge;s.set_border_width_all(1);s.set_corner_radius_all(radius)
    s.shadow_color=Color(.015,.08,.10,.22);s.shadow_size=5;s.shadow_offset=Vector2(0,3);s.set_content_margin_all(margin)
    return s
static func theme() -> Theme:
    if shared_theme:return shared_theme
    var body_font: FontFile=FONT;var bold_font: FontFile=BOLD
    body_font.multichannel_signed_distance_field=true;bold_font.multichannel_signed_distance_field=true
    var t:=Theme.new();t.default_font=FONT;t.default_font_size=20
    t.set_color('font_color','Label',INK)
    for state in ['font_color','font_hover_color','font_pressed_color','font_focus_color']:t.set_color(state,'Button',INK)
    t.set_color('font_disabled_color','Button',MUTED)
    t.set_stylebox('normal','Button',panel(PAPER,SEAFOAM,16,12))
    t.set_stylebox('hover','Button',panel(MINT,SEAFOAM,16,12))
    t.set_stylebox('pressed','Button',panel(Color('#d3e8cf'),GOLD,16,12))
    var focus:=panel(Color(0,0,0,0),INK,16,0);focus.set_border_width_all(3);focus.shadow_size=0
    t.set_stylebox('focus','Button',focus)
    t.set_stylebox('disabled','Button',panel(Color('#ede6d4'),Color('#c5c9ba'),16,12))
    for name in ['background','fill']:
        var meter:=panel(Color('#d7e8de') if name=='background' else Color('#43b7ad'),SEAFOAM,6,0);meter.shadow_size=0
        t.set_stylebox(name,'ProgressBar',meter)
    shared_theme=t;return t
static func label(text: String,size:=20,tint:=INK) -> Label:
    var node:=Label.new();node.text=text;node.add_theme_font_override('font',FONT);node.add_theme_font_size_override('font_size',size);node.add_theme_color_override('font_color',tint)
    node.add_theme_color_override('font_shadow_color',Color.TRANSPARENT);node.mouse_filter=Control.MOUSE_FILTER_IGNORE
    return node
static func button(node: Button,primary:=false) -> void:
    node.theme=theme();node.add_theme_font_override('font',BOLD);node.add_theme_font_size_override('font_size',18)
    for state in ['font_color','font_hover_color','font_pressed_color','font_focus_color']:node.add_theme_color_override(state,INK)
    node.add_theme_color_override('font_shadow_color',Color.TRANSPARENT)
    if primary:node.add_theme_stylebox_override('normal',panel(MINT,SEAFOAM,16,12))
static func caption(box: PanelContainer,text: Label) -> void:
    box.add_theme_stylebox_override('panel',panel(IVORY,SEAFOAM,18,12))
    text.add_theme_color_override('font_color',INK);text.add_theme_color_override('font_shadow_color',Color.TRANSPARENT)
