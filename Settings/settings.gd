## Le impostazioni del gioco. E' un autoload: da qualsiasi script scrivi
## [code]Settings.get_value("audio", "music")[/code] e ottieni il valore.
##
## [b]Cosa fa da solo:[/b] salva tutto in [code]user://settings.cfg[/code] e
## applica ogni cambiamento al momento, a tutto il gioco: volume dei bus audio,
## finestra, vsync, FPS, scala dell'interfaccia, lingua, filtri colore e
## daltonismo, comandi rimappati e il [Theme] globale dell'interfaccia.
##
## [b]Per il resto del gioco:[/b]
## [br]- leggi un valore: [method get_value] (o le scorciatoie come [method color]);
## [br]- reagisci ai cambiamenti: [signal changed], [signal theme_changed],
##   [signal controls_changed];
## [br]- aggiungi un'impostazione tua: [method register], poi se vuoi vederla
##   nella schermata aggiungila a [SettingsSchema];
## [br]- apri la schermata delle impostazioni (es. dal menu di pausa):
##   [method open_menu].
##
## Vedi [code]Settings/README.md[/code] per esempi.
extends Node


## Emesso dopo che un'impostazione e' cambiata (ed e' gia' stata applicata).
signal changed(section: String, key: String, value: Variant)

## Emesso quando cambia l'aspetto (colori, font, dimensione del testo...).
## Arriva una volta sola anche se cambiano tanti valori insieme.
signal theme_changed()

## Emesso quando un comando viene rimappato o i comandi vengono ripristinati.
signal controls_changed()

## Emesso quando la schermata delle impostazioni si apre o si chiude.
signal menu_toggled(is_open: bool)


const SAVE_PATH := "user://settings.cfg"

## La schermata delle impostazioni.
const MENU_SCENE := "res://Settings/settings_menu.tscn"

## I bus audio che il gioco usa, per chiave dell'impostazione.
## Metti i tuoi [AudioStreamPlayer] sul bus giusto (proprieta' [b]Bus[/b]):
## la musica su "Music", gli effetti su "SFX", i suoni dei menu su "UI"...
const BUSES: Dictionary = {
	"master": &"Master",
	"music": &"Music",
	"sfx": &"SFX",
	"ui": &"UI",
	"voice": &"Voice",
}

## Le chiavi del tema che fanno parte di un preset: se il giocatore ne cambia
## una a mano, il preset diventa "Personalizzato".
const PRESET_KEYS: Array[String] = ["background", "panel", "text", "accent", "paper", "ink", "palette"]

## Le impostazioni che cambiano l'aspetto (oltre a tutta la sezione "theme").
const LOOK_KEYS: Array[String] = ["accessibility/text_scale", "accessibility/high_contrast", "accessibility/reduce_motion"]


var _defaults: Dictionary = {}
var _values: Dictionary = {}
var _config: ConfigFile = ConfigFile.new()
var _default_bindings: Dictionary = {}
var _ui_theme: Theme

var _save_timer: Timer
var _theme_timer: Timer
var _post_rect: ColorRect
var _fps_label: Label
var _focused: bool = true
var _menu_layer: CanvasLayer = null


func _init() -> void:
	_defaults = _build_defaults()


func _ready() -> void:
	# Le impostazioni devono funzionare anche a gioco in pausa (menu di pausa).
	process_mode = Node.PROCESS_MODE_ALWAYS

	_save_timer = _make_timer(0.4, save)
	_theme_timer = _make_timer(0.12, _emit_theme_changed)

	_capture_default_bindings()
	_defaults["controls"] = _serialized_default_bindings()
	_ensure_buses()
	_build_overlay()

	_values = _defaults.duplicate(true)
	load_settings()
	apply_all(true)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_PREDELETE:
			if _save_timer != null and not _save_timer.is_stopped():
				save()
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			_focused = false
			_apply_audio()
		NOTIFICATION_APPLICATION_FOCUS_IN:
			_focused = true
			_apply_audio()


func _process(_delta: float) -> void:
	if _fps_label.visible:
		_fps_label.text = "%d FPS" % Engine.get_frames_per_second()


#region Valori predefiniti


## Tutte le impostazioni con il loro valore di partenza.
##
## [b]Per aggiungere un'impostazione del gioco[/b] puoi scriverla qui, oppure
## (meglio, se e' di una parte del gioco) chiamare [method register] dal suo
## script: cosi' resta vicina al codice che la usa.
func _build_defaults() -> Dictionary:
	var look: Dictionary = ThemePresets.get_preset("pergamena")
	return {
		"audio": {
			"master": 1.0,
			"music": 0.8,
			"sfx": 0.9,
			"ui": 0.8,
			"voice": 1.0,
			"mute": false,
			"mute_unfocused": false,
		},
		"video": {
			"window_mode": "windowed",
			"vsync": true,
			"max_fps": 0,
			"ui_scale": 1.0,
			"brightness": 1.0,
			"contrast": 1.0,
			"saturation": 1.0,
			"show_fps": false,
		},
		"game": {
			"language": "it",
			"difficulty": "normal",
			"text_speed": 1.0,
			"screen_shake": 1.0,
			"auto_save": true,
			"show_tutorials": true,
			"confirm_quit": true,
		},
		"accessibility": {
			"text_scale": 1.0,
			"high_contrast": false,
			"reduce_motion": false,
			"colorblind": "none",
			"subtitles": true,
		},
		"theme": {
			"preset": "pergamena",
			"background": look["background"],
			"panel": look["panel"],
			"text": look["text"],
			"accent": look["accent"],
			"paper": look["paper"],
			"ink": look["ink"],
			"palette": look["palette"],
			"card_wear": 0.6,
			"font": "pixel",
			"animation_speed": 1.0,
			"menu_title": "",
			"menu_subtitle": "Un card game a turni",
			"ambient_cards": false,
			"stack_jitter": 3.0,
			"stack_depth": 5,
		},
		"controls": {},
	}


#endregion

#region Leggere e scrivere


## Il valore di un'impostazione. Se non esiste restituisce [param fallback].
func get_value(section: String, key: String, fallback: Variant = null) -> Variant:
	var values: Dictionary = _values.get(section, {})
	return values.get(key, fallback)


## True se l'impostazione esiste (anche se ha il valore predefinito).
func has_setting(section: String, key: String) -> bool:
	return _values.has(section) and (_values[section] as Dictionary).has(key)


## Il valore predefinito di un'impostazione.
func get_default(section: String, key: String) -> Variant:
	var values: Dictionary = _defaults.get(section, {})
	return values.get(key)


## Cambia un'impostazione: la applica subito, avvisa con [signal changed] e la
## salva su disco poco dopo (cosi' trascinare uno slider non scrive il file
## cento volte).
func set_value(section: String, key: String, value: Variant) -> void:
	if not _values.has(section):
		_values[section] = {}
	var values: Dictionary = _values[section]
	if values.has(key) and _same(values[key], value):
		return

	values[key] = value
	_apply_key(section, key)
	changed.emit(section, key, value)

	# Un colore cambiato a mano: il tema non e' piu' quello del preset.
	if section == "theme" and key in PRESET_KEYS and values.get("preset") != ThemePresets.CUSTOM:
		values["preset"] = ThemePresets.CUSTOM
		changed.emit("theme", "preset", ThemePresets.CUSTOM)

	if section == "theme" or ("%s/%s" % [section, key]) in LOOK_KEYS:
		_theme_timer.start()
	_save_timer.start()


## Aggiunge un'impostazione nuova, per le parti del gioco che ne hanno bisogno.
##
## Se il giocatore l'aveva gia' salvata, ritrova il suo valore. Chiamarla piu'
## volte non fa danni.
## [codeblock]
## func _ready() -> void:
##     Settings.register("gameplay", "camera_zoom", 1.0)
##     var zoom: float = Settings.get_value("gameplay", "camera_zoom")
## [/codeblock]
func register(section: String, key: String, default_value: Variant) -> void:
	if not _defaults.has(section):
		_defaults[section] = {}
	if not _values.has(section):
		_values[section] = {}
	(_defaults[section] as Dictionary)[key] = default_value
	if not (_values[section] as Dictionary).has(key):
		(_values[section] as Dictionary)[key] = _config.get_value(section, key, default_value)


## Rimette ai valori predefiniti una sezione (es. "audio").
func reset_section(section: String) -> void:
	if section == "controls":
		reset_bindings()
		return
	var defaults: Dictionary = _defaults.get(section, {})
	for key: String in defaults:
		# I colori del tema li rimette il preset, qui sotto: rimessi uno per
		# uno segnerebbero il tema come "personalizzato".
		if section == "theme" and (key in PRESET_KEYS or key == "preset"):
			continue
		var value: Variant = defaults[key]
		set_value(section, key, (value as Array).duplicate() if value is Array else value)
	if section == "theme":
		apply_theme_preset(str(defaults.get("preset", "pergamena")))


## Rimette tutto ai valori predefiniti.
func reset_all() -> void:
	for section: String in _defaults:
		reset_section(section)


## Applica un tema pronto (vedi [ThemePresets]).
func apply_theme_preset(preset_name: String) -> void:
	if preset_name == ThemePresets.CUSTOM:
		return
	var preset: Dictionary = ThemePresets.get_preset(preset_name)
	for key: String in PRESET_KEYS:
		set_value("theme", key, preset[key])
	# Dopo i colori: set_value li avrebbe segnati come "personalizzato".
	(_values["theme"] as Dictionary)["preset"] = preset_name
	changed.emit("theme", "preset", preset_name)
	_save_timer.start()


#endregion

#region Scorciatoie per il gioco


## Un colore del tema: "background", "panel", "text", "accent", "paper", "ink".
func color(color_name: String) -> Color:
	var value: Variant = get_value("theme", color_name, Color.MAGENTA)
	return value if value is Color else Color.MAGENTA


## Gli 8 colori delle voci e delle carte.
func palette() -> Array[Color]:
	var out: Array[Color] = []
	for value: Variant in get_value("theme", "palette", []):
		out.append(value as Color)
	if out.is_empty():
		out.append(color("accent"))
	return out


## Il colore numero [param i] della tavolozza (gira in tondo).
func palette_color(i: int) -> Color:
	var colors: Array[Color] = palette()
	return colors[posmod(i, colors.size())]


## Lo stile della carta, per [MenuCardArt]: colore della carta, inchiostro e usura.
func card_style() -> Dictionary:
	return {
		"paper": color("paper"),
		"ink": color("ink"),
		"wear": float(get_value("theme", "card_wear", 0.6)),
	}


## Il [Theme] globale dell'interfaccia, gia' applicato a tutto il gioco.
func ui_theme() -> Theme:
	return _ui_theme


## Il font scelto, o null per quello di sistema.
func ui_font() -> Font:
	if str(get_value("theme", "font", "pixel")) == "pixel" and ResourceLoader.exists(UiThemeBuilder.PIXEL_FONT):
		return load(UiThemeBuilder.PIXEL_FONT) as Font
	return null


## La dimensione del testo, gia' moltiplicata per la scala del testo.
func font_size(base: int) -> int:
	return int(round(float(base) * float(get_value("accessibility", "text_scale", 1.0))))


## Per le animazioni: moltiplica una durata per questo numero.
##
## Tiene conto della velocita' delle animazioni e di "Riduci movimento" (che
## le rende quasi istantanee).
## [codeblock]
## tween.tween_property(node, "position", target, 0.4 * Settings.motion_scale())
## [/codeblock]
func motion_scale() -> float:
	if bool(get_value("accessibility", "reduce_motion", false)):
		return 0.05
	return 1.0 / maxf(float(get_value("theme", "animation_speed", 1.0)), 0.1)


## True se il giocatore ha chiesto meno movimento sullo schermo.
func reduce_motion() -> bool:
	return bool(get_value("accessibility", "reduce_motion", false))


## Quanto deve tremare lo schermo: 0 = mai, 1 = pieno.
func screen_shake() -> float:
	if reduce_motion():
		return 0.0
	return float(get_value("game", "screen_shake", 1.0))


## La velocita' del testo dei dialoghi: 1 = normale, 2 = doppia...
func text_speed() -> float:
	return maxf(float(get_value("game", "text_speed", 1.0)), 0.1)


## La difficolta': "easy", "normal" o "hard".
func difficulty() -> String:
	return str(get_value("game", "difficulty", "normal"))


#endregion

#region Applicare


## Applica tutte le impostazioni. [param startup] true al primo avvio: la
## modalita' finestra si applica solo se il giocatore l'ha scelta, per non
## cambiare la finestra decisa nelle impostazioni del progetto.
func apply_all(startup: bool = false) -> void:
	for section: String in _values:
		if section == "controls":
			continue
		for key: String in _values[section]:
			if startup and section == "video" and key == "window_mode" and not _config.has_section_key("video", "window_mode"):
				continue
			_apply_key(section, key)
	_apply_bindings()
	_emit_theme_changed()


func _apply_key(section: String, key: String) -> void:
	match section:
		"audio":
			_apply_audio()
		"video":
			match key:
				"window_mode":
					_apply_window_mode()
				"vsync":
					DisplayServer.window_set_vsync_mode(
						DisplayServer.VSYNC_ENABLED if get_value("video", "vsync") else DisplayServer.VSYNC_DISABLED
					)
				"max_fps":
					Engine.max_fps = int(get_value("video", "max_fps", 0))
				"ui_scale":
					get_tree().root.content_scale_factor = float(get_value("video", "ui_scale", 1.0))
				"brightness", "contrast", "saturation":
					_apply_post()
				"show_fps":
					_fps_label.visible = bool(get_value("video", "show_fps", false))
		"game":
			if key == "language":
				TranslationServer.set_locale(str(get_value("game", "language", "it")))
		"accessibility":
			if key == "colorblind":
				_apply_post()
		"controls":
			_apply_bindings()


func _apply_audio() -> void:
	var muted: bool = bool(get_value("audio", "mute", false))
	if bool(get_value("audio", "mute_unfocused", false)) and not _focused:
		muted = true

	for key: String in BUSES:
		var bus: int = AudioServer.get_bus_index(BUSES[key])
		if bus < 0:
			continue
		var linear: float = clampf(float(get_value("audio", key, 1.0)), 0.0, 1.0)
		AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(linear, 0.0001)))
		AudioServer.set_bus_mute(bus, linear <= 0.001 or (key == "master" and muted))


func _apply_window_mode() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var modes: Dictionary = {
		"windowed": DisplayServer.WINDOW_MODE_WINDOWED,
		"maximized": DisplayServer.WINDOW_MODE_MAXIMIZED,
		"fullscreen": DisplayServer.WINDOW_MODE_FULLSCREEN,
		"exclusive": DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN,
	}
	var mode: String = str(get_value("video", "window_mode", "windowed"))
	DisplayServer.window_set_mode(modes.get(mode, DisplayServer.WINDOW_MODE_WINDOWED))


## Luminosita', contrasto, saturazione e filtro per daltonici: uno shader sopra
## a tutto il gioco. Resta spento quando non serve, cosi' non costa niente.
func _apply_post() -> void:
	var material: ShaderMaterial = _post_rect.material as ShaderMaterial
	var brightness: float = float(get_value("video", "brightness", 1.0))
	var contrast: float = float(get_value("video", "contrast", 1.0))
	var saturation: float = float(get_value("video", "saturation", 1.0))
	var modes: Dictionary = {"none": 0, "protanopia": 1, "deuteranopia": 2, "tritanopia": 3}
	var mode: int = modes.get(str(get_value("accessibility", "colorblind", "none")), 0)

	material.set_shader_parameter("brightness", brightness)
	material.set_shader_parameter("contrast", contrast)
	material.set_shader_parameter("saturation", saturation)
	material.set_shader_parameter("colorblind_mode", mode)
	_post_rect.visible = (
		not is_equal_approx(brightness, 1.0) or not is_equal_approx(contrast, 1.0)
		or not is_equal_approx(saturation, 1.0) or mode != 0
	)


## Ricostruisce il [Theme] e lo mette dove tutto il gioco lo vede.
##
## [b]Dove:[/b] nel tema di progetto ([code]gui/theme/custom[/code], cioe'
## [code]res://Settings/game_theme.tres[/code]). Lo leggono tutti i Control,
## anche quelli dentro un [CanvasLayer] (HUD, menu di pausa...), che invece
## non vedrebbero un tema messo sulla finestra. Il file su disco resta vuoto:
## lo riempiamo solo in memoria, a ogni avvio.
func _emit_theme_changed() -> void:
	_ui_theme = UiThemeBuilder.build(_look())
	var project_theme: Theme = ThemeDB.get_project_theme()
	if project_theme != null:
		project_theme.clear()
		project_theme.merge_with(_ui_theme)
		project_theme.default_font = _ui_theme.default_font
		project_theme.default_font_size = _ui_theme.default_font_size
		_ui_theme = project_theme
	else:
		# Nessun tema di progetto impostato: almeno la finestra principale.
		get_tree().root.theme = _ui_theme
	theme_changed.emit()


## Tutto quello che serve per costruire il [Theme] dell'interfaccia.
func _look() -> Dictionary:
	return {
		"background": color("background"),
		"panel": color("panel"),
		"text": color("text"),
		"accent": color("accent"),
		"paper": color("paper"),
		"ink": color("ink"),
		"font": ui_font(),
		"font_size": font_size(30),
		"high_contrast": bool(get_value("accessibility", "high_contrast", false)),
	}


#endregion

#region Comandi


## Le azioni che il giocatore puo' rimappare: tutte quelle del progetto tranne
## quelle interne di Godot ("ui_..."). Un'azione nuova aggiunta in
## Progetto → Impostazioni → Mappa di input compare da sola.
func rebindable_actions() -> Array[StringName]:
	var out: Array[StringName] = []
	for action: StringName in _default_bindings:
		out.append(action)
	return out


## Il nome leggibile di un'azione.
func action_label(action: StringName) -> String:
	var names: Dictionary = {
		&"left": "Sinistra", &"right": "Destra", &"up": "Su", &"down": "Giù",
		&"attack": "Attacco", &"interact": "Interagisci",
	}
	return names.get(action, str(action).capitalize())


## Il tasto (o pulsante del mouse) assegnato a un'azione, da mostrare.
func binding_text(action: StringName) -> String:
	if not InputMap.has_action(action):
		return "—"
	for event: InputEvent in InputMap.action_get_events(action):
		if _is_keyboard_or_mouse(event):
			return _event_text(event)
	return "—"


## Assegna un nuovo tasto (o pulsante del mouse) a un'azione.
##
## Se quel tasto era gia' di un'altra azione, le due si scambiano il tasto:
## cosi' nessuna azione resta senza comando per sbaglio.
func rebind(action: StringName, event: InputEvent) -> void:
	if not InputMap.has_action(action) or not _is_keyboard_or_mouse(event):
		return

	var new_code: String = _serialize_event(event)
	var old_event: InputEvent = null
	for existing: InputEvent in InputMap.action_get_events(action):
		if _is_keyboard_or_mouse(existing):
			old_event = existing
			break

	for other: StringName in rebindable_actions():
		if other == action:
			continue
		for existing: InputEvent in InputMap.action_get_events(other):
			if _serialize_event(existing) == new_code:
				InputMap.action_erase_event(other, existing)
				if old_event != null:
					InputMap.action_add_event(other, old_event.duplicate())
				_store_binding(other)

	if old_event != null:
		InputMap.action_erase_event(action, old_event)
	InputMap.action_add_event(action, _deserialize_event(new_code))
	_store_binding(action)
	controls_changed.emit()
	_save_timer.start()


## Rimette i comandi del progetto.
func reset_bindings() -> void:
	_values["controls"] = _serialized_default_bindings()
	_apply_bindings()
	controls_changed.emit()
	_save_timer.start()


func _capture_default_bindings() -> void:
	_default_bindings.clear()
	for action: StringName in InputMap.get_actions():
		if str(action).begins_with("ui_") or str(action).begins_with("spatial_editor"):
			continue
		var events: Array[InputEvent] = []
		for event: InputEvent in InputMap.action_get_events(action):
			events.append(event.duplicate())
		_default_bindings[action] = events


func _serialized_default_bindings() -> Dictionary:
	var out: Dictionary = {}
	for action: StringName in _default_bindings:
		var codes: Array = []
		for event: InputEvent in _default_bindings[action]:
			var code: String = _serialize_event(event)
			if not code.is_empty():
				codes.append(code)
		out[str(action)] = codes
	return out


func _store_binding(action: StringName) -> void:
	var codes: Array = []
	for event: InputEvent in InputMap.action_get_events(action):
		var code: String = _serialize_event(event)
		if not code.is_empty():
			codes.append(code)
	(_values["controls"] as Dictionary)[str(action)] = codes


func _apply_bindings() -> void:
	var stored: Dictionary = _values.get("controls", {})
	for action: StringName in _default_bindings:
		if not InputMap.has_action(action) or not stored.has(str(action)):
			continue
		InputMap.action_erase_events(action)
		for code: Variant in stored[str(action)]:
			var event: InputEvent = _deserialize_event(str(code))
			if event != null:
				InputMap.action_add_event(action, event)


## Un comando come testo, per salvarlo: "key:65", "mouse:1", "joy:0", "axis:1:-1".
func _serialize_event(event: InputEvent) -> String:
	var key: InputEventKey = event as InputEventKey
	if key != null:
		if key.physical_keycode != KEY_NONE:
			return "key:%d" % key.physical_keycode
		return "keycode:%d" % key.keycode
	var mouse: InputEventMouseButton = event as InputEventMouseButton
	if mouse != null:
		return "mouse:%d" % mouse.button_index
	var joy: InputEventJoypadButton = event as InputEventJoypadButton
	if joy != null:
		return "joy:%d" % joy.button_index
	var axis: InputEventJoypadMotion = event as InputEventJoypadMotion
	if axis != null:
		return "axis:%d:%d" % [axis.axis, 1 if axis.axis_value >= 0.0 else -1]
	return ""


func _deserialize_event(code: String) -> InputEvent:
	var parts: PackedStringArray = code.split(":")
	if parts.size() < 2:
		return null
	match parts[0]:
		"key":
			var key: InputEventKey = InputEventKey.new()
			key.physical_keycode = int(parts[1]) as Key
			return key
		"keycode":
			var key: InputEventKey = InputEventKey.new()
			key.keycode = int(parts[1]) as Key
			return key
		"mouse":
			var mouse: InputEventMouseButton = InputEventMouseButton.new()
			mouse.button_index = int(parts[1]) as MouseButton
			return mouse
		"joy":
			var joy: InputEventJoypadButton = InputEventJoypadButton.new()
			joy.button_index = int(parts[1]) as JoyButton
			return joy
		"axis":
			if parts.size() < 3:
				return null
			var axis: InputEventJoypadMotion = InputEventJoypadMotion.new()
			axis.axis = int(parts[1]) as JoyAxis
			axis.axis_value = float(parts[2])
			return axis
	return null


func _is_keyboard_or_mouse(event: InputEvent) -> bool:
	return event is InputEventKey or event is InputEventMouseButton


func _event_text(event: InputEvent) -> String:
	var key: InputEventKey = event as InputEventKey
	if key != null:
		var keycode: Key = key.keycode
		if key.physical_keycode != KEY_NONE:
			keycode = DisplayServer.keyboard_get_keycode_from_physical(key.physical_keycode)
		return OS.get_keycode_string(keycode)
	var mouse: InputEventMouseButton = event as InputEventMouseButton
	if mouse != null:
		match mouse.button_index:
			MOUSE_BUTTON_LEFT:
				return "Mouse sinistro"
			MOUSE_BUTTON_RIGHT:
				return "Mouse destro"
			MOUSE_BUTTON_MIDDLE:
				return "Mouse centrale"
		return "Mouse %d" % mouse.button_index
	return event.as_text()


#endregion

#region Salvataggio


## Scrive le impostazioni su disco. Di solito non serve chiamarla: lo fa da
## sola poco dopo ogni cambiamento.
func save() -> void:
	_save_timer.stop()
	for section: String in _values:
		for key: String in _values[section]:
			_config.set_value(section, key, _values[section][key])
	var error: Error = _config.save(SAVE_PATH)
	if error != OK:
		push_warning("Settings: impossibile salvare %s (errore %d)" % [SAVE_PATH, error])


## Legge le impostazioni salvate. Le chiavi sconosciute o di tipo sbagliato
## (es. un file di una versione vecchia) vengono ignorate.
func load_settings() -> void:
	if _config.load(SAVE_PATH) != OK:
		return
	for section: String in _config.get_sections():
		if not _values.has(section):
			continue
		var values: Dictionary = _values[section]
		for key: String in _config.get_section_keys(section):
			var saved: Variant = _config.get_value(section, key)
			if section == "controls" or not values.has(key) or typeof(saved) == typeof(values[key]) or _both_numbers(saved, values[key]):
				values[key] = saved


func _both_numbers(a: Variant, b: Variant) -> bool:
	return typeof(a) in [TYPE_INT, TYPE_FLOAT] and typeof(b) in [TYPE_INT, TYPE_FLOAT]


#endregion

#region Schermata delle impostazioni


## Apre la schermata delle impostazioni sopra a tutto (anche a gioco in pausa).
##
## Restituisce la schermata; quando il giocatore la chiude emette [signal menu_toggled].
## [codeblock]
## # Nel menu di pausa:
## func _on_opzioni_pressed() -> void:
##     Settings.open_menu()
## [/codeblock]
func open_menu() -> Control:
	if is_menu_open():
		return _menu_layer.get_child(0) as Control

	_menu_layer = CanvasLayer.new()
	_menu_layer.layer = 100
	_menu_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(_menu_layer)

	var menu: Control = (load(MENU_SCENE) as PackedScene).instantiate()
	_menu_layer.add_child(menu)
	menu.tree_exited.connect(_on_menu_closed)
	menu_toggled.emit(true)
	return menu


## True se la schermata delle impostazioni e' aperta.
func is_menu_open() -> bool:
	return _menu_layer != null and is_instance_valid(_menu_layer) and _menu_layer.get_child_count() > 0


func _on_menu_closed() -> void:
	if _menu_layer != null and is_instance_valid(_menu_layer):
		_menu_layer.queue_free()
	_menu_layer = null
	save()
	menu_toggled.emit(false)


#endregion

#region Utility


func _make_timer(seconds: float, callback: Callable) -> Timer:
	var timer: Timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = seconds
	timer.timeout.connect(callback)
	add_child(timer)
	return timer


## I bus audio che mancano li crea al volo, cosi' i volumi funzionano anche se
## nessuno li ha creati nel pannello Audio dell'editor.
func _ensure_buses() -> void:
	for key: String in BUSES:
		var bus_name: StringName = BUSES[key]
		if AudioServer.get_bus_index(bus_name) >= 0:
			continue
		AudioServer.add_bus()
		var index: int = AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus_name)
		AudioServer.set_bus_send(index, &"Master")


## Lo strato sopra a tutto: filtri colore e contatore FPS.
func _build_overlay() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 128
	add_child(layer)

	_post_rect = ColorRect.new()
	_post_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_post_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = load("res://Settings/screen_filter.gdshader") as Shader
	_post_rect.material = material
	_post_rect.visible = false
	layer.add_child(_post_rect)

	_fps_label = Label.new()
	_fps_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_fps_label.offset_left = -160.0
	_fps_label.offset_right = -16.0
	_fps_label.offset_top = 10.0
	_fps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_fps_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_fps_label.add_theme_constant_override("outline_size", 6)
	_fps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fps_label.visible = false
	layer.add_child(_fps_label)


func _same(a: Variant, b: Variant) -> bool:
	if typeof(a) != typeof(b):
		return false
	if a is Array:
		return (a as Array) == (b as Array)
	return a == b


#endregion
