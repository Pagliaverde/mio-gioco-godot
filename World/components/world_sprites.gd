## Gli sprite dei personaggi del mondo, costruiti dai fogli che ci sono gia'.
##
## I personaggi disegnati per il gioco ([code]Asset/Sprite/MySprite/MyCharacter[/code])
## seguono la convenzione [code]<animazione>_<direzione>-Sheet.png[/code], con
## fotogrammi da 64x64 in fila: [code]idle_front[/code], [code]run_right[/code]...
## Da qui escono gli [SpriteFrames] per il protagonista dei boss, i manichini e
## chiunque altro usi lo stesso set, senza rifare a mano l'atlante in ogni scena.
class_name WorldSprites extends RefCounted


## Il set del protagonista (MC2): faccia vuota, come il protagonista.
const MC_FOLDER := "res://Asset/Sprite/MySprite/MyCharacter/MC/MC2"

## Il set dei manichini.
const MANNEQUIN_FOLDER := "res://Asset/Sprite/MySprite/MyCharacter/Manichino"

## Lato di un fotogramma.
const FRAME := 64

static var _cache: Dictionary = {}


## Gli [SpriteFrames] di un set: tutte le animazioni che trova tra
## idle/run/pick per front/back/right.
static func frames(folder: String) -> SpriteFrames:
	if _cache.has(folder):
		return _cache[folder]
	var out: SpriteFrames = SpriteFrames.new()
	out.remove_animation(&"default")
	for prefix: String in ["idle", "run", "pick"]:
		for direction: String in ["front", "back", "right"]:
			var path: String = "%s/%s_%s-Sheet.png" % [folder, prefix, direction]
			if not ResourceLoader.exists(path):
				continue
			var sheet: Texture2D = load(path)
			var animation: StringName = StringName("%s_%s" % [prefix, direction])
			out.add_animation(animation)
			out.set_animation_loop(animation, prefix != "pick")
			out.set_animation_speed(animation, {"idle": 3.0, "run": 10.0, "pick": 16.0}[prefix])
			for i: int in sheet.get_width() / FRAME:
				var atlas: AtlasTexture = AtlasTexture.new()
				atlas.atlas = sheet
				atlas.region = Rect2(i * FRAME, 0, FRAME, FRAME)
				out.add_frame(animation, atlas)
	_cache[folder] = out
	return out


## Il suffisso di direzione per un vettore (front/back/right) e se va specchiato.
static func direction_of(dir: Vector2) -> Array:
	if absf(dir.x) > absf(dir.y):
		return ["right", dir.x < 0.0]
	return ["back" if dir.y < 0.0 else "front", false]


## Fa partire [code]prefix_direzione[/code] su uno sprite animato.
static func play(sprite: AnimatedSprite2D, prefix: String, dir: Vector2) -> void:
	var info: Array = direction_of(dir)
	var animation: StringName = StringName("%s_%s" % [prefix, info[0]])
	if sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(animation):
		return
	sprite.flip_h = info[1]
	if sprite.animation != animation or not sprite.is_playing():
		sprite.play(animation)
