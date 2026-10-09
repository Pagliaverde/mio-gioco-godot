## Le transizioni tra mappe e battaglie: il nero tra una stanza e l'altra e il
## "lampo" che annuncia una scena, come nei giochi di mostri tascabili.
##
## [b]E' un autoload[/b] ([code]Transition[/code]): sta sopra a tutto il mondo e
## ai dialoghi (100), sotto la pausa (110) e le impostazioni (120).
##
## [codeblock]
## await Transition.fade_out()        # lo schermo diventa nero
## ... cambia mappa ...
## await Transition.fade_in()         # e torna
##
## await Transition.battle_in(true)   # lampi + sipario a strisce (true = boss)
## ... prepara la battaglia sotto ...
## await Transition.fade_in()
## [/codeblock]
##
## Con [i]Riduci animazioni[/i] (Impostazioni → Accessibilita') resta solo una
## dissolvenza breve, senza lampi.
extends CanvasLayer


## Il livello del velo: sopra il mondo e i dialoghi, sotto la pausa.
const LAYER := 105

## Quante strisce chiudono lo schermo prima di una battaglia.
const STRIPES := 8

## Se true le transizioni durano zero (serve ai controlli senza finestra).
var instant: bool = false

var _veil: ColorRect
var _flash: ColorRect
var _stripes: Control
var _tween: Tween = null


func _ready() -> void:
	layer = LAYER

	_veil = ColorRect.new()
	_veil.color = Color(0, 0, 0, 0)
	_veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_veil)

	_stripes = Control.new()
	_stripes.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stripes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stripes)

	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)


## True se lo schermo e' coperto (o si sta coprendo).
func is_covered() -> bool:
	return _veil.color.a > 0.5


## Lo schermo diventa nero.
func fade_out(seconds: float = 0.3) -> void:
	_kill()
	_veil.mouse_filter = Control.MOUSE_FILTER_STOP
	_tween = create_tween()
	_tween.tween_property(_veil, "color:a", 1.0, _time(seconds))
	await _tween.finished


## Il nero se ne va.
func fade_in(seconds: float = 0.35) -> void:
	_kill()
	_clear_stripes()
	_tween = create_tween()
	_tween.tween_property(_veil, "color:a", 0.0, _time(seconds))
	await _tween.finished
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE


## L'annuncio di una scena: due lampi, poi strisce nere che si chiudono da
## destra e da sinistra, alternate. Finisce con lo schermo nero.
##
## [param boss] fa i lampi rossi e un po' piu' lenti: con un boss ci si ferma.
func battle_in(boss: bool = false) -> void:
	_kill()
	_veil.mouse_filter = Control.MOUSE_FILTER_STOP
	if Settings.reduce_motion() or instant:
		await fade_out(0.2)
		return

	var flash_color: Color = Color(0.85, 0.15, 0.2) if boss else Color(1, 1, 1)
	var flash_time: float = 0.11 if boss else 0.08
	_flash.color = Color(flash_color, 0.0)
	_tween = create_tween()
	for i: int in 2:
		_tween.tween_property(_flash, "color:a", 0.85, flash_time)
		_tween.tween_property(_flash, "color:a", 0.0, flash_time)
	await _tween.finished

	_clear_stripes()
	var size: Vector2 = _stripes.get_viewport_rect().size
	var height: float = ceilf(size.y / float(STRIPES))
	_tween = create_tween()
	_tween.set_parallel(true)
	for i: int in STRIPES:
		var stripe: ColorRect = ColorRect.new()
		stripe.color = Color.BLACK
		stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stripe.size = Vector2(size.x, height + 1.0)
		var from_left: bool = i % 2 == 0
		stripe.position = Vector2(-size.x if from_left else size.x, height * i)
		_stripes.add_child(stripe)
		_tween.tween_property(stripe, "position:x", 0.0, 0.42) \
			.set_delay(0.035 * i).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await _tween.finished
	_veil.color.a = 1.0
	_clear_stripes()


func _time(seconds: float) -> float:
	return 0.0 if instant else seconds * Settings.motion_scale()


func _kill() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null


func _clear_stripes() -> void:
	for child: Node in _stripes.get_children():
		child.queue_free()
