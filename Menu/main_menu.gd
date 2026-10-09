## Il menu principale del gioco: le voci sono carte di un mazzo che tieni in mano.
##
## [b]Com'e' fatto:[/b] le voci del menu non sono un elenco di pulsanti, sono
## [b]carte[/b] impilate una dietro l'altra, come un blocco tenuto in mano. La
## voce selezionata e' la carta in cima; le altre spuntano dietro, un po'
## sfalsate, storte e piu' scure. Scorri (frecce, rotella, trackpad, oppure
## trascina la carta col mouse) e la carta in cima esce di lato e passa in
## fondo al mazzo.
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

## La scena della storia: "Nuova Partita" comincia dal camerino, nel mondo
## esplorabile ([Overworld]). "Riprendi" passa dal salvataggio ([SaveGame]),
## che riporta alla scena salvata.
const STORY_SCENE := "res://World/overworld.tscn"

@export_group("Titolo")

## L'immagine del titolo, mostrata in alto al centro del menu.
##
## Se la lasci vuota si usa [member title_path]. Se manca anche il file, il menu
## ripiega sul testo di [member title]: cosi' non resta mai senza titolo.
@export var title_image: Texture2D

## Percorso dell'immagine del titolo, usato quando [member title_image] e' vuota.
@export_file("*.png", "*.jpg", "*.jpeg", "*.webp") var title_path: String = "res://Menu/img/titleBgRemoved.png"

## Altezza del titolo a schermo, in pixel. La larghezza segue le proporzioni
## dell'immagine.
##
## Con l'immagine di default (677x369) il titolo non supera il 22% dell'altezza
## dello schermo: su 1080p sono ~237px, che e' esattamente lo spazio libero sopra
## alle carte. Alzarlo oltre non serve, si ferma li'.
@export_range(40, 700, 2) var title_height: int = 300

## Testo mostrato [b]solo[/b] se l'immagine del titolo manca.
##
## Il giocatore puo' sovrascriverlo dalle impostazioni (Tema -> Titolo del menu):
## in quel caso vale il suo testo.
@export var title: String = "FUORI COPIONE"

@export_group("Audio")

## La musica di sottofondo del menu. Parte all'avvio e gira all'infinito.
##
## Sta sul bus [b]Music[/b], quindi il volume della musica nelle impostazioni la
## controlla insieme al resto della colonna sonora.
@export_file("*.mp3", "*.ogg", "*.wav") var music_path: String = "res://Menu/Audio/menu_song.mp3"

## Il suono di quando si scorre il mazzo o si preme qualcosa.
## Sta sul bus [b]UI[/b], che ha il suo volume separato.
@export_file("*.mp3", "*.ogg", "*.wav") var click_path: String = "res://Menu/Audio/menu_botton.mp3"

## Volume della musica, in decibel. Piu' basso = piu' discreta.
@export_range(-40.0, 6.0, 0.5) var music_volume_db: float = -9.0

## Volume del suono dei click, in decibel.
@export_range(-40.0, 6.0, 0.5) var click_volume_db: float = -5.0

@export_group("Testi")

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

## Di quanto si sposta ogni carta rispetto a quella davanti.
##
## E' quello che fa vedere il mazzo: le carte dietro spuntano un po' in alto
## a destra, come quando tieni un blocco di carte in mano.
@export var stack_offset: Vector2 = Vector2(9.0, -11.0)

## Quante carte si vedono spuntare dietro a quella in cima.
@export_range(0, 8, 1) var stack_depth: int = 5

## Quanto rimpicciolisce ogni carta scendendo di un posto nel mazzo.
@export_range(0.0, 0.1, 0.005) var stack_scale_step: float = 0.02

## Quanto si scurisce ogni carta scendendo di un posto nel mazzo.
@export_range(0.0, 0.3, 0.01) var stack_darken: float = 0.11

## Rotazione massima, in gradi, delle carte dietro: nessun mazzo vero e'
## perfettamente allineato.
@export_range(0.0, 10.0, 0.5) var stack_jitter: float = 3.0

## Quanti pixel devi trascinare la carta perche' vada in fondo al mazzo.
## Se la lasci prima torna al suo posto.
@export_range(30.0, 400.0, 5.0) var swipe_threshold: float = 110.0

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

## A che altezza mettere il centro del mazzo, in proporzione all'altezza
## dello schermo. 0.5 = meta' esatta.
@export_range(0.2, 0.8, 0.01) var carousel_center_ratio: float = 0.47

@export_group("Aspetto")

## Dimensione del titolo.
@export_range(24, 140, 2) var title_size: int = 68

## Dimensione del testo scritto sulle carte.
@export_range(14, 60, 1) var card_title_size: int = 36

## Colore usato per i bordi del pannello di conferma.
## [b]Lo sovrascrive il tema delle impostazioni[/b] (vedi [method _read_settings]).
@export var accent_color: Color = Color(0.98, 0.72, 0.30)

## Colore di fondo dello schermo. Lo sovrascrive il tema delle impostazioni.
@export var background_color: Color = Color(0.05, 0.06, 0.09)

## Se true, dietro alle carte del menu scorre anche il mazzo decorativo
## ([MenuCardBackdrop]). E' solo ambiente: non serve al menu.
@export var ambient_cards: bool = false

@export_group("Sfondo")

## L'immagine di fondo del menu: il sipario.
##
## Se la lasci vuota si usa [member background_path]. Se non c'e' nessuna delle
## due, resta il solo colore di fondo: il menu funziona lo stesso.
@export var background_image: Texture2D

## Il percorso dell'immagine di fondo, usato quando [member background_image]
## e' vuoto.
##
## [b]Se il menu dice che non la trova:[/b] apri l'editor di Godot una volta.
## Le immagini appena aggiunte al progetto vengono importate da lui, e finche'
## non lo fa il gioco non le vede.
@export_file("*.png", "*.jpg", "*.jpeg", "*.webp") var background_path: String = "res://Menu/img/background.jpg"

## Quanto scurire l'immagine, per far leggere i testi che ci stanno sopra.
##
## Non e' un velo uniforme: scurisce soprattutto l'alto e il basso (dove stanno
## il titolo e le scritte) e lascia piu' libero il centro, dove si vedono le carte.
@export_range(0.0, 1.0, 0.05) var background_dim: float = 0.32

## Se true dietro al menu fluttuano le maschere ([MenuMaskBackdrop]).
@export var floating_masks: bool = true

## Quante maschere tenere in scena contemporaneamente.
@export_range(1, 60, 1) var mask_count: int = 16

## Altezza minima e massima di una maschera, in pixel. Le piu' grandi sono
## quelle "piu' vicine", che si muovono anche di piu'.
@export_range(40, 400, 2) var mask_height_min: int = 84
@export_range(40, 500, 2) var mask_height_max: int = 210

## Quanto sono visibili le maschere. Tienile discrete: sono sfondo.
@export_range(0.0, 1.0, 0.01) var mask_opacity: float = 0.40

## Velocita' di base delle maschere, in pixel al secondo.
## Alzala per vederle muoversi di piu', abbassala per un fondo quasi fermo.
@export_range(0.0, 120.0, 1.0) var mask_drift_speed: float = 13.0


# --- Riferimenti UI ---
var _background_image: TextureRect
var _mask_backdrop: MenuMaskBackdrop
var _ambient: MenuCardBackdrop
var _card_layer: Control
var _title_image: TextureRect
var _title_label: Label
var _description_label: Label
var _index_label: Label
var _hint_label: Label
var _footer_label: Label
var _toast_label: Label

# --- Audio ---
var _music: AudioStreamPlayer
var _click: AudioStreamPlayer

# --- Stato ---
var _cards: Array[MenuEntryCard] = []
var _action_list: Array[MenuAction] = []
var _selected: int = 0
var _toast_time_left: float = 0.0
var _intro_done: bool = false
var _busy: bool = false
var _scroll_cooldown: float = 0.0
var _pan_accum: float = 0.0

# --- Sottomenu (i pulsanti sotto la carta, es. quelli di Storia) ---
var _submenu_row: HBoxContainer = null
var _submenu_action: MenuAction = null

# --- Impostazioni ---
# I valori dell'inspector, prima che le impostazioni del giocatore li cambino:
# servono per poterli ricalcolare ogni volta che cambia il tema.
var _inspector: Dictionary = {}
var _text_color: Color = Color(0.97, 0.97, 0.99)

# --- Conferma ---
var _confirm_layer: Control
var _confirm_text: Label
var _pending_action: MenuAction = null


func _ready() -> void:
	_inspector = {
		"title": title,
		"slide_duration": slide_duration,
		"deal_duration": deal_duration,
		"deal_stagger": deal_stagger,
		"slide_overshoot": slide_overshoot,
	}
	_read_settings()
	Settings.theme_changed.connect(_on_theme_changed)

	# La musica parte subito, prima di costruire la UI: il menu non deve mai
	# comparire in silenzio.
	_setup_audio()

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

	# --- 1b. Il sipario: l'immagine di fondo ---
	# Sta sopra al colore pieno (che resta come ripiego se l'immagine manca) e
	# sotto a tutto il resto. KEEP_ASPECT_COVERED: riempie lo schermo senza
	# deformare l'immagine, tagliando quello che avanza ai lati.
	_background_image = TextureRect.new()
	_background_image.texture = _resolve_background()
	_background_image.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_background_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_background_image.visible = _background_image.texture != null
	add_child(_background_image)

	# --- 1c. Le maschere che fluttuano ---
	# Sopra al sipario (se no' non si vedrebbero) e sotto a tutto il menu.
	if floating_masks:
		_mask_backdrop = MenuMaskBackdrop.new()
		_mask_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
		_mask_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# I valori vanno dati PRIMA di aggiungerlo all'albero: appena entra
		# parte _ready(), che ritaglia il foglio e mette le maschere in scena.
		_mask_backdrop.mask_count = mask_count
		_mask_backdrop.mask_height_min = mask_height_min
		_mask_backdrop.mask_height_max = mask_height_max
		_mask_backdrop.opacity = mask_opacity
		_mask_backdrop.drift_speed = mask_drift_speed
		add_child(_mask_backdrop)

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
	# Un contenitore le rimetterebbe in fila annullando il mazzo.
	_card_layer = Control.new()
	_card_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_card_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_card_layer)

	# --- 4. Titolo, descrizione, aiuto ---
	_build_title()

	_description_label = _make_centered_label(30, _text_color.darkened(0.12))
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_description_label)

	_index_label = _make_centered_label(24, _text_color.darkened(0.35))
	add_child(_index_label)

	_hint_label = _make_centered_label(25, _text_color.darkened(0.42))
	_hint_label.text = _resolve_hint()
	add_child(_hint_label)

	# --- 5. Piede, in basso a sinistra ---
	_footer_label = Label.new()
	_footer_label.text = _resolve_footer()
	_footer_label.add_theme_font_size_override("font_size", Settings.font_size(22))
	_footer_label.add_theme_color_override("font_color", _text_color.darkened(0.5))
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
	_toast_label.add_theme_font_size_override("font_size", Settings.font_size(30))
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
	# La scala del testo viene dalle impostazioni (Accessibilita').
	label.add_theme_font_size_override("font_size", Settings.font_size(font_size))
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

	# Il titolo: l'immagine se c'e', altrimenti il testo. Vedi [method _layout_title].
	_layout_title()

	# La descrizione sta sotto il mazzo di carte. Se sono aperti i pulsanti
	# di una voce, loro prendono il suo posto e la descrizione scende.
	var below_cards: float = center_y + card_size.y * 0.5 + 46.0
	if _submenu_row != null:
		_submenu_row.offset_top = below_cards - 6.0
		_submenu_row.offset_bottom = _submenu_row.offset_top + 72.0
		below_cards = _submenu_row.offset_bottom + 14.0
	_description_label.offset_top = below_cards
	_description_label.offset_bottom = _description_label.offset_top + 84.0

	_index_label.offset_top = height - 156.0
	_index_label.offset_bottom = height - 116.0

	_hint_label.offset_top = height - 108.0
	_hint_label.offset_bottom = height - 64.0


## Posiziona il titolo, immagine o testo, e ritorna dove finisce.
##
## [b]L'immagine si scala sulla sua altezza,[/b] non stirata: la larghezza segue
## le proporzioni.
##
## Tre fermi, tutti calcolati da valori che sono nell'inspector:
## [br]- [b]Larghezza:[/b] mai oltre il 72% dello schermo, cosi' non tocca i bordi.
## [br]- [b]Altezza:[/b] mai oltre lo spazio libero sopra le carte. Non e' una
##   percentuale fissa ma nasce da [member carousel_center_ratio] e
##   [member card_size], quindi se sposti o ingrandisci il mazzo il titolo si
##   stringe da solo invece di finirci sopra.
## [br]- [b]Altezza minima:[/b] sotto il 6% dello schermo il titolo non scende,
##   altrimenti su finestre basse diventerebbe illeggibile.
func _layout_title() -> float:
	var top: float = size.y * 0.045
	# Dove comincia il mazzo: e' il vero limite inferiore del titolo.
	var cards_top: float = size.y * carousel_center_ratio - card_size.y * 0.5
	var free_height: float = maxf(cards_top - top - 16.0, size.y * 0.06)

	if _title_image.visible and _title_image.texture != null:
		var texture_size: Vector2 = _title_image.texture.get_size()
		var ratio: float = texture_size.x / maxf(texture_size.y, 1.0)

		var width: float = float(title_height) * ratio
		width = minf(width, size.x * 0.72)
		var height: float = width / maxf(ratio, 0.001)
		height = minf(height, free_height)
		width = height * ratio

		# Ancore a TOP_LEFT: qui gli offset sono coordinate assolute da (0,0),
		# quindi x1/x2 si calcolano diretti attorno al centro dello schermo.
		_title_image.offset_left = (size.x - width) * 0.5
		_title_image.offset_right = (size.x + width) * 0.5
		_title_image.offset_top = top
		_title_image.offset_bottom = top + height
		return _title_image.offset_bottom

	_title_label.offset_top = top
	_title_label.offset_bottom = top + float(Settings.font_size(title_size)) * 1.35
	return _title_label.offset_bottom


## Il velo sopra al fondo.
##
## [b]Con l'immagine:[/b] e' una vignetta trasparente. Scurisce l'alto e il basso
## — dove stanno il titolo e le righe di testo — e lascia piu' libero il centro,
## dove stanno le carte. Serve a far leggere i testi senza nascondere il sipario.
##
## [b]Senza immagine:[/b] e' il gradiente pieno, che da' profondita' al colore
## di fondo. Qui deve essere opaco, altrimenti sotto non ci sarebbe niente.
func _make_background_gradient() -> GradientTexture2D:
	var colors: PackedColorArray

	if _has_background_image():
		var dim: float = clampf(background_dim, 0.0, 1.0)
		colors = PackedColorArray([
			Color(0.0, 0.0, 0.0, clampf(dim * 1.1 + 0.20, 0.0, 1.0)),
			Color(0.0, 0.0, 0.0, dim * 0.45),
			Color(0.0, 0.0, 0.0, clampf(dim + 0.22, 0.0, 1.0)),
		])
	else:
		colors = PackedColorArray([
			background_color.lightened(0.10),
			background_color,
			background_color.darkened(0.35),
		])

	var gradient: Gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	gradient.colors = colors

	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 8
	texture.height = 512
	texture.fill_from = Vector2(0.5, 0.0)
	texture.fill_to = Vector2(0.5, 1.0)
	return texture


## L'immagine di fondo da mostrare, oppure null.
##
## Prima l'immagine assegnata a mano, poi quella al percorso. Se il file c'e'
## ma Godot non l'ha ancora importato (succede alle immagini appena aggiunte,
## finche' l'editor non le vede), lo segnala invece di restare muto.
func _resolve_background() -> Texture2D:
	if background_image != null:
		return background_image

	if background_path.strip_edges().is_empty():
		return null

	if not ResourceLoader.exists(background_path):
		push_warning("Menu: immagine di fondo non trovata: %s\nApri l'editor di Godot una volta: le immagini nuove le importa lui." % background_path)
		return null

	return load(background_path) as Texture2D


## True se c'e' un'immagine di fondo da mostrare.
func _has_background_image() -> bool:
	return _background_image != null and _background_image.texture != null


## Costruisce il titolo: l'immagine se c'e', il testo come ripiego.
##
## [b]Uno dei due resta sempre visibile,[/b] cosi' il menu non rimane mai senza
## titolo: se l'immagine manca (o Godot non l'ha ancora importata) compare il
## testo, e in Output trovi il motivo.
func _build_title() -> void:
	var texture: Texture2D = _resolve_title_image()

	_title_image = TextureRect.new()
	_title_image.texture = texture
	_title_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_title_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_title_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Angolo in alto a sinistra, non TOP_WIDE: con TOP_WIDE l'ancora destra sta
	# sul bordo destro dello schermo, quindi offset_right si *somma* a quel bordo
	# e il titolo finisce fuori schermo. Con TOP_LEFT gli offset sono assoluti e
	# [method _layout_title] puo' centrare l'immagine calcolando da sola x1/x2.
	_title_image.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_title_image.visible = texture != null
	add_child(_title_image)

	_title_label = _make_centered_label(title_size, _text_color)
	_title_label.text = _resolve_title()
	_title_label.visible = texture == null
	_title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.65))
	_title_label.add_theme_constant_override("shadow_offset_x", 3)
	_title_label.add_theme_constant_override("shadow_offset_y", 3)
	add_child(_title_label)


## L'immagine del titolo, oppure null se non c'e' (e allora si usa il testo).
func _resolve_title_image() -> Texture2D:
	if title_image != null:
		return title_image

	if title_path.strip_edges().is_empty():
		return null

	if not ResourceLoader.exists(title_path):
		push_warning("Menu: immagine del titolo non trovata: %s\nApri l'editor di Godot una volta: importa lui le immagini nuove. Nel frattempo uso il testo." % title_path)
		return null

	return load(title_path) as Texture2D


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

	# Storia non porta a una schermata da sola: apre tre pulsanti sotto la carta.
	# La sua maschera e' il segno del gioco: e' la prima cosa che si vede.
	var story: MenuAction = MenuAction.of(
		&"story", "Storia",
		"Fuori Copione: ti svegli senza volto in un teatro che e' tutto il mondo. Esci, se ci riesci.",
		"", &"mask"
	)
	story.sub_actions = [
		MenuAction.of(&"continue", "Riprendi", "Continua dall'ultimo salvataggio.", "", &"play"),
		MenuAction.of(&"new_game", "Nuova Partita", "Ricomincia dal camerino. Il numero sul muro sale di uno.", STORY_SCENE, &"plus"),
		MenuAction.of(&"story_options", "Altre Opzioni", "Difficolta', capitoli e altre impostazioni della storia.", "", &"gear"),
	]
	list.append(story)

	list.append(MenuAction.of(
		&"deck", "Il tuo deck",
		"Componi il mazzo con le carte che hai raccolto.",
		"", &"deck"
	))

	list.append(MenuAction.of(
		&"shop", "Negozio",
		"Compra carte singole o apri pacchetti.",
		"", &"shop"
	))

	list.append(MenuAction.of(
		&"options", "Opzioni",
		"Impostazioni di gioco, audio e video.",
		"", &"gear"
	))

	list.append(MenuAction.of(
		&"battle", "Prova una battaglia",
		"Salta subito a una partita di prova contro un avversario.",
		"res://Cards/table/play_table.tscn", &"sword"
	))

	var quit_action: MenuAction = MenuAction.of(
		&"quit", "Esci",
		"Chiudi il gioco.",
		"", &"exit"
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
	_refresh_continue_entry()

	for i: int in range(_action_list.size()):
		var action: MenuAction = _action_list[i]

		var card: MenuEntryCard = MenuEntryCard.new()
		# I dati vanno impostati PRIMA di aggiungere la carta all'albero:
		# appena entra nell'albero parte _ready(), che la disegna.
		card.card_size = card_size
		card.title_text = action.label
		card.art = action.art
		card.emblem = action.emblem
		card.enabled = action.enabled
		card.title_font_size = card_title_size
		card.index = i
		card.accent = (
			action.accent if action.has_custom_accent()
			else MenuEntryCard.palette_color(i)
		)

		_card_layer.add_child(card)
		card.card_pressed.connect(_on_card_pressed)
		card.card_dragged.connect(_on_card_dragged)
		card.card_released.connect(_on_card_released)
		# Invisibili finche' non e' partito l'ingresso: cosi' non si vede un
		# fotogramma con tutte le carte ammassate nell'angolo.
		card.modulate.a = 0.0
		_cards.append(card)

	_update_selection_labels()


## Aggiorna la voce "Riprendi" con quello che c'e' davvero sul disco.
##
## La descrizione della voce e' scritta a mano in [method build_default_actions],
## ma li' non si puo' sapere se un salvataggio esiste: si scopre solo adesso.
## Se non c'e' niente da riprendere la voce resta, ma lo dice.
func _refresh_continue_entry() -> void:
	var entry: MenuAction = null
	for action: MenuAction in _action_list:
		if action.id == &"continue":
			entry = action
			break

	if entry == null:
		return

	if not SaveGame.has_save():
		entry.description = "Nessun salvataggio da riprendere, per ora."
		return

	var description: String = SaveGame.describe()
	if description.is_empty():
		entry.description = "Continua dall'ultimo salvataggio."
	else:
		entry.description = "Ultimo salvataggio: %s." % description


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
## Cliccare la carta in cima equivale a sceglierla (come Invio); cliccare il
## bordo di una carta dietro fa passare quella in cima in fondo al mazzo.
func _on_card_pressed(card: MenuEntryCard) -> void:
	if _busy or not is_instance_valid(card):
		return

	if card.index == _selected:
		_activate_selected()
		return

	_move_selection(1)


## Il giocatore sta trascinando una carta: quella in cima lo segue.
##
## Si muove soprattutto in orizzontale e si inclina verso dove la tiri, come
## una carta che stai sfilando dal mazzo con il pollice.
func _on_card_dragged(card: MenuEntryCard, offset: Vector2) -> void:
	if _busy or card.index != _selected or _confirm_layer.visible:
		return

	var home: Dictionary = _target_for(0, card)
	card.kill_tween()
	card.position = home["position"] + Vector2(offset.x, offset.y * 0.3)
	card.rotation = deg_to_rad(clampf(offset.x * 0.05, -18.0, 18.0))


## Il giocatore ha lasciato la carta: se l'ha tirata abbastanza va in fondo
## al mazzo, altrimenti torna al suo posto.
func _on_card_released(card: MenuEntryCard, offset: Vector2) -> void:
	if _busy or card.index != _selected:
		return

	if absf(offset.x) >= swipe_threshold:
		_move_selection(1, _sign_of_float(offset.x))
	else:
		_layout_cards(true)


## Sceglie la voce che sta in cima al mazzo.
func _activate_selected() -> void:
	if _busy or _action_list.is_empty():
		return
	_play_click()
	_activate_action(_action_list[_selected])


## Sceglie una voce: quella in cima al mazzo o un pulsante del sottomenu.
func _activate_action(action: MenuAction) -> void:
	if not action.enabled:
		_show_toast("%s non e' disponibile." % action.label, 2.0)
		_refuse_current()
		return

	# Le voci con sotto-voci aprono (o richiudono) i loro pulsanti.
	if action.has_sub_actions():
		if _submenu_action == action:
			_close_submenu()
		else:
			_open_submenu(action)
		return

	# Le azioni che chiedono conferma si fermano qui. Per "Esci" la conferma
	# si puo' spegnere nelle impostazioni (Gioco → Chiedi conferma).
	var skip_confirm: bool = action.id == &"quit" and not bool(Settings.get_value("game", "confirm_quit", true))
	if action.needs_confirmation and not skip_confirm:
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
			# Una partita nuova riparte da zero anche se ce n'era una aperta.
			if action.id == &"new_game":
				GameState.new_game()
			_play_card_out(func() -> void: get_tree().change_scene_to_file(path))
			return

		# La scena indicata non esiste: meglio dirlo che non far nulla.
		_show_toast("Scena non trovata:\n%s" % action.scene_path, 4.0)
		push_warning("Menu: la voce '%s' punta a una scena inesistente: %s" % [
			action.label, action.scene_path,
		])
		_refuse_current()
		return

	# 2b. Opzioni: apre la schermata delle impostazioni, sopra al menu.
	if action.id == &"options":
		action_selected.emit(action.id)
		_cards[_selected].tremble()
		Settings.open_menu()
		return

	# 2c. Riprendi: ricarica l'ultimo salvataggio, se c'e'.
	if action.id == &"continue":
		if not SaveGame.has_save():
			_show_toast("Non c'e' ancora nessun salvataggio da riprendere.", 2.5)
			_refuse_current()
			return
		_play_card_out(func() -> void: SaveGame.load_into(get_tree()))
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
	_play_click()
	var action: MenuAction = _pending_action
	_pending_action = null
	_confirm_layer.visible = false

	if action != null:
		_execute_action(action)


func _on_confirm_no() -> void:
	_play_click()
	_pending_action = null
	_confirm_layer.visible = false


#endregion

#region Sottomenu


## Fa comparire, sotto la carta in cima, i pulsanti delle sotto-voci.
##
## I pulsanti entrano uno alla volta con un tremolio (vedi [method _pop_in]) e
## la carta stessa trema, come se li avesse "lasciati cadere" lei.
func _open_submenu(action: MenuAction) -> void:
	_close_submenu(false)
	_submenu_action = action

	_submenu_row = HBoxContainer.new()
	_submenu_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_submenu_row.add_theme_constant_override("separation", 24)
	_submenu_row.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_submenu_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_submenu_row)
	# Sotto al pannello di conferma: quello deve restare sopra a tutto.
	move_child(_submenu_row, _confirm_layer.get_index())

	var accent: Color = _cards[_selected].accent
	var order: int = 0
	for sub: MenuAction in action.sub_actions:
		if sub == null:
			continue
		var button: Button = _make_sub_button(sub, accent)
		_submenu_row.add_child(button)
		_pop_in(button, 0.06 + float(order) * 0.09)
		order += 1

	_layout_ui()
	_hint_label.text = "← →  scegli      Invio  conferma      Esc  indietro"
	_cards[_selected].tremble()
	_focus_sub_button(0)


## Richiude i pulsanti, se sono aperti.
func _close_submenu(animate: bool = true) -> void:
	if _submenu_row == null:
		return

	var row: HBoxContainer = _submenu_row
	_submenu_row = null
	_submenu_action = null
	_hint_label.text = _resolve_hint()
	_layout_ui()
	_update_selection_labels()

	if not animate:
		row.queue_free()
		return

	# Mentre svaniscono non devono piu' prendere click ne' focus.
	for child: Node in row.get_children():
		var button: Button = child as Button
		if button != null:
			button.release_focus()
			button.focus_mode = Control.FOCUS_NONE
			button.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var tween: Tween = row.create_tween()
	tween.set_parallel(true)
	tween.tween_property(row, "modulate:a", 0.0, 0.15)
	tween.tween_property(row, "position:y", row.position.y + 14.0, 0.15)
	tween.chain().tween_callback(row.queue_free)


## Un pulsante del sottomenu, in stile pixel: carta, bordo a inchiostro e
## un "labbro" sotto che si schiaccia quando lo premi.
func _make_sub_button(sub: MenuAction, accent: Color) -> Button:
	var button: Button = Button.new()
	button.text = sub.label
	button.disabled = not sub.enabled
	button.focus_mode = Control.FOCUS_ALL
	button.custom_minimum_size = Vector2(280.0, 72.0)
	button.add_theme_font_size_override("font_size", Settings.font_size(34))

	# Colori e bordi vengono dal Theme globale (Settings → UiThemeBuilder):
	# qui resta solo il contorno di focus del colore della voce.
	var focus: StyleBoxFlat = StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = accent.darkened(0.15)
	focus.set_border_width_all(UiThemeBuilder.BORDER)
	focus.set_expand_margin_all(6.0)
	focus.anti_aliasing = false
	button.add_theme_stylebox_override("focus", focus)

	var describe: Callable = func() -> void: _description_label.text = sub.description
	button.focus_entered.connect(describe)
	button.mouse_entered.connect(describe)
	# Il perno al centro, cosi' scala e rotazione non partono dall'angolo.
	button.resized.connect(func() -> void: button.pivot_offset = button.size * 0.5)
	button.pressed.connect(_on_sub_pressed.bind(button, sub))
	return button


## La comparsa di un pulsante: salta fuori un po' troppo grande, poi trema
## avanti e indietro e si assesta.
func _pop_in(button: Button, delay: float) -> void:
	var m: float = Settings.motion_scale()
	button.modulate.a = 0.0
	button.scale = Vector2.ONE * 0.4

	var tween: Tween = button.create_tween()
	tween.tween_interval(delay * m)
	tween.tween_property(button, "modulate:a", 1.0, 0.08 * m)
	tween.parallel().tween_property(button, "scale", Vector2.ONE * 1.12, 0.14 * m) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Il tremolio: oscillazioni sempre piu' piccole, mentre torna alla sua misura.
	var first: bool = true
	# Con "Riduci il movimento" niente tremolio: il pulsante compare e basta.
	var wobble: Array[float] = [8.0, -7.0, 5.0, -3.5, 2.0, -1.0, 0.0]
	if Settings.reduce_motion():
		wobble = [0.0]
	for degrees: float in wobble:
		tween.tween_property(button, "rotation", deg_to_rad(degrees), 0.04 * m)
		if first:
			tween.parallel().tween_property(button, "scale", Vector2.ONE, 0.24 * m) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			first = false


## Un pulsante del sottomenu e' stato premuto.
##
## Se porta a una schermata (o chiude il gioco) il sottomenu si chiude e la
## carta vola via come per le voci normali. Se non e' ancora pronto, trema
## solo il pulsante e il sottomenu resta aperto.
func _on_sub_pressed(button: Button, sub: MenuAction) -> void:
	if _busy:
		return

	_play_click()

	if sub.has_scene() or sub.has_sub_actions() or sub.needs_confirmation or sub.id == &"quit":
		_close_submenu()
		_activate_action(sub)
		return

	action_selected.emit(sub.id)
	if show_placeholder_message:
		_show_toast("%s: non e' ancora pronto." % sub.label, 2.5)
	_wobble(button)


## Il "no" di un pulsante: una scossa veloce.
func _wobble(button: Button) -> void:
	var tween: Tween = button.create_tween()
	for degrees: float in [-5.0, 5.0, -3.0, 0.0]:
		tween.tween_property(button, "rotation", deg_to_rad(degrees), 0.05)


## True se il focus della tastiera e' su uno dei pulsanti del sottomenu.
func _sub_button_has_focus() -> bool:
	if _submenu_row == null:
		return false
	var focused: Control = get_viewport().gui_get_focus_owner()
	return focused != null and focused.get_parent() == _submenu_row


## Sposta il focus fra i pulsanti del sottomenu.
##
## [param step] 0 = primo pulsante attivo, -1/+1 = quello a sinistra/destra.
func _focus_sub_button(step: int) -> void:
	if _submenu_row == null:
		return

	var buttons: Array[Button] = []
	for child: Node in _submenu_row.get_children():
		var button: Button = child as Button
		if button != null and not button.disabled:
			buttons.append(button)
	if buttons.is_empty():
		return

	_play_click(randf_range(0.96, 1.06))

	var current: int = -1
	for i: int in buttons.size():
		if buttons[i].has_focus():
			current = i
	var next: int = 0 if step == 0 or current < 0 else clampi(current + step, 0, buttons.size() - 1)
	buttons[next].call_deferred("grab_focus")


#endregion

#region Carosello


## Sposta la selezione di un posto.
##
## [b]Avanti[/b] ([param direction] = +1): la carta in cima esce di lato e
## passa in fondo al mazzo, e tutte le altre salgono di un posto.
## [b]Indietro[/b] (-1): la carta in fondo esce di lato e torna in cima.
##
## [param out_side] e' il lato da cui esce la carta: -1 sinistra, +1 destra.
## Quando trascini, e' il lato verso cui l'hai tirata.
func _move_selection(direction: int, out_side: float = -1.0) -> void:
	if _busy or _cards.size() < 2:
		return

	# Scorrere il mazzo chiude i pulsanti della carta che se ne va.
	_close_submenu()

	var count: int = _cards.size()
	var next: int = _selected

	# Salta le voci disabilitate: non ha senso fermarsi su una carta spenta.
	for _attempt: int in count:
		next = posmod(next + direction, count)
		if _action_list[next].enabled:
			break

	if next == _selected or not _action_list[next].enabled:
		return

	# La carta che "vola": quella che lascia la cima, o quella che ci arriva.
	var flying: MenuEntryCard = _cards[_selected] if direction > 0 else _cards[next]
	_selected = next
	# Il tono varia appena: scorrere tante carte non deve suonare meccanico.
	_play_click(randf_range(0.94, 1.08))
	_layout_cards(true, false, flying, direction, out_side)


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


## Quanto e' in fondo al mazzo una carta: 0 = in cima, 1 = subito dietro...
##
## Il mazzo gira: la carta dopo l'ultima e' di nuovo la prima, per questo
## quella in cima, quando scorri, finisce in fondo.
func _depth_of(card_index: int) -> int:
	return posmod(card_index - _selected, _cards.size())


## Dove va una carta, in base a quanto e' in fondo al mazzo.
##
## [b]Il trucco del mazzo in mano:[/b] ogni carta dietro spunta un po' in alto
## a destra, e' un filo piu' piccola, piu' scura e un po' storta. Basta questo
## perche' sembri un blocco di carte tenuto in mano e non una pila di riquadri.
func _target_for(depth: int, card: MenuEntryCard) -> Dictionary:
	var center: Vector2 = Vector2(size.x * 0.5, size.y * carousel_center_ratio)
	var shown: int = mini(depth, stack_depth)
	var shade: float = clampf(1.0 - stack_darken * float(shown), 0.3, 1.0)

	return {
		"position": center + stack_offset * float(shown) - card_size * 0.5,
		"scale": Vector2.ONE * (1.0 - stack_scale_step * float(shown)),
		# La carta in cima sta dritta: e' quella che stai guardando.
		"rotation": 0.0 if depth == 0 else deg_to_rad(_jitter_for(card)),
		# Le carte oltre [member stack_depth] restano nascoste dietro l'ultima.
		"color": Color(shade, shade, shade, 1.0 if depth <= stack_depth else 0.0),
		"focused": depth == 0,
	}


## L'inclinazione, sempre la stessa, di una carta quando sta dietro.
func _jitter_for(card: MenuEntryCard) -> float:
	var h: int = absi(card.title_text.hash()) + card.index * 31
	return (float(h % 1000) / 999.0 * 2.0 - 1.0) * stack_jitter


## Porta tutte le carte nella posizione che gli spetta.
##
## [param animate] false piazza tutto di colpo: serve al primo giro e quando
## cambia la dimensione della finestra.
## [param deal_in] true aggiunge il ritardo a scalare dell'ingresso iniziale.
## [param flying] e' la carta che passa dalla cima al fondo (o viceversa): lei
## non scorre e basta, esce di lato e rientra dall'altra parte del mazzo.
func _layout_cards(
	animate: bool,
	deal_in: bool = false,
	flying: MenuEntryCard = null,
	direction: int = 0,
	out_side: float = -1.0
) -> void:
	if _cards.is_empty():
		return
	if size.x < 10.0 or size.y < 10.0:
		return

	var count: int = _cards.size()
	for card: MenuEntryCard in _cards:
		if not is_instance_valid(card):
			continue
		var depth: int = _depth_of(card.index)
		var target: Dictionary = _target_for(depth, card)
		if animate and card == flying:
			_fly_card(card, target, direction, out_side)
		else:
			# All'ingresso escono prima le carte del fondo: il mazzo si forma
			# dal basso, come quando le raccogli una sull'altra.
			var order: int = count - 1 - depth if deal_in else depth
			_apply_target(card, target, animate, deal_in, order)

	_reorder_cards()

	# Mentre esce di lato, la carta che vola resta dove stava: sopra a tutte se
	# lascia la cima, sotto a tutte se arriva dal fondo. Cambia strato a meta'
	# del volo, in [method _fly_card].
	if animate and flying != null and is_instance_valid(flying):
		_card_layer.move_child(flying, _card_layer.get_child_count() - 1 if direction > 0 else 0)

	_update_selection_labels()


## Il volo di una carta da un capo all'altro del mazzo.
##
## Due tempi: prima esce di lato (sfilata dal mazzo), poi cambia strato e
## scivola nel suo nuovo posto. E' il cambio di strato a meta' strada che fa
## sembrare che la carta passi [i]dietro[/i] alle altre.
func _fly_card(card: MenuEntryCard, target: Dictionary, direction: int, out_side: float) -> void:
	card.kill_tween()

	var front: Dictionary = _target_for(0, card)
	var out_position: Vector2 = front["position"] + Vector2(out_side * card_size.x * 0.82, -card_size.y * 0.06)
	var half: float = slide_duration * 0.5
	var trans: Tween.TransitionType = Tween.TRANS_BACK if slide_overshoot else Tween.TRANS_CUBIC
	var final_color: Color = target["color"]
	var middle_color: Color = card.modulate.lerp(final_color, 0.5)
	var focused: bool = target["focused"]

	var tween: Tween = card.create_tween()
	card.set_tween(tween)
	tween.set_parallel(true)

	# --- 1. Fuori, di lato ---
	tween.tween_property(card, "position", out_position, half) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "rotation", deg_to_rad(out_side * 14.0), half) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "scale", Vector2.ONE, half)
	tween.tween_property(card, "modulate", middle_color, half)
	tween.tween_method(card.apply_accent, card.accent_mix, 0.0, half)

	# --- 2. Cambio di strato: dietro a tutte, o davanti a tutte ---
	tween.chain().tween_callback(func() -> void:
		if not is_instance_valid(card):
			return
		_card_layer.move_child(card, 0 if direction > 0 else _card_layer.get_child_count() - 1)
		card.set_focused(focused)
	)

	# --- 3. Dentro, al nuovo posto ---
	tween.chain().tween_property(card, "position", target["position"], half) \
		.set_trans(trans).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "rotation", target["rotation"], half) \
		.set_trans(trans).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "scale", target["scale"], half) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "modulate", final_color, half)
	tween.tween_method(card.apply_accent, 0.0, 1.0 if focused else 0.0, half)


## Applica a una carta la sua posizione, con o senza animazione.
func _apply_target(
	card: MenuEntryCard,
	target: Dictionary,
	animate: bool,
	deal_in: bool,
	order: int
) -> void:
	card.kill_tween()

	var color: Color = target["color"]
	var focused: bool = target["focused"]

	if not animate:
		card.position = target["position"]
		card.scale = target["scale"]
		card.rotation = target["rotation"]
		card.modulate = color
		card.set_focused(focused)
		card.apply_accent(1.0 if focused else 0.0)
		return

	var duration: float = deal_duration if deal_in else slide_duration
	var delay: float = float(order) * deal_stagger if deal_in else 0.0

	# TRANS_BACK fa "sforare" la carta un po' oltre la sua posizione e poi
	# tornare indietro: e' l'assestamento di una carta che si appoggia al mazzo.
	var trans: Tween.TransitionType = Tween.TRANS_BACK if slide_overshoot else Tween.TRANS_CUBIC

	var tween: Tween = card.create_tween()
	card.set_tween(tween)
	tween.set_parallel(true)

	tween.tween_property(card, "position", target["position"], duration) \
		.set_trans(trans).set_ease(Tween.EASE_OUT).set_delay(delay)
	tween.tween_property(card, "scale", target["scale"], duration) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(delay)
	tween.tween_property(card, "rotation", target["rotation"], duration) \
		.set_trans(trans).set_ease(Tween.EASE_OUT).set_delay(delay)

	# Il colore usa un'altra curva: con TRANS_BACK l'alfa andrebbe sopra 1
	# e si vedrebbe un lampo.
	tween.tween_property(card, "modulate", color, duration * 0.7) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT).set_delay(delay)

	# L'accensione del contorno arriva un attimo dopo la carta: sembra che la
	# carta si "apra" quando arriva in cima.
	tween.tween_method(card.apply_accent, card.accent_mix, 1.0 if focused else 0.0, duration * 0.9) \
		.set_delay(delay + 0.05)

	card.set_focused(focused)


## Mette le carte nell'albero nell'ordine giusto di disegno: prima quelle in
## fondo al mazzo, per ultima quella in cima.
func _reorder_cards() -> void:
	var ordered: Array[MenuEntryCard] = _cards.duplicate()
	ordered.sort_custom(_is_deeper_than)
	for i: int in range(ordered.size()):
		_card_layer.move_child(ordered[i], i)


func _is_deeper_than(a: MenuEntryCard, b: MenuEntryCard) -> bool:
	return _depth_of(a.index) > _depth_of(b.index)


## L'ingresso: le carte salgono dal basso una alla volta e si impilano in
## mano, come quando raccogli il mazzo dal tavolo.
func _play_intro() -> void:
	if size.x < 10.0 or size.y < 10.0:
		call_deferred("_play_intro")
		return

	_intro_done = true
	_layout_ui()

	for card: MenuEntryCard in _cards:
		if not is_instance_valid(card):
			continue
		card.position = _deck_position() - card_size * 0.5
		card.scale = Vector2.ONE * 0.9
		card.rotation = deg_to_rad(-18.0 + float(card.index % 5) * 9.0)
		card.modulate = Color(1, 1, 1, 0)
		card.set_focused(false)
		card.apply_accent(0.0)

	_layout_cards(true, true)
	_animate_in()


## Da dove arrivano le carte all'avvio: da sotto il bordo dello schermo.
func _deck_position() -> Vector2:
	return Vector2(size.x * 0.5, size.y + card_size.y * 0.6)


## La dissolvenza in ingresso dei testi.
func _animate_in() -> void:
	_title_label.modulate.a = 0.0
	_title_image.modulate.a = 0.0
	_description_label.modulate.a = 0.0

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_title_label, "modulate:a", 1.0, 0.5)
	tween.tween_property(_title_image, "modulate:a", 1.0, 0.55)
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


## Il segno di un numero: -1 se negativo, +1 altrimenti.
func _sign_of_float(value: float) -> float:
	return -1.0 if value < 0.0 else 1.0


## Mostra un messaggio in basso, che svanisce da solo.
func _show_toast(text: String, seconds: float) -> void:
	_toast_label.text = text
	_toast_time_left = seconds

	var tween: Tween = create_tween()
	tween.tween_property(_toast_label, "modulate:a", 1.0, 0.15)


func _hide_toast() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_toast_label, "modulate:a", 0.0, 0.35)


## Fa passare il tempo per il messaggio temporaneo e per la rotella.
func _process(delta: float) -> void:
	_scroll_cooldown = maxf(_scroll_cooldown - delta, 0.0)
	if _toast_time_left <= 0.0:
		return
	_toast_time_left -= delta
	if _toast_time_left <= 0.0:
		_hide_toast()


## Scorre il mazzo con la rotella del mouse o con due dita sul trackpad.
##
## Sta in _input e non in _unhandled_input di proposito: le carte usano
## MOUSE_FILTER_STOP per ricevere i click, e quello consumerebbe anche la
## rotella prima che arrivi qui.
##
## [b]La pausa fra uno scatto e l'altro[/b] ([member _scroll_cooldown]) serve
## al trackpad: un solo gesto manda decine di eventi, e senza pausa il mazzo
## girerebbe tutto in un colpo.
func _input(event: InputEvent) -> void:
	if _confirm_layer.visible or Settings.is_menu_open():
		return

	var pan: InputEventPanGesture = event as InputEventPanGesture
	if pan != null:
		_pan_accum += pan.delta.x + pan.delta.y
		if absf(_pan_accum) > 1.5 and _scroll_cooldown <= 0.0:
			_scroll_step(1 if _pan_accum > 0.0 else -1)
			_pan_accum = 0.0
		get_viewport().set_input_as_handled()
		return

	var wheel: InputEventMouseButton = event as InputEventMouseButton
	if wheel == null or not wheel.pressed:
		return

	var direction: int = 0
	match wheel.button_index:
		MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_RIGHT:
			direction = 1
		MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_LEFT:
			direction = -1
		_:
			return

	if _scroll_cooldown <= 0.0:
		_scroll_step(direction)
	get_viewport().set_input_as_handled()


## Uno scatto di rotella: sposta il mazzo e fa partire la pausa.
func _scroll_step(direction: int) -> void:
	_move_selection(direction)
	_scroll_cooldown = slide_duration * 0.6


#endregion

#region Input


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or Settings.is_menu_open():
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

	# Con i pulsanti aperti le frecce si muovono fra i pulsanti (ci pensa
	# Godot, con il focus) e Esc li richiude. Su e giu' non fanno niente:
	# scorrere il mazzo per sbaglio chiuderebbe il sottomenu.
	if _submenu_row != null:
		match key_event.keycode:
			KEY_ESCAPE:
				_close_submenu()
			KEY_A, KEY_LEFT:
				_focus_sub_button(-1)
			KEY_D, KEY_RIGHT:
				_focus_sub_button(1)
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				# Se un pulsante ha il focus, Invio e' suo: il Button lo "preme"
				# al rilascio del tasto, ma Godot fa arrivare la pressione anche
				# qui. Senza questo controllo richiuderemmo il sottomenu prima
				# che il pulsante scatti.
				if not _sub_button_has_focus():
					_activate_selected()
			_:
				return
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
	return "← →  scorri il mazzo      trascina la carta per passarla in fondo      Invio  scegli      Esc  esci"


## La riga in fondo: quella impostata, oppure una generica.
func _resolve_footer() -> String:
	if not footer.strip_edges().is_empty():
		return footer
	return "Godot %s" % Engine.get_version_info().get("string", "")


## Legge dalle impostazioni tutto cio' che il giocatore puo' personalizzare
## del menu (scheda Tema): colori, titoli, mazzo e velocita' delle animazioni.
##
## [b]Le impostazioni vincono sull'inspector:[/b] l'inspector da' i valori di
## partenza (e il titolo, se il giocatore non ne sceglie uno), il giocatore
## decide il resto.
func _read_settings() -> void:
	background_color = Settings.color("background")
	accent_color = Settings.color("accent")
	_text_color = Settings.color("text")

	var custom_title: String = str(Settings.get_value("theme", "menu_title", "")).strip_edges()
	title = custom_title if not custom_title.is_empty() else str(_inspector.get("title", ""))

	ambient_cards = bool(Settings.get_value("theme", "ambient_cards", ambient_cards))
	stack_jitter = float(Settings.get_value("theme", "stack_jitter", stack_jitter))
	stack_depth = int(Settings.get_value("theme", "stack_depth", stack_depth))

	var m: float = Settings.motion_scale()
	slide_duration = float(_inspector["slide_duration"]) * m
	deal_duration = float(_inspector["deal_duration"]) * m
	deal_stagger = float(_inspector["deal_stagger"]) * m
	slide_overshoot = bool(_inspector["slide_overshoot"]) and not Settings.reduce_motion()


## Il tema e' cambiato: ricostruiamo il menu con i colori nuovi, senza rifare
## l'ingresso e lasciando in cima la stessa carta.
func _on_theme_changed() -> void:
	_read_settings()
	if not _intro_done:
		return

	var keep: int = _selected
	_close_submenu(false)
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	_cards.clear()
	_busy = false

	_build_ui()
	_build_cards()
	# Anche i lettori audio erano figli di questo nodo: vanno rifatti, o dopo
	# un cambio di tema il menu resta muto.
	_setup_audio()
	_selected = clampi(keep, 0, maxi(_cards.size() - 1, 0))
	_layout_ui()
	_layout_cards(false)


## La finestra ha cambiato dimensione: rimettiamo a posto tutto.
func _on_resized() -> void:
	_layout_ui()
	if _intro_done:
		_layout_cards(false)


#endregion

#region Audio


## Crea (o ricrea) i lettori audio del menu.
##
## [b]Va richiamata dopo ogni ricostruzione della UI:[/b] anche i lettori sono
## figli di questo nodo, quindi un cambio di tema li cancellerebbe insieme al
## resto. Richiamandola si riparte puliti, senza musica doppia.
func _setup_audio() -> void:
	for player: Node in [_music, _click]:
		if is_instance_valid(player):
			player.queue_free()
	_music = null
	_click = null

	var music: AudioStream = _load_audio(music_path)
	if music != null:
		# Il loop e' una proprieta' della risorsa, non del lettore: senza questo
		# la musica del menu si fermerebbe alla fine del brano.
		_enable_loop(music)
		_music = AudioStreamPlayer.new()
		_music.name = "MenuMusic"
		_music.bus = &"Music"
		_music.volume_db = music_volume_db
		_music.stream = music
		add_child(_music)
		_music.play()

	var click: AudioStream = _load_audio(click_path)
	if click != null:
		_click = AudioStreamPlayer.new()
		_click.name = "MenuClick"
		_click.bus = &"UI"
		_click.volume_db = click_volume_db
		_click.stream = click
		add_child(_click)


## Carica un file audio, con un avviso chiaro se non c'e'.
##
## [b]Nota:[/b] i file appena aggiunti al progetto vanno importati da Godot una
## volta. Finche' l'editor non li vede, [method ResourceLoader.exists] dice di no.
func _load_audio(path: String) -> AudioStream:
	if path.strip_edges().is_empty():
		return null

	if not ResourceLoader.exists(path):
		push_warning("Menu: audio non trovato: %s\nApri l'editor di Godot una volta: importa lui i file nuovi." % path)
		return null

	return load(path) as AudioStream


## Fa ripetere un brano all'infinito.
##
## Il loop e' una proprieta' [b]della risorsa[/b], non del lettore, e il campo ha
## un nome diverso per ogni formato: da qui il controllo sul tipo.
static func _enable_loop(stream: AudioStream) -> void:
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD


## Il "toc" dei menu: scorrendo il mazzo e premendo qualsiasi cosa.
##
## [param pitch] alza o abbassa il tono: lo scorrimento lo varia appena, cosi'
## passare su tante carte non diventa un suono identico ripetuto.
func _play_click(pitch: float = 1.0) -> void:
	if _click == null or _click.stream == null:
		return
	_click.pitch_scale = pitch
	_click.play()


#endregion
