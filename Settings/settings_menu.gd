## La schermata delle impostazioni.
##
## [b]Non va aperta a mano:[/b] usa [code]Settings.open_menu()[/code], che la
## mette sopra a tutto (anche a gioco in pausa) e la toglie quando si chiude.
##
## [b]Si costruisce da sola[/b] leggendo [SettingsSchema]: per aggiungere una
## voce non si tocca questo file. Ogni controllo scrive in [Settings] appena lo
## muovi, quindi i cambiamenti si vedono subito (anche il menu dietro cambia
## colore mentre scegli) e si salvano da soli.
##
## L'aspetto viene tutto dal [Theme] globale costruito da [UiThemeBuilder]:
## qui ci sono solo misure, nessun colore.
class_name SettingsMenu extends Control


## Emesso quando il giocatore chiude la schermata.
signal closed()


var _schema: Array = []
var _tabs: TabContainer
var _panel: PanelContainer
var _controls: Dictionary = {}          # "sezione/chiave" -> Control
var _binding_buttons: Dictionary = {}   # azione -> Button
var _waiting_action: StringName = &""
var _reset_all_button: Button
var _reset_all_armed: bool = false
var _closing: bool = false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS

	_schema = SettingsSchema.tabs()
	_build()

	Settings.changed.connect(_on_setting_changed)
	Settings.controls_changed.connect(_refresh_bindings)
	_pop_in()


#region Costruzione


func _build() -> void:
	var veil: ColorRect = ColorRect.new()
	veil.color = Color(0, 0, 0, 0.72)
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_panel = PanelContainer.new()
	# Grande, ma mai piu' grande dello schermo (anche con la scala interfaccia alta).
	var screen: Vector2 = get_viewport_rect().size
	_panel.custom_minimum_size = Vector2(minf(1320.0, screen.x * 0.94), minf(860.0, screen.y * 0.92))
	center.add_child(_panel)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	_panel.add_child(column)

	var title: Label = Label.new()
	title.theme_type_variation = &"TitleLabel"
	title.text = "Impostazioni"
	column.add_child(title)

	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_tabs)

	for tab: Dictionary in _schema:
		var page: Control = _build_tab(tab)
		_tabs.add_child(page)
		_tabs.set_tab_title(_tabs.get_tab_count() - 1, tab["title"])

	column.add_child(_build_footer())


func _build_tab(tab: Dictionary) -> Control:
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.name = str(tab["title"]).validate_node_name()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	var margin: MarginContainer = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	scroll.add_child(margin)

	var list: VBoxContainer = VBoxContainer.new()
	list.add_theme_constant_override("separation", 14)
	margin.add_child(list)

	var section: String = tab["section"]
	for item: Dictionary in tab["items"]:
		list.add_child(_build_item(section, item))
	return scroll


func _build_item(section: String, item: Dictionary) -> Control:
	var type: String = item["type"]
	match type:
		"header":
			var box: VBoxContainer = VBoxContainer.new()
			box.add_child(HSeparator.new())
			var header: Label = Label.new()
			header.theme_type_variation = &"SectionLabel"
			header.text = item["label"]
			box.add_child(header)
			return box
		"bindings":
			return _build_bindings(item)

	var key: String = item.get("key", "")
	var control: Control
	match type:
		"slider":
			control = _make_slider(section, key, item)
		"toggle":
			control = _make_toggle(section, key)
		"choice":
			control = _make_choice(section, key, item["options"])
		"preset":
			control = _make_preset()
		"color":
			control = _make_color(section, key)
		"palette":
			control = _make_palette(section, key)
		"text":
			control = _make_text(section, key, item)
		_:
			push_warning("SettingsMenu: tipo sconosciuto '%s'" % type)
			control = Control.new()

	_controls["%s/%s" % [section, key]] = control
	_refresh_control(section, key)
	return _row(item["label"], item.get("hint", ""), control)


## Una riga: nome (e spiegazione) a sinistra, controllo a destra.
func _row(label_text: String, hint: String, control: Control) -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)

	var texts: VBoxContainer = VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_theme_constant_override("separation", 0)
	row.add_child(texts)

	var label: Label = Label.new()
	label.text = label_text
	texts.add_child(label)

	if not hint.is_empty():
		var hint_label: Label = Label.new()
		hint_label.theme_type_variation = &"DimLabel"
		hint_label.text = hint
		hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint_label.add_theme_font_size_override("font_size", Settings.font_size(23))
		texts.add_child(hint_label)

	var holder: HBoxContainer = HBoxContainer.new()
	holder.custom_minimum_size = Vector2(540.0, 0.0)
	holder.alignment = BoxContainer.ALIGNMENT_END
	control.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	holder.add_child(control)
	row.add_child(holder)
	return row


func _build_footer() -> Control:
	var footer: HBoxContainer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", 16)

	var reset_tab: Button = Button.new()
	reset_tab.text = "Ripristina scheda"
	reset_tab.pressed.connect(_on_reset_tab)
	footer.add_child(reset_tab)

	# "Ripristina tutto" chiede un secondo click: e' facile premerlo per sbaglio.
	_reset_all_button = Button.new()
	_reset_all_button.text = "Ripristina tutto"
	_reset_all_button.pressed.connect(_on_reset_all)
	_reset_all_button.mouse_exited.connect(_disarm_reset_all)
	footer.add_child(_reset_all_button)

	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)

	var saved: Label = Label.new()
	saved.theme_type_variation = &"DimLabel"
	saved.text = "Le modifiche si salvano da sole"
	saved.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	footer.add_child(saved)

	var close_button: Button = Button.new()
	close_button.text = "Chiudi"
	close_button.custom_minimum_size = Vector2(200.0, 0.0)
	close_button.pressed.connect(close)
	footer.add_child(close_button)
	close_button.call_deferred("grab_focus")
	return footer


#endregion

#region Controlli


func _make_slider(section: String, key: String, item: Dictionary) -> Control:
	var box: HBoxContainer = HBoxContainer.new()
	box.add_theme_constant_override("separation", 14)

	var slider: HSlider = HSlider.new()
	slider.min_value = item.get("min", 0.0)
	slider.max_value = item.get("max", 1.0)
	slider.step = item.get("step", 0.05)
	slider.custom_minimum_size = Vector2(320.0, 32.0)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(slider)

	var value_label: Label = Label.new()
	value_label.custom_minimum_size = Vector2(120.0, 0.0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	box.add_child(value_label)

	var format: String = item.get("format", "number")
	slider.set_meta("value_label", value_label)
	slider.set_meta("format", format)

	var is_int: bool = Settings.get_default(section, key) is int
	slider.value_changed.connect(func(value: float) -> void:
		value_label.text = _format_value(value, format, slider.step)
		Settings.set_value(section, key, int(round(value)) if is_int else value)
	)
	# Il contenitore e' quello che va nella riga, ma i valori li legge lo slider.
	box.set_meta("slider", slider)
	return box


func _make_toggle(section: String, key: String) -> Control:
	var toggle: CheckButton = CheckButton.new()
	toggle.toggled.connect(func(on: bool) -> void: Settings.set_value(section, key, on))
	return toggle


func _make_choice(section: String, key: String, options: Array) -> Control:
	var choice: OptionButton = OptionButton.new()
	choice.custom_minimum_size = Vector2(340.0, 0.0)
	for option: Array in options:
		choice.add_item(str(option[1]))
		choice.set_item_metadata(choice.item_count - 1, option[0])
	choice.item_selected.connect(func(index: int) -> void:
		Settings.set_value(section, key, choice.get_item_metadata(index))
	)
	return choice


func _make_preset() -> Control:
	var choice: OptionButton = OptionButton.new()
	choice.custom_minimum_size = Vector2(340.0, 0.0)
	for option: Array in ThemePresets.choices():
		choice.add_item(str(option[1]))
		choice.set_item_metadata(choice.item_count - 1, option[0])
	choice.item_selected.connect(func(index: int) -> void:
		Settings.apply_theme_preset(str(choice.get_item_metadata(index)))
	)
	return choice


func _make_color(section: String, key: String) -> Control:
	var picker: ColorPickerButton = ColorPickerButton.new()
	picker.custom_minimum_size = Vector2(140.0, 44.0)
	picker.edit_alpha = false
	picker.color_changed.connect(func(value: Color) -> void: Settings.set_value(section, key, value))
	return picker


func _make_palette(section: String, key: String) -> Control:
	var grid: GridContainer = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	for i: int in 8:
		var picker: ColorPickerButton = ColorPickerButton.new()
		picker.custom_minimum_size = Vector2(72.0, 40.0)
		picker.edit_alpha = false
		picker.color_changed.connect(func(value: Color) -> void:
			var colors: Array = (Settings.get_value(section, key, []) as Array).duplicate()
			while colors.size() < 8:
				colors.append(Settings.color("accent"))
			colors[i] = value
			Settings.set_value(section, key, colors)
		)
		grid.add_child(picker)
	return grid


func _make_text(section: String, key: String, item: Dictionary) -> Control:
	var field: LineEdit = LineEdit.new()
	field.custom_minimum_size = Vector2(360.0, 0.0)
	field.placeholder_text = item.get("placeholder", "")
	field.text_changed.connect(func(value: String) -> void: Settings.set_value(section, key, value))
	return field


## I comandi: una riga per azione, con il tasto attuale. Cliccandolo aspetta
## il tasto nuovo.
func _build_bindings(item: Dictionary) -> Control:
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)

	var hint: Label = Label.new()
	hint.theme_type_variation = &"DimLabel"
	hint.text = item.get("label", "")
	box.add_child(hint)

	for action: StringName in Settings.rebindable_actions():
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(280.0, 0.0)
		button.pressed.connect(_start_rebind.bind(action))
		_binding_buttons[action] = button
		box.add_child(_row(Settings.action_label(action), "", button))

	_refresh_bindings()
	return box


#endregion

#region Aggiornare i controlli


## Rimette nel controllo il valore attuale, senza far ripartire i suoi segnali
## (altrimenti ogni aggiornamento riscriverebbe l'impostazione).
func _refresh_control(section: String, key: String) -> void:
	var control: Control = _controls.get("%s/%s" % [section, key])
	if control == null:
		return
	var value: Variant = Settings.get_value(section, key)

	if control.has_meta("slider"):
		var slider: HSlider = control.get_meta("slider")
		slider.set_value_no_signal(float(value))
		var label: Label = slider.get_meta("value_label")
		label.text = _format_value(float(value), slider.get_meta("format"), slider.step)
	elif control is CheckButton:
		(control as CheckButton).set_pressed_no_signal(bool(value))
	elif control is OptionButton:
		var choice: OptionButton = control
		for i: int in choice.item_count:
			if _equal(choice.get_item_metadata(i), value):
				choice.select(i)
				break
	elif control is ColorPickerButton:
		(control as ColorPickerButton).color = value
	elif control is GridContainer:
		var colors: Array = value if value is Array else []
		for i: int in control.get_child_count():
			if i < colors.size():
				(control.get_child(i) as ColorPickerButton).color = colors[i]
	elif control is LineEdit:
		var field: LineEdit = control
		if not field.has_focus() and field.text != str(value):
			field.text = str(value)


func _on_setting_changed(section: String, key: String, _value: Variant) -> void:
	_refresh_control(section, key)


func _refresh_bindings() -> void:
	for action: StringName in _binding_buttons:
		var button: Button = _binding_buttons[action]
		button.text = "Premi un tasto…" if action == _waiting_action else Settings.binding_text(action)


func _format_value(value: float, format: String, step: float) -> String:
	match format:
		"percent":
			return "%d%%" % roundi(value * 100.0)
		"times":
			return "%.2f×" % value
	return str(roundi(value)) if step >= 1.0 else "%.1f" % value


func _equal(a: Variant, b: Variant) -> bool:
	if typeof(a) in [TYPE_INT, TYPE_FLOAT] and typeof(b) in [TYPE_INT, TYPE_FLOAT]:
		return is_equal_approx(float(a), float(b))
	return str(a) == str(b)


#endregion

#region Comandi e tastiera


func _start_rebind(action: StringName) -> void:
	_waiting_action = action
	_refresh_bindings()


## Mentre aspetta un tasto nuovo, prende il primo tasto o click del mouse.
## Esc annulla. Fuori da quel momento, Esc chiude la schermata.
func _input(event: InputEvent) -> void:
	if _waiting_action == &"":
		return

	var key: InputEventKey = event as InputEventKey
	var mouse: InputEventMouseButton = event as InputEventMouseButton
	var picked: InputEvent = null

	if key != null and key.pressed and not key.echo:
		if key.keycode != KEY_ESCAPE:
			picked = key
	elif mouse != null and mouse.pressed:
		if mouse.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT]:
			return
		picked = mouse
	else:
		return

	var action: StringName = _waiting_action
	_waiting_action = &""
	if picked != null:
		Settings.rebind(action, picked)
	_refresh_bindings()
	get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		close()
	# Finche' la schermata e' aperta, sotto non arriva niente.
	if event is InputEventKey or event is InputEventMouseButton:
		get_viewport().set_input_as_handled()


func _on_reset_tab() -> void:
	var tab: Dictionary = _schema[_tabs.current_tab]
	Settings.reset_section(tab["section"])


func _on_reset_all() -> void:
	if not _reset_all_armed:
		_reset_all_armed = true
		_reset_all_button.text = "Sicuro? Clicca ancora"
		return
	_disarm_reset_all()
	Settings.reset_all()


func _disarm_reset_all() -> void:
	_reset_all_armed = false
	_reset_all_button.text = "Ripristina tutto"


#endregion

#region Apertura e chiusura


func _pop_in() -> void:
	var speed: float = Settings.motion_scale()
	_panel.pivot_offset = _panel.custom_minimum_size * 0.5
	modulate.a = 0.0
	_panel.scale = Vector2.ONE * 0.94
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.18 * speed)
	tween.tween_property(_panel, "scale", Vector2.ONE, 0.25 * speed) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Chiude la schermata (le impostazioni sono gia' salvate).
func close() -> void:
	if _closing:
		return
	_closing = true
	_waiting_action = &""
	closed.emit()

	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.15 * Settings.motion_scale())
	tween.tween_callback(queue_free)


#endregion
