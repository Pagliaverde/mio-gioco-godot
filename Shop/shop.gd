## Il negozio: compra carte con le monete che guadagni combattendo.
##
## [b]Si apre in due modi:[/b]
## [codeblock]
##   dal menu principale    ->  scena a se', pulsante "Torna al menu"
##   dal banco sulla mappa  ->  un pannello sopra il gioco, pulsante "Chiudi"
## [/codeblock]
## Nel secondo caso il gioco si ferma ([code]get_tree().paused = true[/code])
## mentre il negozio e' aperto, come fa il menu di pausa: il personaggio non
## cammina e nessuno si muove. Vedi [ShopBooth].
##
## [b]Com'e' fatta la schermata:[/b] un velo scuro, un pannello bordato al
## centro (lo stesso schema delle impostazioni), e dentro la vetrina divisa in
## gruppi per rarita'. Le carte sono [CardView], cioe' le stesse che si vedono
## in battaglia: il negozio non disegna carte sue.
##
## [b]Tutto in codice:[/b] [code]Shop/shop.tscn[/code] contiene solo questo script.
##
## Vedi [code]Shop/README.md[/code].
class_name ShopScreen extends Control


## Emesso quando il negozio si chiude da solo (modalita' sovrapposta).
##
signal closed()


## Il menu a cui tornare, quando il negozio e' una scena a se'.
const MENU_SCENE := "res://Menu/main_menu.tscn"

## La scena da istanziare per aprirlo sopra a un'altra scena.
const SCENE_PATH := "res://Shop/shop.tscn"

## Il livello del negozio sovrapposto alla mappa.
##
## Sopra al gioco (0) e sotto al menu di pausa (110), come il balloon dei
## dialoghi (100). Vedi [Pause], che usa 110.
const OVERLAY_LAYER := 95

## Il testo che sta in fondo finche' non succede niente.
const DEFAULT_FEEDBACK := "Clicca una carta per leggerne i dettagli e il prezzo."

## Quanto resta a schermo un messaggio di acquisto, in secondi.
const FEEDBACK_TIME := 2.6

## Quante carte per riga.
const COLUMNS := 5

## Misura di una carta in vetrina.
##
## Piu' piccola di quelle in battaglia: cosi' se ne vedono cinque per riga e la
## vetrina si legge come un banco, non come una pila.
const CARD_WIDTH := 190
const CARD_HEIGHT := 268

## La carta grande dei dettagli, e di quanto cresce il suo testo.
##
## [member CardView.font_scale] e' la parte che conta: senza, ingrandire la
## carta ingrandirebbe solo la cornice, lasciando il testo a 13 pixel. Vedi
## [CardView._apply_scale].
const DETAIL_CARD_WIDTH := 340
const DETAIL_CARD_HEIGHT := 480
const DETAIL_FONT_SCALE := 1.5
const DETAIL_WIDTH := 560

## Il pannello: grande, ma mai piu' grande dello schermo (anche con la scala
## interfaccia alta).
const PANEL_MAX := Vector2(1500.0, 880.0)
const PANEL_RATIO := Vector2(0.94, 0.92)

## Il colore del prezzo quando non puoi permettertelo.
##
## [b]Rosso scuro, non brillante:[/b] il prezzo sta su un cartellino di carta
## chiara, e un rosso acceso ci si perderebbe dentro. Il messaggio in fondo
## invece sta sul pannello scuro e usa [constant BAD_NEWS].
const UNAFFORDABLE := Color(0.70, 0.16, 0.14)

## Il colore di un rifiuto, sul pannello scuro.
const BAD_NEWS := Color(0.95, 0.42, 0.40)


## [b]Come e' aperto:[/b] [code]true[/code] come scena a se' (dal menu),
## [code]false[/code] sovrapposto al gioco (dal banco sulla mappa).
var standalone: bool = true


var _panel: PanelContainer
var _coins_label: Label
var _owned_label: Label
var _feedback: Label
var _feedback_timer: Timer
var _groups_box: VBoxContainer

## Quante carte ci sono in vetrina. Si conta una volta sola, costruendo: cosi'
## un acquisto non rilegge il database delle carte da disco.
var _total_offers: int = 0

## Il pannello dei dettagli, se e' aperto. Uno per volta.
var _detail: Control = null

## La carta che il pannello sta mostrando, e il suo prezzo.
var _detail_card: CardData = null
var _detail_price: int = 0
var _detail_price_label: Label = null
var _detail_button: Button = null

## Una voce per carta: [code]{ "view", "button", "price_label", "price" }[/code].
##
## Serve a [b]rinfrescare una voce sola[/b] dopo un acquisto, invece di
## ricostruire tutte e trentasette le carte (che vorrebbe dire ridisegnare
## trentasette illustrazioni).
var _tiles: Dictionary = {}


## Apre il negozio [b]sopra[/b] la scena corrente, col gioco fermo.
##
## Ritorna la schermata, cosi' chi la apre puo' collegarsi a [signal closed].
##
## [b]Perche' un [CanvasLayer]:[/b] la mappa ha una [Camera2D] che segue il
## personaggio, e un [Control] figlio della mappa verrebbe trascinato via con
## lei. Su un livello a parte lo schermo resta fermo. Fa lo stesso il menu di
## pausa.
static func open_over(parent: Node) -> ShopScreen:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.name = "ShopLayer"
	layer.layer = OVERLAY_LAYER
	parent.add_child(layer)

	var scene: PackedScene = load(SCENE_PATH) as PackedScene
	var screen: ShopScreen = scene.instantiate() as ShopScreen
	screen.standalone = false
	layer.add_child(screen)
	return screen


func _ready() -> void:
	# Deve rispondere ai click anche col gioco in pausa: e' il motivo per cui
	# esiste la modalita' sovrapposta.
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Esc e' nostro, in [b]entrambe[/b] le modalita': chiude i dettagli, poi il
	# negozio. Senza questo, dal menu principale Esc aprirebbe il menu di pausa
	# [i]sopra[/i] al negozio. Vedi [method _unhandled_input].
	Pause.enabled = false

	if not standalone:
		# Come il menu di pausa: ferma il mondo mentre si compra.
		get_tree().paused = true

	# La prima volta in assoluto il portafoglio non esiste: qui prende le monete
	# di partenza. Se esiste gia', non fa niente.
	ShopWallet.ensure_started(ShopCatalog.STARTING_COINS)

	_feedback_timer = Timer.new()
	_feedback_timer.one_shot = true
	_feedback_timer.timeout.connect(_clear_feedback)
	add_child(_feedback_timer)

	_build()
	_build_groups()
	_refresh()
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

	var screen: Vector2 = get_viewport_rect().size
	var panel_size: Vector2 = Vector2(
		minf(PANEL_MAX.x, screen.x * PANEL_RATIO.x),
		minf(PANEL_MAX.y, screen.y * PANEL_RATIO.y)
	)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = panel_size
	center.add_child(_panel)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	_panel.add_child(column)

	column.add_child(_build_header())
	column.add_child(_build_valance(panel_size.x))
	column.add_child(_build_intro())

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)

	var margin: MarginContainer = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 4)
	scroll.add_child(margin)

	_groups_box = VBoxContainer.new()
	_groups_box.add_theme_constant_override("separation", 22)
	margin.add_child(_groups_box)

	column.add_child(_build_footer())


## Titolo a sinistra, borsa a destra.
func _build_header() -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)

	var title: Label = Label.new()
	title.theme_type_variation = &"TitleLabel"
	title.text = "Negozio"
	row.add_child(title)

	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(spacer)

	row.add_child(_build_purse())
	return row


## La borsa: la moneta e il saldo, dentro un cartellino di carta.
func _build_purse() -> Control:
	var tag: PanelContainer = PanelContainer.new()
	tag.theme_type_variation = &"CardPanel"
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	tag.add_child(row)

	row.add_child(_coin_icon(36))

	_coins_label = Label.new()
	_coins_label.add_theme_font_size_override("font_size", Settings.font_size(36))
	# Sta su un cartellino di carta: l'inchiostro, non il testo chiaro del tema.
	_coins_label.add_theme_color_override("font_color", Settings.color("ink"))
	_coins_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_coins_label)

	return tag


## Il festone della bancarella, sotto al titolo.
func _build_valance(panel_width: float) -> Control:
	const TILE := 16
	var rect: TextureRect = TextureRect.new()
	rect.texture = ShopArt.valance(
		maxi(int(panel_width / float(TILE)), 8),
		TILE,
		18,
		Settings.color("accent"),
		Settings.color("panel").lightened(0.12),
		Settings.color("ink")
	)
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.custom_minimum_size = Vector2(0, 18)
	rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


## La riga di spiegazione: diventa il messaggio di acquisto e poi torna com'era.
func _build_intro() -> Control:
	_feedback = Label.new()
	_feedback.theme_type_variation = &"DimLabel"
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_feedback.text = DEFAULT_FEEDBACK
	return _feedback


func _build_footer() -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)

	_owned_label = Label.new()
	_owned_label.theme_type_variation = &"DimLabel"
	_owned_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_owned_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_owned_label)

	var back: Button = Button.new()
	back.text = "Torna al menu" if standalone else "Chiudi"
	back.focus_mode = Control.FOCUS_NONE
	back.pressed.connect(_on_back_pressed)
	row.add_child(back)

	return row


## I gruppi per rarita': un'intestazione colorata e una griglia di carte.
func _build_groups() -> void:
	for child: Node in _groups_box.get_children():
		_groups_box.remove_child(child)
		child.queue_free()
	_tiles.clear()
	_total_offers = 0

	for group: Dictionary in ShopCatalog.groups():
		var profile: RarityProfile = group["profile"]
		var offers: Array = group["offers"]
		_total_offers += offers.size()

		_groups_box.add_child(_build_group_header(profile, offers.size()))

		var grid: GridContainer = GridContainer.new()
		grid.columns = COLUMNS
		grid.add_theme_constant_override("h_separation", 16)
		grid.add_theme_constant_override("v_separation", 20)
		_groups_box.add_child(grid)

		for offer: Dictionary in offers:
			grid.add_child(_make_offer(offer))


func _build_group_header(profile: RarityProfile, count: int) -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	# La barretta del colore della rarita': la stessa che usa la cornice delle
	# carte, cosi' si capisce a colpo d'occhio che fascia stai guardando.
	var bar: ColorRect = ColorRect.new()
	bar.color = profile.border_color
	bar.custom_minimum_size = Vector2(6, 0)
	bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(bar)

	var title: Label = Label.new()
	title.theme_type_variation = &"SectionLabel"
	title.text = profile.display_name
	row.add_child(title)

	var count_label: Label = Label.new()
	count_label.theme_type_variation = &"DimLabel"
	count_label.add_theme_font_size_override("font_size", Settings.font_size(22))
	count_label.text = "%d carte, %d-%d mana" % [count, profile.cost_min, profile.cost_max]
	count_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(count_label)

	return row


## Una voce di vetrina: la carta, il prezzo, il pulsante. Tutto su un cartellino,
## come una carta appoggiata sul banco.
func _make_offer(offer: Dictionary) -> Control:
	var card: CardData = offer["card"]
	var price: int = int(offer["price"])

	var frame: PanelContainer = PanelContainer.new()
	frame.theme_type_variation = &"CardPanel"
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	frame.add_child(box)

	var view: CardView = CardView.new()
	view.card_width = CARD_WIDTH
	view.card_height = CARD_HEIGHT
	view.art_height = int(float(CARD_HEIGHT) * 0.36)
	view.card = card
	box.add_child(view)

	# L'area che cattura il click, [b]sopra[/b] alla carta. Non e' la carta a
	# riceverlo: dentro ci sono etichette e illustrazioni, e una di quelle
	# potrebbe mangiarsi il click prima che arrivi in fondo. Un [Control]
	# trasparente a tutta carta non disegna niente e li copre tutti.
	var hit: Control = Control.new()
	hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hit.mouse_filter = Control.MOUSE_FILTER_STOP
	hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hit.gui_input.connect(_on_card_clicked.bind(card))
	view.add_child(hit)

	var price_row: HBoxContainer = HBoxContainer.new()
	price_row.alignment = BoxContainer.ALIGNMENT_CENTER
	price_row.add_theme_constant_override("separation", 8)
	box.add_child(price_row)

	price_row.add_child(_coin_icon(24))

	var price_label: Label = Label.new()
	price_label.text = str(price)
	price_label.add_theme_font_size_override("font_size", Settings.font_size(28))
	price_row.add_child(price_label)

	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(CARD_WIDTH, 0)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(_on_buy_pressed.bind(card, price))
	box.add_child(button)

	_tiles[card.id] = {
		"view": view,
		"button": button,
		"price_label": price_label,
		"price": price,
	}

	_style_tile(card.id)
	return frame


## Mette a posto una voce: comprata, oppure comprabile o troppo cara.
func _style_tile(card_id: StringName) -> void:
	var tile: Dictionary = _tiles.get(card_id, {})
	if tile.is_empty():
		return

	var view: CardView = tile["view"]
	var button: Button = tile["button"]
	var price_label: Label = tile["price_label"]
	var price: int = int(tile["price"])

	if ShopWallet.owns(card_id):
		button.text = "Acquistata"
		button.disabled = true
		# Sbiadita: e' tua, non c'e' piu' niente da fare qui.
		view.modulate = Color(1, 1, 1, 0.42)
		price_label.add_theme_color_override("font_color", Settings.color("ink").lerp(Settings.color("paper"), 0.55))
		return

	button.text = "Compra"
	button.disabled = false
	view.modulate = Color.WHITE

	# Il prezzo in rosso quando non basta: si vede prima di provarci.
	var affordable: bool = ShopWallet.coins() >= price
	price_label.add_theme_color_override("font_color",
		Settings.color("ink") if affordable else UNAFFORDABLE)


## Il colore della cornice di una rarita'.
##
## [b]E' lo stesso che usa [CardView][/b] per il bordo della carta: le due
## schermate devono raccontare la stessa cosa con lo stesso colore.
func _rarity_color(rarity: CardTypes.Rarity) -> Color:
	var profile: RarityProfile = RarityTable.load_default().get_profile(rarity)
	if profile != null:
		return profile.border_color
	return Settings.color("accent")


## La moneta, alta circa [param pixels] pixel.
##
## La matrice e' 12x12, quindi la scala e' [i]pixel per punto[/i] e si arrotonda:
## cosi' la moneta resta squadrata invece di sfuocarsi, e non si sbaglia
## dimensione scrivendo il numero dei pixel finali.
func _coin_icon(pixels: int) -> TextureRect:
	var scale: int = maxi(int(round(float(pixels) / 12.0)), 1)
	var drawn: int = 12 * scale

	var icon: TextureRect = TextureRect.new()
	icon.texture = ShopArt.coin(scale, Settings.color("accent"), Settings.color("ink"))
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.custom_minimum_size = Vector2(drawn, drawn)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


#endregion

#region Dettagli di una carta


## Cliccando una carta in vetrina: la mostra grande, con la descrizione per
## esteso e il prezzo.
##
## [b]Perche' serve:[/b] a 190 pixel di larghezza il testo della carta e' di 13
## pixel, e la descrizione viene tagliata. In vetrina basta per riconoscere la
## carta, non per [i]decidere[/i] se comprarla.
func _on_card_clicked(event: InputEvent, card: CardData) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	get_viewport().set_input_as_handled()
	_open_detail(card)


func _open_detail(card: CardData) -> void:
	if is_instance_valid(_detail):
		_detail.queue_free()
		_detail = null

	_detail_card = card
	_detail_price = ShopCatalog.price_of(card)

	_detail = Control.new()
	_detail.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Ferma i click: sotto c'e' la vetrina, e non deve reagire.
	_detail.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_detail)

	# Il velo: piu' scuro di quello della vetrina, cosi' la carta viene avanti.
	# Cliccarlo chiude, come in qualsiasi finestra.
	var veil: ColorRect = ColorRect.new()
	veil.color = Color(0, 0, 0, 0.82)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	veil.gui_input.connect(_on_detail_veil_input)
	_detail.add_child(veil)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail.add_child(center)

	var panel: PanelContainer = PanelContainer.new()
	center.add_child(panel)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 28)
	panel.add_child(row)

	# A sinistra: la carta grande. E' la stessa CardView della battaglia, solo
	# con il testo ingrandito.
	var view: CardView = CardView.new()
	view.card_width = DETAIL_CARD_WIDTH
	view.card_height = DETAIL_CARD_HEIGHT
	view.art_height = int(float(DETAIL_CARD_HEIGHT) * 0.40)
	view.font_scale = DETAIL_FONT_SCALE
	view.card = card
	row.add_child(view)

	row.add_child(_build_detail_info())

	_pop_in_control(_detail, panel)


func _build_detail_info() -> Control:
	var column: VBoxContainer = VBoxContainer.new()
	column.custom_minimum_size = Vector2(DETAIL_WIDTH, 0)
	column.add_theme_constant_override("separation", 16)
	column.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var name: Label = Label.new()
	name.theme_type_variation = &"TitleLabel"
	name.text = _detail_card.display_name
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(name)

	var element_color: Color = CardTypes.element_color(_detail_card.element)
	column.add_child(_detail_row("Elemento", CardTypes.element_name(_detail_card.element), element_color))
	column.add_child(_detail_row("Costo", "%d mana" % _detail_card.cost, Settings.color("text")))
	column.add_child(_detail_row(
		"Rarita'", CardTypes.rarity_name(_detail_card.rarity), _rarity_color(_detail_card.rarity)
	))

	var separator: HSeparator = HSeparator.new()
	column.add_child(separator)

	var heading: Label = Label.new()
	heading.theme_type_variation = &"SectionLabel"
	heading.text = "Cosa fa"
	column.add_child(heading)

	var description: Label = Label.new()
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", Settings.font_size(26))
	var text: String = _detail_card.get_description()
	description.text = text if not text.is_empty() else "(nessun effetto)"
	column.add_child(description)

	column.add_child(_build_detail_buy())

	var close: Button = Button.new()
	close.text = "Chiudi"
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(_close_detail)
	column.add_child(close)

	return column


## Una riga "Etichetta: valore" dei dettagli.
func _detail_row(label_text: String, value: String, color: Color) -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)

	var label: Label = Label.new()
	label.theme_type_variation = &"DimLabel"
	label.text = label_text
	label.custom_minimum_size = Vector2(150, 0)
	label.add_theme_font_size_override("font_size", Settings.font_size(24))
	row.add_child(label)

	var text: Label = Label.new()
	text.text = value
	text.add_theme_color_override("font_color", color)
	text.add_theme_font_size_override("font_size", Settings.font_size(24))
	row.add_child(text)

	return row


## Il prezzo e il pulsante d'acquisto, nel pannello dei dettagli.
func _build_detail_buy() -> Control:
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)

	row.add_child(_coin_icon(36))

	_detail_price_label = Label.new()
	_detail_price_label.add_theme_font_size_override("font_size", Settings.font_size(40))
	_detail_price_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_detail_price_label)

	var coins: Label = Label.new()
	coins.theme_type_variation = &"DimLabel"
	coins.text = "monete"
	coins.add_theme_font_size_override("font_size", Settings.font_size(24))
	coins.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(coins)

	_detail_button = Button.new()
	_detail_button.custom_minimum_size = Vector2(DETAIL_WIDTH, 0)
	_detail_button.focus_mode = Control.FOCUS_NONE
	_detail_button.pressed.connect(_on_buy_pressed.bind(_detail_card, _detail_price))
	box.add_child(_detail_button)

	_refresh_detail()
	return box


## Aggiorna il prezzo e il pulsante dei dettagli: comprata, oppure comprabile o
## troppo cara. Stessa logica della vetrina, misure diverse.
func _refresh_detail() -> void:
	if _detail_price_label == null or _detail_button == null or _detail_card == null:
		return

	_detail_price_label.text = str(_detail_price)

	if ShopWallet.owns(_detail_card.id):
		_detail_button.text = "Acquistata"
		_detail_button.disabled = true
		_detail_price_label.add_theme_color_override("font_color", Settings.color("text").darkened(0.4))
		return

	_detail_button.text = "Compra"
	_detail_button.disabled = false
	var affordable: bool = ShopWallet.coins() >= _detail_price
	_detail_price_label.add_theme_color_override("font_color",
		Settings.color("text") if affordable else BAD_NEWS)


func _close_detail() -> void:
	if is_instance_valid(_detail):
		_detail.queue_free()
	_detail = null
	_detail_card = null
	_detail_price_label = null
	_detail_button = null


func _on_detail_veil_input(event: InputEvent) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	_close_detail()


## Esc: chiude i dettagli se sono aperti, altrimenti il negozio.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"ui_cancel"):
		return

	if is_instance_valid(_detail):
		_close_detail()
	else:
		_on_back_pressed()
	get_viewport().set_input_as_handled()


#endregion

#region Rinfrescare


func _refresh() -> void:
	_coins_label.text = str(ShopWallet.coins())
	_owned_label.text = "Possiedi %d carte su %d." % [
		ShopWallet.owned_count(), _total_offers,
	]

	for key: Variant in _tiles:
		var card_id: StringName = key
		_style_tile(card_id)

	# Se i dettagli sono aperti, anche li' il prezzo e' cambiato.
	_refresh_detail()


## Mostra un messaggio in fondo. [param bad] lo colora di rosso (un rifiuto).
##
## [b]Niente BBCode:[/b] e' una [Label] semplice, non una [RichTextLabel],
## quindi le parentesi quadre si vedrebbero scritte.
func _say(text: String, bad: bool) -> void:
	_feedback.text = text
	_feedback.remove_theme_color_override("font_color")
	_feedback.add_theme_color_override("font_color",
		BAD_NEWS if bad else Settings.color("accent"))
	_feedback_timer.start(FEEDBACK_TIME)


func _clear_feedback() -> void:
	_feedback.text = DEFAULT_FEEDBACK
	_feedback.remove_theme_color_override("font_color")


#endregion

#region Azioni


func _on_buy_pressed(card: CardData, price: int) -> void:
	if ShopWallet.owns(card.id):
		return

	if not ShopWallet.spend(price):
		var missing: int = price - ShopWallet.coins()
		if missing == 1:
			_say("Ti manca 1 moneta per \"%s\". Vinci una scena per guadagnarla." % card.display_name, true)
		else:
			_say("Ti mancano %d monete per \"%s\". Vinci una scena per guadagnarle." % [
				missing, card.display_name,
			], true)
		return

	ShopWallet.own(card.id)
	_say("\"%s\" e' tua, per %d monete." % [card.display_name, price], false)

	# Le monete sono cambiate: si aggiornano i saldi e i prezzi di [b]tutte[/b]
	# le voci (quelle che ora non puoi piu' permetterti devono arrossire), ma
	# senza ridisegnare nessuna illustrazione.
	_refresh()


func _on_back_pressed() -> void:
	if standalone:
		get_tree().change_scene_to_file(MENU_SCENE)
		return

	# Sovrapposto al gioco: si fa da parte e ridà il mondo com'era. La pausa e
	# il tasto Esc li rimette [method _exit_tree], cosi' non ci sono due posti
	# che devono ricordarsi di farlo.
	closed.emit()

	# Sopra la mappa la schermata vive dentro un [CanvasLayer]: va liberato
	# quello, non solo se stessa.
	var layer: Node = get_parent()
	if layer is CanvasLayer:
		layer.queue_free()
	else:
		queue_free()


## Uscendo si rimette tutto com'era, [b]comunque[/b] si esca: col pulsante,
## con Esc, o perche' qualcuno ha cambiato scena.
##
## Senza questo, se il negozio venisse liberato mentre il gioco e' fermo, il
## mondo resterebbe in pausa per sempre.
func _exit_tree() -> void:
	Pause.enabled = true

	if standalone:
		return
	var tree: SceneTree = get_tree()
	if tree != null:
		tree.paused = false


func _pop_in() -> void:
	_pop_in_control(self, _panel)


## L'animazione di comparsa: il velo sfuma, il pannello sboccia da 0.94 a 1.
##
## [param holder] e' chi porta il velo (tutta la schermata), [param panel] il
## riquadro che deve crescere. Vale sia per la vetrina sia per i dettagli.
func _pop_in_control(holder: Control, panel: Control) -> void:
	var speed: float = Settings.motion_scale()
	holder.modulate.a = 0.0
	panel.scale = Vector2.ONE * 0.94

	# Il perno: il pannello deve allargarsi dal suo centro, non dall'angolo.
	# La vetrina ha una misura sua (custom_minimum_size); i dettagli no, perche'
	# sono grandi quanto il loro contenuto, e la misura arriva al primo giro di
	# layout. Quindi li' il perno si fissa quando il pannello ha una dimensione.
	if panel.custom_minimum_size == Vector2.ZERO:
		panel.resized.connect(func() -> void: panel.pivot_offset = panel.size * 0.5, CONNECT_ONE_SHOT)
	else:
		panel.pivot_offset = panel.custom_minimum_size * 0.5

	var tween: Tween = holder.create_tween().set_parallel(true)
	tween.tween_property(holder, "modulate:a", 1.0, 0.18 * speed)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.25 * speed) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


#endregion
