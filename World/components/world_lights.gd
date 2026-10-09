## Le luci del teatro: lampioni, riflettori, la porta EXIT.
##
## Ogni mappa ha un [CanvasModulate] che la scurisce (la palette della zona) e
## le luci ci bucano dentro. Il risultato e' il teatro: buio in sala, luce dove
## qualcuno deve essere guardato.
class_name WorldLights extends RefCounted


static var _texture: GradientTexture2D = null


## Una luce morbida e tonda.
## [param radius] e' in mattonelle (32 pixel).
static func make_light(color: Color, energy: float, radius: float) -> PointLight2D:
	var light: PointLight2D = PointLight2D.new()
	light.texture = _glow()
	light.color = color
	light.energy = energy
	light.texture_scale = radius * 32.0 / 128.0
	light.blend_mode = Light2D.BLEND_MODE_ADD
	return light


## La texture condivisa: un disco che sfuma, 256x256.
static func _glow() -> GradientTexture2D:
	if _texture != null:
		return _texture
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	gradient.add_point(0.45, Color(1, 1, 1, 0.55))
	_texture = GradientTexture2D.new()
	_texture.gradient = gradient
	_texture.fill = GradientTexture2D.FILL_RADIAL
	_texture.fill_from = Vector2(0.5, 0.5)
	_texture.fill_to = Vector2(1.0, 0.5)
	_texture.width = 256
	_texture.height = 256
	return _texture
