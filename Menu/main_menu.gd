## Il menu principale del gioco: le voci sono carte che scorrono.
##
## [b]Com'e' fatto:[/b] le voci del menu non sono un elenco di pulsanti, sono
## [b]carte[/b] disposte a ventaglio. Quella selezionata sta al centro, dritta
## e in primo piano; le altre si allontanano ai lati rimpicciolendosi,
## ruotando e sbiadendo. Premi la freccia e il mazzo scorre: la carta nuova
## entra da un lato e si "sfila" fino al centro, come quando apri un mazzo.
##
## [b]Come si usa:[/b] apri [code]res://Menu/main_menu.tscn[/code] e premi F6.
##
## [b]Come mettere le tue immagini:[/b] ogni voce ha un campo [b]Art[/b].
## Compilalo con l'illustrazione della carta e compare sul menu. Vedi
## [code]Menu/README.md[/code] per il resto.
##
## [b]Come aggiungere una voce:[/b] aggiungi un elemento a [member actions]
## nell'inspector. Se lasci l'array vuoto usa [method build_default_actions].
## Per collegare una voce a una schermata, compila il suo campo [b]Scene Path[/b].
extends Control


## Emesso quando il giocatore sceglie una voce che il menu non gestisce da solo.
##
## Utile se preferisci collegare le schermate dal codice invece che con
## [member MenuAction.scene_path].
signal action_selected(action_id: StringName)

## Emesso quando il giocatore sceglie di uscire e conferma.
signal quit_requested()

@export_group("Testi")

## Il titolo grande. Se lo lasci vuoto usa il nome del progetto.
@export var title: String = ""

## La riga sotto il titolo.
@export_multiline var subtitle: String = "Un card game a turni"

## La riga di aiuto in fondo. Vuota = quella di default.
@export_multiline var hint: String = ""

## Riga piccolissima in basso a sinistra. Utile per la versione.
@export var footer: String = ""

@export_group("Voci di menu")

## Le voci del menu. Se lasci vuoto usa quelle di default
## (Storia, Il tuo deck, Negozio, Opzioni, Prova una battaglia, Esci).
@export var actions: Array[MenuAction] = []

## Se true il menu mostra un messaggio quando scegli una voce
## che non porta ancora a nessuna schermata.
@export var show_placeholder_message: bool = true

@export_group("Carte")

## Dimensione di una carta. Alzala per un menu piu' imponente.
@export var card_size: Vector2 = Vector2(300, 420)

## Quanto distano i centri di due carte vicine.
##
## Se e' piu' piccola della larghezza della carta, le carte si sovrappongono
## un po': e' quello che le fa sembrare un mazzo di carte invece di una fila.
@export_range(60.0, 600.0, 5.0) var card_spacing: float = 196.0

## Quante carte tenere visibili per lato, oltre a quella centrale.
@export_range(0, 8, 1) var visible_side: int = 3

## Quanto rimpicciolisce ogni carta allontanandosi di un posto dal centro.
@export_range(0.5, 1.0, 0.01) var neighbour_scale: float = 0.86

## Quanto sbiadisce ogni carta allontanandosi di un posto dal centro.
@export_range(0.0, 0.6, 0.02) var neighbour_fade: float = 0.16

## Rotazione, in gradi, della prima carta di lato. Piu' alta = ventaglio
## piu' aperto.
@export_range(0.0, 25.0, 0.5) var fan_rotation: float = 8.0

## Se true, arrivato all'ultima voce la freccia riparte dalla prima.
@export var wrap_around: bool = true

@export_group("Animazione")

## Quanto dura lo scorrimento del mazzo, in secondi.
@export_range(0.1, 1.5, 0.05) var slide_duration: float = 0.45

## Se true la carta "sfora" un po' oltre la sua posizione e poi torna
## indietro: e' quello che da' la sensazione di carta che scatta fuori
## dal mazzo. Se lo togli il movimento diventa piu' sobrio.
@export var slide_overshoot: bool = true

## Quanto dura l'ingresso di una carta all'avvio, in secondi.
@export_range(0.1, 2.0, 0.05) var deal_duration: float = 0.6

## Ritardo fra una carta e la successiva all'avvio, in secondi.
## E' il tempo fra una carta e l'altra mentre escono dal mazzo.
@export_range(0.0, 0.4, 0.01) var deal_stagger: float = 0.07

## A che altezza mettere il centro del ventaglio, in proporzione all'altezza
## dello schermo. 0.5 = meta' esatta.
@export_range(0.2, 0.8, 0.01) var carousel_center_ratio: float = 0.47

@export_group("Aspetto")

## Dimensione del titolo.
@export_range(24, 140, 2) var title_size: int = 68

## Dimensione del testo scritto sulle carte.
@export_range(14, 60, 1) var card_title_size: int = 32

## Colore usato per i bordi del pannello di conferma.
@export var accent_color: Color = Color(0.98, 0.72, 0.30)

## Colore di fondo dello schermo.
@export var background_color: Color = Color(0.05, 0.06, 0.09)

## Se true, dietro alle carte del menu scorre anche il mazzo decorativo
## ([MenuCardBackdrop]). E' solo ambiente: non serve al menu.
@export var ambient_cards: bool = false


# --- Riferimenti UI ---
var _ambient: MenuCardBackdrop
var _card_layer: Control
var _title_label: Label
var _subtitle_label: Label
var _description_label: Label
var _index_label: Label
var _hint_label: Label
var _footer_label: Label
var _toast_label: Label

# --- Stato ---
var _cards: Array[MenuEntryCard] = []
var _action_list: Array[MenuAction] = []
var _selected: int = 0
var _toast_time_left: float = 0.0
var _intro_done: bool = false
var _busy: bool = false

# --- Conferma ---
var _confirm_layer: Control
var _confirm_text: Label
var _pending_action: MenuAction = null


func _ready() -> void:
	_build_ui()
	_build_cards()
	_layout_ui()
	_layout_cards(false)
	resized.connect(_on_resized)
	call_deferred("_play_intro")


#region Costruzione interfaccia


## Costruisce tutta la UI in codice.
##
## [b]Perche' in codice:[/b] cosi' non si puo' rompere per un errore di
## formattazione in un file [code].tscn[/code], e tutti i valori regolabili
## restano raggruppati nell'inspector di questo nodo.
func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# IGNORE: i click li prendono le carte, il resto passa oltre. Serve a non
	# bloccare la rotella del mouse (vedi _input).
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# --- 1. Fondo, con un gradiente appena accennato ---
	var base: ColorRect = ColorRect.new()
	base.color = background_color
	base.set_anchors_preset(Control.PRESET_FULL_RECT)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(base)

	var sheen: TextureRect = TextureRect.new()
	sheen.texture = _make_background_gradient()
	sheen.set_anchors_preset(Control.PRESET_FULL_RECT)
	sheen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sheen.stretch_mode = TextureRect.STRETCH_SCALE
	sheen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sheen)

	# --- 2. Sfondo animato, solo se lo accendi ---
	if ambient_cards:
		_ambient = MenuCardBackdrop.new()
		_ambient.set_anchors_preset(Control.PRESET_FULL_RECT)
		_ambient.modulate.a = 0.55
		_ambient.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_ambient)

	# --- 3. Lo strato dove vivono le carte del menu ---
	# Non e' un contenitore: le posizioni le calcoliamo noi, una per una.
	# Un contenitore le rimetterebbe in fila annullando il ventaglio.
	_card_layer = Control.new()
	_card_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_card_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_card_layer)

	# --- 4. Titolo, sottotitolo, descrizione, aiuto ---
	_title_label = _make_centered_label(title_size, Color(0.97, 0.97, 0.99))
	_title_label.text = _resolve_title()
	_title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.65))
	_title_label.add_theme_constant_override("shadow_offset_x", 3)
	_title_label.add_theme_constant_override("shadow_offset_y", 3)
	add_child(_title_label)

	_subtitle_label = _make_centered_label(23, Color(0.74, 0.78, 0.88))
	_subtitle_label.text = subtitle
	_subtitle_label.visible = not subtitle.strip_edges().is_empty()
	add_child(_subtitle_label)

	_description_label = _make_centered_label(20, Color(0.80, 0.84, 0.92))
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_description_label)

	_index_label = _make_centered_label(16, Color(0.60, 0.64, 0.74))
	add_child(_index_label)

	_hint_label = _make_centered_label(17, Color(0.55, 0.59, 0.68))
	_hint_label.text = _resolve_hint()
	add_child(_hint_label)

	# --- 5. Piede, in basso a sinistra ---
	_footer_label = Label.new()
	_footer_label.text = _resolve_footer()
	_footer_label.add_theme_font_size_override("font_size", 15)
	_footer_label.add_theme_color_override("font_color", Color(0.45, 0.48, 0.56))
	_footer_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	# Tutti e quattro gli offset: con gli anchor in basso a sinistra,
	# lasciare offset_left == offset_right darebbe larghezza zero.
	_footer_label.offset_left = 28.0
	_footer_label.offset_right = 428.0
	_footer_label.offset_top = -42.0
	_footer_label.offset_bottom = -16.0
	_footer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_footer_label)

	# --- 6. Messaggio temporaneo, in basso al centro ---
	_toast_label = Label.new()
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.add_theme_font_size_override("font_size", 21)
	_toast_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.96))
	_toast_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_toast_label.add_theme_constant_override("outline_size", 8)
	_toast_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_toast_label.offset_top = -176.0
	_toast_label.offset_bottom = -140.0
	_toast_label.modulate.a = 0.0
	_toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toast_label)

	_confirm_layer = _build_confirm_layer()


## Crea una Label centrata che occupa tutta la larghezza dello schermo.
##
## Gli offset verticali li sistema [method _layout_ui], perche' dipendono
## dall'altezza della finestra.
func _make_centered_label(font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	# Margine orizzontale: le righe lunghe non devono toccare i bordi.
	label.offset_left = 80.0
	label.offset_right = -80.0
	return label


## Posiziona i testi in base alla dimensione attuale dello schermo.
func _layout_ui() -> void:
	var height: float = size.y
	var center_y: float = height * carousel_center_ratio

	_title_label.offset_top = height * 0.055
	_title_label.offset_bottom = _title_label.offset_top + float(title_size) * 1.35

	_subtitle_label.offset_top = _title_label.offset_bottom + 2.0
	_subtitle_label.offset_bottom = _subtitle_label.offset_top + 36.0

	# La descrizione sta sotto il ventaglio di carte.
	_description_label.offset_top = center_y + card_size.y * 0.5 + 46.0
	_description_label.offset_bottom = _description_label.offset_top + 66.0

	_index_label.offset_top = height - 140.0
	_index_label.offset_bottom = height - 108.0

	_hint_label.offset_top = height - 100.0
	_hint_label.offset_bottom = height - 68.0


## Un gradiente verticale appena percettibile, per dare profondita' al fondo.
func _make_background_gradient() -> GradientTexture2D:
	var gradient: Gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	gradient.colors = PackedColorArray([
		background_color.lightened(0.10),
		background_color,
		background_color.darkened(0.35),
	])

	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 8
	texture.height = 512
	texture.fill_from = Vector2(0.5, 0.0)
	texture.fill_to = Vector2(0.5, 1.0)
	return texture


## Costruisce il pannello di conferma (nascosto all'inizio).
func _build_confirm_layer() -> Control:
	var layer: Control = Control.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.visible = false
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(layer)

	var veil: ColorRect = ColorRect.new()
	veil.color = Color(0, 0, 0, 0.7)
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(veil)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(center)

	var panel: PanelContainer = PanelContainer.new()
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.10, 0.11, 0.15, 0.98)
	panel_style.border_color = accent_color
	panel_style.border_width_left = 3
	panel_style.border_width_top = 3
	panel_style.border_width_right = 3
	panel_style.border_width_bottom = 3
	panel_style.corner_radius_top_left = 16
	panel_style.corner_radius_top_right = 16
	panel_style.corner_radius_bottom_left = 16
	panel_style.corner_radius_bottom_right = 16
	panel_style.content_margin_left = 34
	panel_style.content_margin_right = 34
	panel_style.content_margin_top = 26
	panel_style.content_margin_bottom = 26
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 22)
	panel.add_child(column)

	_confirm_text = Label.new()
	_confirm_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_confirm_text.add_theme_font_size_override("font_size", 24)
	_confirm_text.add_theme_color_override("font_color", Color(0.95, 0.95, 0.97))
	column.add_child(_confirm_text)

	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 18)
	column.add_child(buttons)

	var yes: Button = _make_dialog_button("Sì")
	yes.pressed.connect(_on_confirm_yes)
	buttons.add_child(yes)

	var no: Button = _make_dialog_button("No")
	no.pressed.connect(_on_confirm_no)
	buttons.add_child(no)

	return layer


#endregion

#region Voci di menu


## Le voci di default, usate se [member actions] e' vuoto.
##
## [b]Per collegare una voce a una schermata[/b] basta compilare il suo
## [b]Scene Path[/b]: quando la scegli, il menu carica quella scena.
##
## [b]Le voci senza Scene Path[/b] non sono un errore: sono le schermate che
## non hai ancora fatto. Compaiono lo stesso e, se le scegli, il menu te lo
## dice invece di non fare niente. Per non farle proprio vedere, togli la
## spunta a [b]Enabled[/b] sulla voce.
static func build_default_actions() -> Array[MenuAction]:
	var list: Array[MenuAction] = []

	list.append(MenuAction.of(
		&"story", "Storia",
		"Inizia l'avventura e attraversa i dungeon.",
		"res://Scene/Main.tscn"
	))

	list.append(MenuAction.of(
		&"deck", "Il tuo deck",
		"Componi il mazzo con le carte che hai raccolto."
	))

	list.append(MenuAction.of(
		&"shop", "Negozio",
		"Compra carte singole o apri pacchetti."
	))

	list.append(MenuAction.of(
		&"options", "Opzioni",
		"Impostazioni di gioco, audio e video."
	))

	list.append(MenuAction.of(
		&"battle", "Prova una battaglia",
		"Salta subito a una partita di prova contro un avversario.",
		"res://Cards/table/play_table.tscn"
	))

	var quit_action: MenuAction = MenuAction.of(
		&"quit", "Esci",
		"Chiudi il gioco."
	)
	quit_action.needs_confirmation = true
	list.append(quit_action)

	return list


## Costruisce una carta per ogni voce del menu.
func _build_cards() -> void:
	for card: MenuEntryCard in _cards:
		if is_instance_valid(card):
			card.queue_free()
	_cards.clear()

	_action_list = _resolve_actions()
	_selected = clampi(_selected, 0, maxi(_action_list.size() - 1, 0))

	for i: int in range(_action_list.size()):
		var action: MenuAction = _action_list[i]

		var card: MenuEntryCard = MenuEntryCard.new()
		# I dati vanno impostati PRIMA di aggiungere la carta all'albero:
		# appena entra nell'albero parte _ready(), che la disegna.
		card.card_size = card_size
		card.title_text = action.label
		card.art = action.art
		card.enabled = action.enabled
		card.title_font_size = card_title_size
		card.index = i
		card.accent = (
			action.accent if action.has_custom_accent()
			else MenuEntryCard.palette_color(i)
		)

		_card_layer.add_child(card)
		card.card_pressed.connect(_on_card_pressed)
		# Invisibili finche' non e' partito l'ingresso: cosi' non si vede un
		# fotogramma con tutte le carte ammassate nell'angolo.
		card.modulate.a = 0.0
		_cards.append(card)

	_update_selection_labels()


## Le voci da mostrare: quelle scelte nell'inspector, o quelle di default.
func _resolve_actions() -> Array[MenuAction]:
	var list: Array[MenuAction] = []

	if actions.is_empty():
		for action: MenuAction in build_default_actions():
			list.append(action)
	else:
		for action: MenuAction in actions:
			list.append(action)

	return list


## Crea un pulsante per il pannello di conferma.
##
## Serve solo li': le voci del menu adesso sono carte, non pulsanti.
func _make_dialog_button(text: String) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(150.0, 52.0)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 22)

	button.add_theme_stylebox_override("normal", _make_dialog_style(
		Color(0.16, 0.17, 0.22), Color(1, 1, 1, 0.14)))
	button.add_theme_stylebox_override("hover", _make_dialog_style(
		Color(0.22, 0.23, 0.29), Color(1, 1, 1, 0.30)))
	button.add_theme_stylebox_override("pressed", _make_dialog_style(
		Color(0.12, 0.13, 0.17), accent_color))
	button.add_theme_stylebox_override("focus", _make_dialog_style(
		Color(0.20, 0.21, 0.27), accent_color))

	button.add_theme_color_override("font_color", Color(0.93, 0.94, 0.97))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	button.add_theme_color_override("font_focus_color", accent_color)
	return button


func _make_dialog_style(background: Color, border: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 22.0
	style.content_margin_right = 22.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	return style


#endregion

#region Azioni


## Il giocatore ha cliccato una carta.
##
## Cliccare la carta gia' al centro equivale a sceglierla (come Invio);
## cliccarne un'altra la porta al centro.
func _on_card_pressed(card: MenuEntryCard) -> void:
	if _busy or not is_instance_valid(card):
		return

	if card.index == _selected:
		_activate_selected()
		return

	_selected = card.index
	_layout_cards(true)


## Sceglie la voce che sta al centro del ventaglio.
func _activate_selected() -> void:
	if _busy or _action_list.is_empty():
		return

	var action: MenuAction = _action_list[_selected]
	if not action.enabled:
		_show_toast("%s non e' disponibile." % action.label, 2.0)
		_refuse_current()
		return

	# Le azioni che chiedono conferma si fermano qui.
	if action.needs_confirmation:
		_ask_confirmation(action)
		return

	_execute_action(action)


## Esegue davvero una voce.
##
## [b]Prima l'animazione, poi l'effetto:[/b] quando una voce porta a una
## schermata o chiude il gioco, la carta al centro "vola via" verso di te e
## solo alla fine dell'animazione succede qualcosa. Senza questo, la scena
## cambierebbe di colpo e l'animazione non si vedrebbe mai.
func _execute_action(action: MenuAction) -> void:
	# 1. Le azioni che il menu gestisce da solo.
	if action.id == &"quit":
		quit_requested.emit()
		_play_card_out(func() -> void: get_tree().quit())
		return

	# 2. Le voci collegate a una schermata.
	if action.has_scene():
		if ResourceLoader.exists(action.scene_path):
			var path: String = action.scene_path
			_play_card_out(func() -> void: get_tree().change_scene_to_file(path))
			return

		# La scena indicata non esiste: meglio dirlo che non far nulla.
		_show_toast("Scena non trovata:\n%s" % action.scene_path, 4.0)
		push_warning("Menu: la voce '%s' punta a una scena inesistente: %s" % [
			action.label, action.scene_path,
		])
		_refuse_current()
		return

	# 3. Tutto il resto: lo segnaliamo a chi ascolta, e intanto spieghiamo.
	action_selected.emit(action.id)

	if show_placeholder_message:
		_show_toast("%s: non e' ancora pronto." % action.label, 2.5)
	_refuse_current()


## Fa "volare via" la carta al centro, verso chi guarda.
func _play_card_out(then: Callable) -> void:
	if _cards.is_empty():
		then.call()
		return

	_busy = true
	var card: MenuEntryCard = _cards[_selected]
	card.kill_tween()

	# Portiamo la carta in cima: deve passare davanti a tutte le altre.
	_card_layer.move_child(card, _card_layer.get_child_count() - 1)

	var tween: Tween = card.create_tween()
	card.set_tween(tween)
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(card, "position", card.position + Vector2(-140.0, -300.0), 0.42)
	tween.tween_property(card, "scale", Vector2(1.55, 1.55), 0.42)
	tween.tween_property(card, "rotation", deg_to_rad(-10.0), 0.42)
	tween.tween_property(card, "modulate:a", 0.0, 0.42)
	tween.finished.connect(then)


## Dice alla carta al centro "no, questa non e' disponibile".
func _refuse_current() -> void:
	if _cards.is_empty():
		return
	var card: MenuEntryCard = _cards[_selected]
	if is_instance_valid(card):
		card.shake()


## Chiede conferma prima di eseguire un'azione delicata.
func _ask_confirmation(action: MenuAction) -> void:
	_pending_action = action
	_confirm_text.text = "Vuoi davvero\n\"%s\"?" % action.label
	_confirm_layer.visible = true

	# Diamo il focus a "No": cosi' se premi Invio per abitudine non chiudi il
	# gioco per sbaglio. Per confermare devi scegliere tu "Sì".
	for child: Node in _confirm_layer.find_children("*", "Button", true, false):
		var button: Button = child as Button
		if button != null and button.text == "No":
			button.call_deferred("grab_focus")
			return


func _on_confirm_yes() -> void:
	var action: MenuAction = _pending_action
	_pending_action = null
	_confirm_layer.visible = false

	if action != null:
		_execute_action(action)


func _on_confirm_no() -> void:
	_pending_action = null
	_confirm_layer.visible = false


#endregion

#region Carosello


## Sposta la selezione di un posto.
##
## [param direction] e' -1 (indietro) o +1 (avanti).
func _move_selection(direction: int) -> void:
	if _busy or _cards.size() < 2:
		return

	var count: int = _cards.size()
	var next: int = _selected

	# Salta le voci disabilitate: non ha senso fermarsi su una carta spenta.
	for _attempt: int in count:
		next += direction
		if wrap_around:
			next = posmod(next, count)
		elif next < 0 or next >= count:
			return  # Siamo a un estremo e il giro completo e' spento.
		if _action_list[next].enabled:
			break

	if next == _selected or not _action_list[next].enabled:
		return

	_selected = next
	_layout_cards(true)


## Porta la selezione su "Esci" e la sceglie: e' quello che fa Esc.
func _activate_quit_entry() -> void:
	for i: int in range(_action_list.size()):
		if _action_list[i].id == &"quit" and _action_list[i].enabled:
			_selected = i
			_layout_cards(true)
			_activate_selected()
			return
	# Nessuna voce "Esci": non facciamo niente. Meglio di chiudere il gioco
	# per sbaglio quando Esc non e' una scorciatoia voluta.


## Calcola dove va messa una carta, in base a quanto dista dal centro.
##
## [param rel] e' la distanza dal centro: 0 = la carta selezionata, 1 = quella
## subito a destra, -2 = due posti a sinistra, e cosi' via.
##
## [b]Il trucco del ventaglio:[/b] un solo numero decide tutto. Piu' la carta
## e' lontana, piu' e' piccola, piu' ruotata, piu' in basso e piu' sbiadita.
## E' per questo che sembra un mazzo steso sul tavolo e non una fila di
## riquadri.
func _target_for(rel: int) -> Dictionary:
	var center: Vector2 = Vector2(size.x * 0.5, size.y * carousel_center_ratio)
	var steps: int = absi(rel)

	if steps > visible_side:
		# Fuori scena: la parcheggiamo appena oltre il bordo, invisibile.
		# Serve a non avere carte tutte ammassate nello stesso punto.
		var side: float = _sign_of(rel)
		return {
			"position": Vector2(
				center.x + side * (card_size.x * float(visible_side + 1) + card_spacing),
				center.y
			) - card_size * 0.5,
			"scale": Vector2.ONE * pow(neighbour_scale, float(visible_side + 1)),
			"rotation": deg_to_rad(side * fan_rotation * 3.0),
			"alpha": 0.0,
			"focused": false,
		}

	var offset: Vector2 = Vector2(float(rel) * card_spacing, pow(float(steps), 1.5) * 6.0)
	if rel == 0:
		# La carta al centro si alza un po': sembra "tirata su" dal mazzo.
		offset.y -= 16.0

	return {
		"position": center + offset - card_size * 0.5,
		"scale": Vector2.ONE * pow(neighbour_scale, float(steps)),
		# La rotazione cresce, ma sempre meno: il ventaglio si apre senza che
		# le carte ai bordi si mettano di traverso.
		"rotation": deg_to_rad(_sign_of(rel) * pow(float(steps), 0.85) * fan_rotation),
		"alpha": clampf(1.0 - float(steps) * neighbour_fade, 0.0, 1.0),
		"focused": rel == 0,
	}


## Porta tutte le carte nella posizione che gli spetta.
##
## [param animate] false piazza tutto di colpo: serve al primo giro e quando
## cambia la dimensione della finestra.
## [param deal_in] true aggiunge il ritardo a scalare dell'ingresso iniziale.
func _layout_cards(animate: bool, deal_in: bool = false) -> void:
	if _cards.is_empty():
		return
	if size.x < 10.0 or size.y < 10.0:
		return

	for card: MenuEntryCard in _cards:
		if not is_instance_valid(card):
			continue
		var rel: int = _relative_offset(card.index)
		_apply_target(card, _target_for(rel), animate, deal_in, absi(rel))

	# L'ordine di disegno: prima le carte lontane, per ultima quella
	# selezionata. Cosi' la selezione sta sempre sopra a tutte le altre.
	_reorder_cards()
	_update_selection_labels()


## Quanti posti dista una carta dal centro, tenendo conto del giro completo.
func _relative_offset(card_index: int) -> int:
	var count: int = _cards.size()
	var rel: int = card_index - _selected

	if not wrap_around or count < 3:
		return rel

	# Con il giro completo scegliamo sempre la strada piu' corta: cosi' una
	# carta non attraversa tutto lo schermo per spostarsi di un posto solo.
	var half: int = count / 2
	if rel > half:
		rel -= count
	elif rel < -half:
		rel += count
	return rel


## Applica a una carta la sua posizione, con o senza animazione.
func _apply_target(
	card: MenuEntryCard,
	target: Dictionary,
	animate: bool,
	deal_in: bool,
	steps: int
) -> void:
	card.kill_tween()

	var alpha: float = target["alpha"]
	var focused: bool = target["focused"]

	if not animate:
		card.position = target["position"]
		card.scale = target["scale"]
		card.rotation = target["rotation"]
		card.modulate.a = alpha
		card.set_focused(focused)
		card.apply_accent(1.0 if focused else 0.0)
		return

	var duration: float = deal_duration if deal_in else slide_duration
	var delay: float = float(steps) * deal_stagger if deal_in else 0.0

	# TRANS_BACK fa "sforare" la carta un po' oltre la sua posizione e poi
	# tornare indietro: e' l'esitazione di una carta che esce dal mazzo.
	var trans: Tween.TransitionType = Tween.TRANS_BACK if slide_overshoot else Tween.TRANS_CUBIC

	var tween: Tween = card.create_tween()
	card.set_tween(tween)
	tween.set_parallel(true)

	tween.tween_property(card, "position", target["position"], duration) \
		.set_trans(trans).set_ease(Tween.EASE_OUT).set_delay(delay)
	tween.tween_property(card, "scale", target["scale"], duration) \
		.set_trans(trans).set_ease(Tween.EASE_OUT).set_delay(delay)
	tween.tween_property(card, "rotation", target["rotation"], duration) \
		.set_trans(trans).set_ease(Tween.EASE_OUT).set_delay(delay)

	# La dissolvenza usa un'altra curva: con TRANS_BACK l'alfa andrebbe sopra 1
	# e si vedrebbe un lampo.
	tween.tween_property(card, "modulate:a", alpha, duration * 0.7) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT).set_delay(delay)

	# L'accensione del bordo arriva un attimo dopo la carta: sembra che la
	# carta si "apra" quando si ferma davanti a te.
	tween.tween_method(card.apply_accent, card.accent_mix, 1.0 if focused else 0.0, duration * 0.9) \
		.set_delay(delay + 0.05)

	card.set_focused(focused)


## Mette le carte nell'albero nell'ordine giusto di disegno.
func _reorder_cards() -> void:
	var ordered: Array[MenuEntryCard] = _cards.duplicate()
	ordered.sort_custom(_is_further_than)
	for i: int in range(ordered.size()):
		_card_layer.move_child(ordered[i], i)


## Ordina le carte dalla piu' lontana dal centro alla piu' vicina.
func _is_further_than(a: MenuEntryCard, b: MenuEntryCard) -> bool:
	return absi(_relative_offset(a.index)) > absi(_relative_offset(b.index))


## L'ingresso: le carte escono una per una dal mazzo, come quando apri un
## pacchetto di carte nuove.
func _play_intro() -> void:
	if size.x < 10.0 or size.y < 10.0:
		call_deferred("_play_intro")
		return

	_intro_done = true
	_layout_ui()

	# Prima le impiliamo tutte fuori a destra, ruotate e invisibili: e' il
	# "mazzo chiuso" da cui poi escono una alla volta.
	for card: MenuEntryCard in _cards:
		if not is_instance_valid(card):
			continue
		card.position = _deck_position() - card_size * 0.5
		card.scale = Vector2.ONE * 0.62
		card.rotation = deg_to_rad(-24.0)
		card.modulate.a = 0.0
		card.set_focused(false)
		card.apply_accent(0.0)

	_layout_cards(true, true)
	_animate_in()


## Dove sta il "mazzo chiuso" da cui escono le carte.
func _deck_position() -> Vector2:
	return Vector2(size.x * 0.80, size.y * carousel_center_ratio)


## La dissolvenza in ingresso dei testi.
func _animate_in() -> void:
	_title_label.modulate.a = 0.0
	_subtitle_label.modulate.a = 0.0
	_description_label.modulate.a = 0.0

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_title_label, "modulate:a", 1.0, 0.5)
	tween.tween_property(_subtitle_label, "modulate:a", 1.0, 0.5).set_delay(0.1)
	tween.tween_property(_description_label, "modulate:a", 1.0, 0.6).set_delay(0.45)


## Rinfresca descrizione e contatore della voce selezionata.
func _update_selection_labels() -> void:
	if _action_list.is_empty():
		_description_label.text = ""
		_index_label.text = ""
		return

	var action: MenuAction = _action_list[_selected]
	_description_label.text = action.description
	_index_label.text = "%d / %d" % [_selected + 1, _action_list.size()]


## Il segno di un numero, come float.
func _sign_of(value: int) -> float:
	if value > 0:
		return 1.0
	if value < 0:
		return -1.0
	return 0.0


## Mostra un messaggio in basso, che svanisce da solo.
func _show_toast(text: String, seconds: float) -> void:
	_toast_label.text = text
	_toast_time_left = seconds

	var tween: Tween = create_tween()
	tween.tween_property(_toast_label, "modulate:a", 1.0, 0.15)


func _hide_toast() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_toast_label, "modulate:a", 0.0, 0.35)


## Fa passare il tempo per il messaggio temporaneo.
func _process(delta: float) -> void:
	if _toast_time_left <= 0.0:
		return
	_toast_time_left -= delta
	if _toast_time_left <= 0.0:
		_hide_toast()


## Scorre le carte con la rotella del mouse.
##
## Sta in _input e non in _unhandled_input di proposito: le carte usano
## MOUSE_FILTER_STOP per ricevere i click, e quello consumerebbe anche la
## rotella prima che arrivi qui.
func _input(event: InputEvent) -> void:
	var wheel: InputEventMouseButton = event as InputEventMouseButton
	if wheel == null or not wheel.pressed:
		return
	if _confirm_layer.visible:
		return

	if wheel.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_move_selection(1)
		get_viewport().set_input_as_handled()
	elif wheel.button_index == MOUSE_BUTTON_WHEEL_UP:
		_move_selection(-1)
		get_viewport().set_input_as_handled()


#endregion

#region Input


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return

	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	# Con la conferma aperta lasciamo fare ai suoi pulsanti: qui gestiamo solo
	# Esc, che annulla.
	if _confirm_layer.visible:
		if key_event.keycode == KEY_ESCAPE:
			_on_confirm_no()
			get_viewport().set_input_as_handled()
		return

	match key_event.keycode:
		KEY_LEFT, KEY_A, KEY_UP, KEY_W:
			_move_selection(-1)
			get_viewport().set_input_as_handled()
		KEY_RIGHT, KEY_D, KEY_DOWN, KEY_S:
			_move_selection(1)
			get_viewport().set_input_as_handled()
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			_activate_selected()
			get_viewport().set_input_as_handled()
		KEY_ESCAPE:
			# Esc seleziona "Esci", come in tutti i menu.
			_activate_quit_entry()
			get_viewport().set_input_as_handled()


#endregion

#region Utility


## Il titolo mostrato: quello impostato, oppure il nome del progetto.
func _resolve_title() -> String:
	if not title.strip_edges().is_empty():
		return title
	return str(ProjectSettings.get_setting("application/config/name", "GAME")).to_upper()


## La riga di aiuto: quella impostata, oppure quella di default.
func _resolve_hint() -> String:
	if not hint.strip_edges().is_empty():
		return hint
	return "← →  scorri le carte      Invio  scegli      Esc  esci"


## La riga in fondo: quella impostata, oppure una generica.
func _resolve_footer() -> String:
	if not footer.strip_edges().is_empty():
		return footer
	return "Godot %s" % Engine.get_version_info().get("string", "")


## La finestra ha cambiato dimensione: rimettiamo a posto tutto.
func _on_resized() -> void:
	_layout_ui()
	if _intro_done:
		_layout_cards(false)


#endregion
