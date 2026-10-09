## La HUD del mondo: il cartello della zona quando entri, e in alto a destra
## vita, biglietti, gavetta e maschera indossata. In basso, i tasti.
##
## Si aggiorna da sola quando [code]GameState[/code] emette [code]changed[/code].
class_name WorldHud extends CanvasLayer


var _zone_panel: PanelContainer
var _zone_title: Label
var _zone_subtitle: Label
var _hp_bar: ProgressBar
var _hp_text: Label
var _money: Label
var _level: Label
var _mask: Label
var _hint: Label
var _zone_tween: Tween = null


func _ready() -> void:
	layer = 10
	var root: Control = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# --- Il cartello della zona (in alto a sinistra) ---
	_zone_panel = PanelContainer.new()
	_zone_panel.theme_type_variation = &"CardPanel"
	_zone_panel.position = Vector2(32, 28)
	_zone_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_zone_panel.modulate.a = 0.0
	root.add_child(_zone_panel)
	var zone_box: VBoxContainer = VBoxContainer.new()
	_zone_panel.add_child(zone_box)
	_zone_title = Label.new()
	_zone_title.add_theme_font_size_override("font_size", Settings.font_size(40))
	_zone_title.add_theme_color_override("font_color", Settings.color("ink"))
	zone_box.add_child(_zone_title)
	_zone_subtitle = Label.new()
	_zone_subtitle.add_theme_font_size_override("font_size", Settings.font_size(22))
	_zone_subtitle.add_theme_color_override("font_color", Settings.color("ink").lerp(Color(0.5, 0.5, 0.5), 0.4))
	zone_box.add_child(_zone_subtitle)

	# --- Lo stato (in alto a destra) ---
	var status: PanelContainer = PanelContainer.new()
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	status.position = Vector2(-372, 24)
	status.custom_minimum_size = Vector2(340, 0)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.04, 0.09, 0.78)
	style.border_color = Color(0.79, 0.64, 0.29, 0.9)
	style.set_border_width_all(3)
	style.set_content_margin_all(14)
	style.anti_aliasing = false
	status.add_theme_stylebox_override("panel", style)
	root.add_child(status)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	status.add_child(column)

	_level = _label(column, 22, Color(1, 0.88, 0.55))
	_hp_bar = ProgressBar.new()
	_hp_bar.show_percentage = false
	_hp_bar.custom_minimum_size = Vector2(0, 18)
	var fill: StyleBoxFlat = StyleBoxFlat.new()
	fill.bg_color = Color("b8384a")
	fill.anti_aliasing = false
	_hp_bar.add_theme_stylebox_override("fill", fill)
	var track: StyleBoxFlat = StyleBoxFlat.new()
	track.bg_color = Color(0, 0, 0, 0.6)
	track.anti_aliasing = false
	_hp_bar.add_theme_stylebox_override("background", track)
	column.add_child(_hp_bar)
	_hp_text = _label(column, 20, Color(0.95, 0.92, 0.9))
	_money = _label(column, 22, Color(0.98, 0.85, 0.45))
	_mask = _label(column, 20, Color(0.8, 0.78, 0.95))

	# --- I tasti (in basso a sinistra) ---
	_hint = Label.new()
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_hint.position = Vector2(28, -48)
	_hint.add_theme_font_size_override("font_size", Settings.font_size(20))
	_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.65))
	_hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_hint.add_theme_constant_override("outline_size", 6)
	_hint.text = "WASD muoviti · Maiusc corri · E interagisci · I inventario · Esc pausa"
	root.add_child(_hint)

	GameState.changed.connect(refresh)
	refresh()


func _label(parent: Node, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.add_theme_font_size_override("font_size", Settings.font_size(font_size))
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


## Aggiorna i numeri.
func refresh() -> void:
	_level.text = StoryWords.level_name(GameState.level)
	_hp_bar.max_value = GameState.max_hp
	_hp_bar.value = GameState.hp
	_hp_text.text = "Vita %d / %d" % [GameState.hp, GameState.max_hp]
	_money.text = "%d %s" % [GameState.money, WorldData.MONEY_NAME]
	var worn: MaskData = GameState.worn_mask_data()
	_mask.text = "Indossi: %s" % (worn.display_name if worn != null else "nessuna maschera")


## Il cartello della zona: compare, resta un attimo, se ne va.
func show_zone(title: String, subtitle: String) -> void:
	_zone_title.text = title
	_zone_subtitle.text = subtitle
	if _zone_tween != null and _zone_tween.is_valid():
		_zone_tween.kill()
	_zone_panel.position = Vector2(32, 0)
	_zone_tween = create_tween()
	_zone_tween.set_parallel(true)
	_zone_tween.tween_property(_zone_panel, "modulate:a", 1.0, 0.35 * Settings.motion_scale())
	_zone_tween.tween_property(_zone_panel, "position:y", 28.0, 0.35 * Settings.motion_scale()).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_zone_tween.chain().tween_interval(2.6)
	_zone_tween.chain().tween_property(_zone_panel, "modulate:a", 0.0, 0.6 * Settings.motion_scale())


## Nasconde tutto (durante le battaglie).
func set_shown(value: bool) -> void:
	visible = value
