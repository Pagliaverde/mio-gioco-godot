## Dipinge l'illustrazione di una carta in pixel art, a partire da cio' che
## la carta [i]fa[/i]: elemento, effetti, costo e rarita'.
##
## [b]Perche' in codice:[/b] ogni carta ha cosi' un'immagine sua, diversa da
## tutte le altre, senza disegnarne quaranta a mano. L'id della carta fa da
## seme: la stessa carta ha sempre la stessa immagine, e una carta nuova ne
## riceve una nuova da sola.
##
## [b]Cosa decide cosa:[/b]
## [br]- l'[b]elemento[/b] sceglie i colori e lo sfondo (braci, cristalli,
##   bolle, tempesta, foglie, stelle, pergamena);
## [br]- il [b]primo effetto[/b] sceglie il soggetto: fiamma, lancia di ghiaccio,
##   fulmine, artiglio, scudo, cuore, fiala, calderone, stendardo...;
## [br]- gli [b]altri effetti[/b] aggiungono un dettaglio (un simbolo di status, un
##   secondo oggetto);
## [br]- il [b]costo[/b] decide quanto e' grande il soggetto;
## [br]- la [b]rarita'[/b] aggiunge raggi, scintille, cornici d'oro.
##
## Le immagini si possono anche esportare come PNG in [code]Cards/art/[/code]
## con [code]Cards/tools/generate_card_art.gd[/code], per ritoccarle a mano.
@tool
class_name CardArtPainter extends RefCounted


## Dimensione dell'illustrazione in pixel (4:3, come consiglia Cards/art/README.md).
const WIDTH: int = 64
const HEIGHT: int = 48

## Matrice di Bayer 4x4 per il dithering.
const BAYER4: Array[int] = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]

## Le immagini gia' dipinte, per id: dipingere costa, mostrare no.
static var _cache: Dictionary = {}

## La variante del soggetto per le carte del gioco, scelta a mano perche'
## il disegno dica cio' che la carta fa: Fendente di Fiamma e' una spada
## infuocata, Vampa una palla di fuoco, Fenice un uccello di fiamme.
## Una carta che non e' qui prende una variante dal suo id.
const VARIANTS: Dictionary = {
	&"fire_flame_slash": 2, &"fire_blaze": 1, &"fire_inferno": 0, &"fire_conflagration": 1,
	&"fire_phoenix": 3, &"fire_ember": 0, &"fire_flame_guard": 0,
	&"ice_lance": 0, &"ice_blizzard": 1, &"ice_absolute_zero": 2, &"ice_glacier_tomb": 2,
	&"ice_barrier": 1, &"ice_frost_bite": 0,
	&"poison_acid_spit": 1, &"poison_plague": 2, &"poison_miasma": 2, &"poison_toxic_dart": 2,
	&"poison_venom_cloud": 1, &"poison_plague_lord": 0,
	&"lightning_static_bolt": 0, &"lightning_thunder_strike": 1, &"lightning_storm_surge": 0,
	&"lightning_storm_herald": 2, &"lightning_shield_arc": 1,
	&"nature_forest_wrath": 1, &"nature_barrier": 2, &"nature_thorn_whip": 0,
	&"nature_rejuvenate": 0, &"nature_life_bloom": 1, &"nature_world_tree": 3,
	&"dark_drain": 1, &"dark_sacrifice": 0, &"dark_blood_pact": 2, &"dark_curse": 1,
	&"support_bulwark": 0, &"support_iron_wall": 2, &"support_reinforce": 1,
	&"support_eternal_bulwark": 0, &"support_battle_cry": 0, &"support_war_drum": 1,
	&"support_arcane_engine": 3,
}


## L'illustrazione della carta, come texture (dalla cache se c'e' gia').
static func paint(card: CardData) -> ImageTexture:
	if card == null:
		return null
	var key: String = "%s|%d|%d|%d|%d" % [card.id, card.cost, card.element, card.rarity, card.effects.size()]
	if _cache.has(key):
		return _cache[key]
	var texture: ImageTexture = ImageTexture.create_from_image(paint_image(card))
	_cache[key] = texture
	return texture


## L'illustrazione della carta, come immagine [constant WIDTH] x [constant HEIGHT].
static func paint_image(card: CardData) -> Image:
	var img: Image = Image.create_empty(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = absi(str(card.id).hash()) + card.cost * 131

	var pal: Dictionary = _palette(card.element)
	_paint_background(img, card.element, pal, rng)

	var effects: Array = _effect_kinds(card)
	var main: String = effects[0] if not effects.is_empty() else "none"
	var scale: float = clampf(0.65 + float(card.cost) / 40.0, 0.65, 1.25)
	var cx: int = WIDTH / 2 + rng.randi_range(-3, 3)
	var cy: int = HEIGHT / 2 + 4

	# La variante: carte dello stesso tipo hanno soggetti diversi (una fiamma,
	# una palla di fuoco, una spada infuocata...). Decisa dall'id.
	var variant: int = VARIANTS.get(card.id, (absi(str(card.id).hash()) / 7) % 3)

	_paint_subject(img, main, card, pal, cx, cy, scale, variant, rng)

	# Un dettaglio per ogni altro effetto, in un angolo.
	var corner: int = 0
	for i: int in range(1, effects.size()):
		_paint_detail(img, effects[i], card, pal, corner, rng)
		corner += 1

	_paint_rarity(img, card.rarity, pal, rng)
	_vignette(img, pal)
	return img


#region Tavolozze e sfondi


## I colori di un elemento: due per lo sfondo, uno acceso, uno chiaro, l'inchiostro.
static func _palette(element: CardTypes.Element) -> Dictionary:
	match element:
		CardTypes.Element.FIRE:
			return _pal("3a0f0c", "7a1f10", "ff7a1c", "ffd166", "1a0604")
		CardTypes.Element.ICE:
			return _pal("0d1a33", "1d3f6e", "6fd3ff", "e8fbff", "060b16")
		CardTypes.Element.POISON:
			return _pal("12240f", "2b4d18", "9ee64a", "e2ff9a", "060d05")
		CardTypes.Element.LIGHTNING:
			return _pal("1c1a33", "3a3466", "ffe74a", "fff8c4", "0b0a18")
		CardTypes.Element.NATURE:
			return _pal("10281a", "22512f", "6fcf6a", "d4f5a8", "061208")
		CardTypes.Element.DARK:
			return _pal("160a22", "32174f", "b06cff", "ead9ff", "08040f")
	return _pal("2b2420", "4b3f36", "d9b86c", "f4e7c3", "140f0c")


static func _pal(deep: String, mid: String, bright: String, light: String, ink: String) -> Dictionary:
	return {
		"deep": Color(deep), "mid": Color(mid), "bright": Color(bright),
		"light": Color(light), "ink": Color(ink),
	}


## Lo sfondo: un cielo sfumato a puntini, piu' un motivo per elemento.
static func _paint_background(img: Image, element: CardTypes.Element, pal: Dictionary, rng: RandomNumberGenerator) -> void:
	var deep: Color = pal["deep"]
	var mid: Color = pal["mid"]
	for y: int in HEIGHT:
		for x: int in WIDTH:
			var t: float = float(y) / float(HEIGHT - 1)
			var b: float = _bayer(x, y)
			img.set_pixel(x, y, mid if t + (b - 0.5) * 0.4 < 0.45 else deep)

	match element:
		CardTypes.Element.FIRE:
			# Terra bruciata in basso e braci che salgono.
			for x: int in WIDTH:
				var ground: int = HEIGHT - 6 - int(2.0 * sin(float(x) * 0.4))
				for y: int in range(ground, HEIGHT):
					img.set_pixel(x, y, pal["ink"] if (x + y) % 3 != 0 else deep)
			for _i: int in 22:
				var p: Vector2i = Vector2i(rng.randi_range(2, WIDTH - 3), rng.randi_range(4, HEIGHT - 8))
				img.set_pixel(p.x, p.y, pal["bright"] if rng.randf() < 0.6 else pal["light"])
		CardTypes.Element.ICE:
			# Cristalli sul fondo e qualche fiocco.
			for i: int in 6:
				var bx: int = 4 + i * 11 + rng.randi_range(-2, 2)
				var h: int = rng.randi_range(5, 12)
				_shard(img, bx, HEIGHT - 1, h, 3, mid.lightened(0.25), pal["light"], pal["ink"])
			for _i: int in 14:
				_dot(img, rng.randi_range(0, WIDTH - 1), rng.randi_range(0, HEIGHT - 14), pal["light"])
		CardTypes.Element.POISON:
			# Una palude con bolle.
			for x: int in WIDTH:
				var level: int = HEIGHT - 9 + int(1.5 * sin(float(x) * 0.5 + 1.0))
				for y: int in range(level, HEIGHT):
					img.set_pixel(x, y, mid.darkened(0.2) if (x * 3 + y) % 5 != 0 else pal["bright"].darkened(0.4))
			for _i: int in 7:
				var r: int = rng.randi_range(1, 3)
				_ring(img, rng.randi_range(4, WIDTH - 5), rng.randi_range(HEIGHT - 20, HEIGHT - 6), r, pal["bright"].darkened(0.1))
		CardTypes.Element.LIGHTNING:
			# Nuvole basse e pioggia obliqua.
			for i: int in 4:
				var cx: int = 8 + i * 16 + rng.randi_range(-4, 4)
				var cy: int = 6 + rng.randi_range(0, 6)
				_blob(img, cx, cy, 9, 4, mid.lightened(0.15))
				_blob(img, cx - 5, cy + 2, 7, 3, mid.lightened(0.05))
			for _i: int in 30:
				var x: int = rng.randi_range(0, WIDTH - 1)
				var y: int = rng.randi_range(12, HEIGHT - 1)
				_dot(img, x, y, mid.lightened(0.35))
				_dot(img, x - 1, y + 1, mid.lightened(0.2))
		CardTypes.Element.NATURE:
			# Erba e foglie che cadono.
			for x: int in WIDTH:
				var ground: int = HEIGHT - 7 + int(1.5 * sin(float(x) * 0.7))
				for y: int in range(ground, HEIGHT):
					img.set_pixel(x, y, pal["bright"].darkened(0.45) if (x + y * 2) % 4 != 0 else mid)
				if x % 5 == 2:
					_dot(img, x, ground - 1, pal["bright"].darkened(0.3))
					_dot(img, x, ground - 2, pal["bright"].darkened(0.2))
			for _i: int in 6:
				_leaf(img, rng.randi_range(3, WIDTH - 4), rng.randi_range(2, HEIGHT - 16), 3, pal["bright"].darkened(0.15), pal["ink"], rng.randf() < 0.5)
		CardTypes.Element.DARK:
			# Un cielo di stelle e una luna.
			for _i: int in 26:
				_dot(img, rng.randi_range(0, WIDTH - 1), rng.randi_range(0, HEIGHT - 1), pal["light"] if rng.randf() < 0.3 else mid.lightened(0.4))
			var mx: int = rng.randi_range(44, 56)
			_fill_circle(img, mx, 10, 6, pal["light"])
			_fill_circle(img, mx + 3, 9, 5, deep)
		_:
			# Pergamena: righe e un timbro sbiadito.
			for y: int in range(6, HEIGHT - 4, 5):
				for x: int in range(6, WIDTH - 6):
					if x % 2 == 0:
						_dot(img, x, y, mid.lightened(0.12))
			_ring(img, WIDTH - 12, 10, 6, mid.lightened(0.25))
			_ring(img, WIDTH - 12, 10, 4, mid.lightened(0.2))


#endregion

#region Soggetti


## Il tipo di ogni effetto, nell'ordine della carta.
static func _effect_kinds(card: CardData) -> Array:
	var kinds: Array = []
	for effect: CardEffect in card.effects:
		if effect == null:
			continue
		if effect is DealDamageEffect:
			kinds.append("damage")
		elif effect is GainShieldEffect:
			kinds.append("shield")
		elif effect is HealEffect:
			kinds.append("heal")
		elif effect is ApplyStatusEffect:
			kinds.append("status:%d" % int((effect as ApplyStatusEffect).status))
		elif effect is TurnDamageBuffEffect:
			kinds.append("buff")
		elif effect is FlatDamageBonusEffect:
			kinds.append("focus")
		elif effect is LoseHealthEffect:
			kinds.append("blood")
		elif effect is AmplifyStatusEffect:
			kinds.append("cauldron")
		else:
			kinds.append("none")
	return kinds


## Il soggetto principale.
static func _paint_subject(
	img: Image, kind: String, card: CardData, pal: Dictionary,
	cx: int, cy: int, scale: float, variant: int, rng: RandomNumberGenerator
) -> void:
	var bright: Color = pal["bright"]
	var light: Color = pal["light"]
	var ink: Color = pal["ink"]
	var mid: Color = pal["mid"]

	if kind == "damage":
		_paint_attack(img, card.element, pal, cx, cy, scale, variant, rng)
	elif kind == "shield":
		match variant:
			1:
				_round_shield(img, cx, cy - 2, int(13.0 * scale) + 2, mid.lightened(0.3), light, ink)
				_emblem(img, card.element, pal, cx, cy - 2, scale * 0.8)
			2:
				_brick_wall(img, cx, cy, scale, mid, light, ink)
				_emblem(img, card.element, pal, cx, cy - 12, scale * 0.8)
			_:
				_shield(img, cx, cy - 2, int(18.0 * scale), int(26.0 * scale), mid.lightened(0.3), light, ink)
				_emblem(img, card.element, pal, cx, cy - 3, scale)
	elif kind == "heal":
		if card.element == CardTypes.Element.DARK:
			# Un calice: cura, ma a un prezzo.
			_chalice(img, cx, cy, scale, bright, light, ink)
		elif variant == 1:
			_flower(img, cx, cy, scale, pal, rng)
		elif variant == 3:
			_tree(img, cx, cy, scale, pal, rng)
			_sparkles(img, cx, cy - 10, 16, 6, light, rng)
		elif variant == 2:
			_potion(img, cx, cy, scale, Color("e8536a"), Color("ffb3c0"), ink)
			_sparkles(img, cx, cy - 8, 10, 4, light, rng)
		else:
			_heart(img, cx, cy - 2, int(7.0 * scale) + 2, Color("e8536a"), Color("ffb3c0"), ink)
			_sparkles(img, cx, cy - 2, int(12.0 * scale), 5, light, rng)
	elif kind.begins_with("status:"):
		_paint_status(img, int(kind.substr(7)), pal, cx, cy, scale, variant, rng)
	elif kind == "buff":
		match variant:
			1:
				_drum(img, cx, cy, scale, pal)
			2:
				_banner(img, cx, cy, scale, bright, light, ink)
			3:
				_orb(img, cx, cy - 2, int(8.0 * scale) + 2, bright, light, ink, rng)
				_ring(img, cx, cy - 2, int(8.0 * scale) + 6, light)
			_:
				_horn(img, cx, cy, scale, bright, light, ink)
		_sparkles(img, cx, cy - 10, 14, 5, light, rng)
	elif kind == "focus":
		if card.element == CardTypes.Element.LIGHTNING:
			_orb(img, cx, cy - 2, int(8.0 * scale) + 2, bright, light, ink, rng)
		else:
			_target(img, cx, cy - 2, int(12.0 * scale), bright, light, ink)
	elif kind == "blood":
		_heart(img, cx, cy - 2, int(7.0 * scale) + 2, Color("8a1f2e"), Color("c84a5a"), ink)
		_crack(img, cx, cy - 8, 12, ink)
	elif kind == "cauldron":
		_cauldron(img, cx, cy, scale, pal, rng)
	else:
		_ring(img, cx, cy, int(8.0 * scale), bright)


## Il colpo di ogni elemento, in tre varianti per elemento: fiamme, palla di
## fuoco o spada infuocata; lancia, tormenta o blocco di ghiaccio; e cosi' via.
static func _paint_attack(
	img: Image, element: CardTypes.Element, pal: Dictionary,
	cx: int, cy: int, scale: float, variant: int, rng: RandomNumberGenerator
) -> void:
	var bright: Color = pal["bright"]
	var light: Color = pal["light"]
	var ink: Color = pal["ink"]
	var mid: Color = pal["mid"]
	match element:
		CardTypes.Element.FIRE:
			match variant:
				1:
					_fireball(img, cx, cy - 2, int(8.0 * scale) + 2, mid.lightened(0.2), bright, light, ink)
				3:
					_phoenix(img, cx, cy, scale, mid.lightened(0.2), bright, light, ink)
				2:
					_sword(img, cx, cy, scale, Color("c9c2b8"), Color.WHITE, ink)
					for i: int in 4:
						var t: float = 0.25 + float(i) * 0.18
						var px: int = cx - int(26.0 * scale) / 4 + int(float(int(26.0 * scale)) * 0.75 * t)
						var py: int = cy + int(26.0 * scale) / 4 - int(float(int(26.0 * scale)) * 0.75 * t)
						_flame(img, px, py - 1, 7 + i, 4, mid.lightened(0.2), bright, light, ink)
				_:
					_flame(img, cx, cy + int(10.0 * scale), int(24.0 * scale), int(14.0 * scale), mid.lightened(0.2), bright, light, ink)
					_flame(img, cx - int(9.0 * scale), cy + int(10.0 * scale), int(13.0 * scale), int(8.0 * scale), mid.lightened(0.2), bright, light, ink)
					_flame(img, cx + int(9.0 * scale), cy + int(10.0 * scale), int(11.0 * scale), int(7.0 * scale), mid.lightened(0.2), bright, light, ink)
		CardTypes.Element.ICE:
			match variant:
				1:
					_blizzard(img, cx, cy, scale, bright, light, ink, rng)
				2:
					_crystal(img, cx, cy, scale, mid.lightened(0.3), bright, light, ink)
				_:
					_lance(img, cx, cy, int(30.0 * scale), bright, light, ink, rng)
		CardTypes.Element.POISON:
			match variant:
				1:
					_splash(img, cx, cy, scale, bright, light, ink)
				2:
					_cloud(img, cx, cy - 4, scale, bright.darkened(0.35), bright, ink)
					_skull(img, cx, cy - 2, scale * 0.8, light, ink)
				_:
					_claw(img, cx, cy, scale, bright, light, ink)
					for i: int in 3:
						_drop(img, cx - 8 + i * 8, cy + 9 + rng.randi_range(0, 4), 2, bright, ink)
		CardTypes.Element.LIGHTNING:
			match variant:
				1:
					_bolt(img, cx - 9, cy, int(26.0 * scale), bright, light, ink, rng)
					_bolt(img, cx + 9, cy + 2, int(30.0 * scale), bright, light, ink, rng)
				2:
					_orb(img, cx, cy - 2, int(8.0 * scale) + 2, bright, light, ink, rng)
				_:
					_bolt(img, cx, cy, int(32.0 * scale), bright, light, ink, rng)
		CardTypes.Element.NATURE:
			match variant:
				1:
					_tree(img, cx, cy, scale, pal, rng)
				2:
					_thorn_branch(img, cx - 4, cy + 2, scale * 0.9, pal, rng)
					_thorn_branch(img, cx + 4, cy - 2, scale * 0.9, pal, rng)
				_:
					_thorn_branch(img, cx, cy, scale, pal, rng)
		CardTypes.Element.DARK:
			match variant:
				1:
					_dagger(img, cx, cy, scale, bright, light, ink)
					_drop(img, cx + 10, cy + 10, 2, Color("b02a3a"), ink)
				2:
					_dark_eye(img, cx, cy - 2, scale, pal)
				_:
					_scythe(img, cx, cy, scale, bright, light, ink)
		_:
			_sword(img, cx, cy, scale, mid.lightened(0.35), light, ink)


## Il simbolo di uno status.
static func _paint_status(
	img: Image, status: int, pal: Dictionary, cx: int, cy: int, scale: float, variant: int, rng: RandomNumberGenerator
) -> void:
	var ink: Color = pal["ink"]
	match status:
		CardTypes.StatusType.BURN:
			if variant == 1:
				_fireball(img, cx, cy - 2, int(7.0 * scale) + 2, pal["mid"].lightened(0.2), pal["bright"], pal["light"], ink)
			else:
				for i: int in range(-1, 2):
					_flame(img, cx + i * int(10.0 * scale), cy + 10, int((14.0 - absi(i) * 4.0) * scale), int(7.0 * scale), pal["mid"].lightened(0.2), pal["bright"], pal["light"], ink)
		CardTypes.StatusType.POISON:
			if variant == 1:
				_cloud(img, cx, cy - 4, scale, pal["bright"].darkened(0.35), pal["bright"], ink)
				_skull(img, cx, cy - 2, scale * 0.8, pal["light"], ink)
			elif variant == 2:
				_splash(img, cx, cy, scale, pal["bright"], pal["light"], ink)
			else:
				_skull(img, cx, cy - 4, scale, pal["light"], ink)
				for i: int in 3:
					_drop(img, cx - 10 + i * 10, cy + 10 + rng.randi_range(0, 3), 2, pal["bright"], ink)
		CardTypes.StatusType.CHILL:
			_snowflake(img, cx, cy - 2, int(13.0 * scale), pal["light"], pal["bright"])
		CardTypes.StatusType.EMPOWER:
			_star(img, cx, cy - 2, int(12.0 * scale), pal["bright"], pal["light"], ink)
		CardTypes.StatusType.REGEN:
			_leaf(img, cx, cy - 3, int(9.0 * scale), pal["bright"], ink, false)
			_leaf(img, cx + 6, cy + 3, int(6.0 * scale), pal["bright"].darkened(0.15), ink, true)
			_sparkles(img, cx, cy, 12, 4, pal["light"], rng)


## Un dettaglio piccolo, per gli effetti secondari.
static func _paint_detail(
	img: Image, kind: String, card: CardData, pal: Dictionary, corner: int, rng: RandomNumberGenerator
) -> void:
	var x: int = 9 if corner % 2 == 0 else WIDTH - 10
	var y: int = 9 if corner < 2 else HEIGHT - 11
	var ink: Color = pal["ink"]
	if kind == "shield":
		_shield(img, x, y, 8, 11, pal["mid"].lightened(0.3), pal["light"], ink)
	elif kind == "heal":
		_heart(img, x, y, 4, Color("e8536a"), Color("ffb3c0"), ink)
	elif kind == "blood":
		_drop(img, x, y, 3, Color("b02a3a"), ink)
	elif kind == "buff" or kind == "focus":
		_star(img, x, y, 5, pal["bright"], pal["light"], ink)
	elif kind == "damage":
		_sparkles(img, x, y, 5, 4, pal["light"], rng)
	elif kind.begins_with("status:"):
		match int(kind.substr(7)):
			CardTypes.StatusType.BURN:
				_flame(img, x, y + 5, 10, 6, pal["mid"].lightened(0.2), Color("ff7a1c"), Color("ffd166"), ink)
			CardTypes.StatusType.POISON:
				_drop(img, x, y, 3, Color("9ee64a"), ink)
			CardTypes.StatusType.CHILL:
				_snowflake(img, x, y, 5, Color("e8fbff"), Color("6fd3ff"))
			CardTypes.StatusType.EMPOWER:
				_star(img, x, y, 5, Color("ffe74a"), Color("fff8c4"), ink)
			CardTypes.StatusType.REGEN:
				_leaf(img, x, y, 4, Color("6fcf6a"), ink, false)
	elif kind == "cauldron":
		_ring(img, x, y, 3, pal["bright"])


## Lo stemma dell'elemento sopra uno scudo.
static func _emblem(img: Image, element: CardTypes.Element, pal: Dictionary, cx: int, cy: int, scale: float) -> void:
	var ink: Color = pal["ink"]
	match element:
		CardTypes.Element.FIRE:
			_flame(img, cx, cy + 6, int(11.0 * scale), int(6.0 * scale), pal["mid"].lightened(0.2), pal["bright"], pal["light"], ink)
		CardTypes.Element.ICE:
			_snowflake(img, cx, cy, int(6.0 * scale), pal["light"], pal["bright"])
		CardTypes.Element.POISON:
			_drop(img, cx, cy, int(3.0 * scale), pal["bright"], ink)
		CardTypes.Element.LIGHTNING:
			_bolt(img, cx, cy, int(12.0 * scale), pal["bright"], pal["light"], ink, null)
		CardTypes.Element.NATURE:
			_leaf(img, cx, cy, int(5.0 * scale), pal["bright"], ink, false)
		CardTypes.Element.DARK:
			_fill_circle(img, cx, cy, int(4.0 * scale), pal["light"])
			_fill_circle(img, cx + 2, cy - 1, int(3.0 * scale), pal["mid"].lightened(0.3))
		_:
			_ring(img, cx, cy, int(4.0 * scale), pal["bright"])


## La rarita' si vede: raggi, scintille, angoli d'oro.
static func _paint_rarity(img: Image, rarity: CardTypes.Rarity, pal: Dictionary, rng: RandomNumberGenerator) -> void:
	var gold: Color = Color("f2c94c")
	match rarity:
		CardTypes.Rarity.RARE:
			_frame(img, Color("4f8fd9"), 1)
		CardTypes.Rarity.EPIC:
			_frame(img, Color("a05ad9"), 1)
			_sparkles(img, WIDTH / 2, HEIGHT / 2, 26, 8, pal["light"], rng)
		CardTypes.Rarity.LEGENDARY:
			_rays(img, WIDTH / 2, HEIGHT / 2 + 4, gold.darkened(0.35), rng)
			_frame(img, gold, 2)
			_corners(img, gold)
		CardTypes.Rarity.UNIQUE:
			_rays(img, WIDTH / 2, HEIGHT / 2 + 4, Color("ff6a3d").darkened(0.2), rng)
			_frame(img, Color("ff6a3d"), 2)
			_corners(img, gold)
			_sparkles(img, WIDTH / 2, HEIGHT / 2, 26, 10, Color.WHITE, rng)


#endregion

#region Forme


static func _flame(img: Image, cx: int, base: int, h: int, w: int, outer: Color, body: Color, core: Color, ink: Color) -> void:
	# Una goccia rovesciata, con la lingua che ondeggia e il cuore chiaro.
	for dy: int in range(0, h + 1):
		var t: float = float(dy) / float(maxi(h, 1))  # 0 in punta, 1 alla base
		var half: int = int(float(w) * 0.5 * sin(t * PI * 0.72 + 0.1) + 0.5)
		var wobble: int = int(2.0 * sin(float(dy) * 0.9)) if t < 0.5 else 0
		var y: int = base - h + dy
		for dx: int in range(-half, half + 1):
			var x: int = cx + dx + wobble
			var edge: bool = absi(dx) == half
			var c: Color = body
			if edge or dy == 0:
				c = ink
			elif t > 0.55 and absi(dx) <= half / 2:
				c = core
			elif absi(dx) >= half - 1 and t < 0.8:
				c = outer
			_dot(img, x, y, c)


static func _lance(img: Image, cx: int, cy: int, length: int, body: Color, light: Color, ink: Color, rng: RandomNumberGenerator) -> void:
	# Una lancia di ghiaccio in diagonale, con il riflesso.
	var half: int = length / 2
	for i: int in range(-half, half + 1):
		var t: float = float(i + half) / float(length)
		var thick: int = int(4.0 * sin(t * PI)) + 1
		var x: int = cx + i
		var y: int = cy - i / 2
		for d: int in range(-thick, thick + 1):
			var c: Color = body
			if absi(d) == thick:
				c = ink
			elif d == -thick + 1:
				c = light
			_dot(img, x, y + d, c)
	# Schegge intorno.
	if rng != null:
		for _i: int in 6:
			_shard(img, cx + rng.randi_range(-18, 18), cy + rng.randi_range(6, 14), rng.randi_range(3, 6), 2, body, light, ink)


static func _shard(img: Image, bx: int, base: int, h: int, w: int, body: Color, light: Color, ink: Color) -> void:
	for dy: int in range(0, h + 1):
		var half: int = int(float(w) * float(dy) / float(maxi(h, 1)) + 0.5)
		var y: int = base - h + dy
		for dx: int in range(-half, half + 1):
			var c: Color = body
			if absi(dx) == half or dy == 0:
				c = ink
			elif dx == -half + 1:
				c = light
			_dot(img, bx + dx, y, c)


static func _bolt(img: Image, cx: int, cy: int, length: int, body: Color, light: Color, ink: Color, rng: RandomNumberGenerator) -> void:
	# Un fulmine a zig-zag che scende, con i bordi d'inchiostro.
	var x: int = cx + 4
	var y: int = cy - length / 2
	var step: int = maxi(length / 5, 3)
	var points: Array[Vector2i] = [Vector2i(x, y)]
	var dir: int = -1
	while y < cy + length / 2:
		y += step
		x += dir * (3 + (rng.randi_range(0, 2) if rng != null else 1))
		points.append(Vector2i(x, y))
		dir = -dir
	for i: int in range(points.size() - 1):
		_thick_line(img, points[i], points[i + 1], 2, ink)
	for i: int in range(points.size() - 1):
		_thick_line(img, points[i], points[i + 1], 1, body)
	for i: int in range(points.size() - 1):
		_line(img, points[i] + Vector2i(0, 0), points[i + 1] + Vector2i(0, 0), light)
	if rng != null:
		for _i: int in 6:
			_dot(img, cx + rng.randi_range(-14, 14), cy + rng.randi_range(-12, 12), light)


static func _claw(img: Image, cx: int, cy: int, scale: float, body: Color, light: Color, ink: Color) -> void:
	# Tre graffi in diagonale.
	var length: int = int(22.0 * scale)
	for i: int in range(-1, 2):
		var start: Vector2i = Vector2i(cx - length / 2 + i * 7, cy - length / 2 - i * 2)
		var end: Vector2i = Vector2i(cx + length / 2 + i * 7, cy + length / 2 - i * 2)
		_thick_line(img, start, end, 2, ink)
		_thick_line(img, start, end, 1, body)
		_line(img, start, end, light)


static func _thorn_branch(img: Image, cx: int, cy: int, scale: float, pal: Dictionary, rng: RandomNumberGenerator) -> void:
	var length: int = int(30.0 * scale)
	var start: Vector2i = Vector2i(cx - length / 2, cy + 8)
	var end: Vector2i = Vector2i(cx + length / 2, cy - 8)
	_thick_line(img, start, end, 2, pal["ink"])
	_thick_line(img, start, end, 1, pal["mid"].lightened(0.35))
	for i: int in range(2, length, 4):
		var t: float = float(i) / float(length)
		var p: Vector2i = Vector2i(int(lerpf(start.x, end.x, t)), int(lerpf(start.y, end.y, t)))
		var up: bool = (i / 4) % 2 == 0
		_line(img, p, p + Vector2i(1, -4 if up else 4), pal["light"])
		_dot(img, p.x + 1, p.y + (-4 if up else 4), pal["ink"])
	for _i: int in 3:
		_leaf(img, cx + rng.randi_range(-10, 10), cy + rng.randi_range(-6, 6), 4, pal["bright"], pal["ink"], rng.randf() < 0.5)


static func _scythe(img: Image, cx: int, cy: int, scale: float, body: Color, light: Color, ink: Color) -> void:
	# Il manico e la lama curva.
	var length: int = int(26.0 * scale)
	_thick_line(img, Vector2i(cx - 6, cy + length / 2), Vector2i(cx + 4, cy - length / 2), 2, ink)
	_line(img, Vector2i(cx - 6, cy + length / 2), Vector2i(cx + 4, cy - length / 2), Color("5a3a28"))
	var r: int = int(11.0 * scale)
	for a: int in range(200, 350, 3):
		var angle: float = deg_to_rad(float(a))
		var p: Vector2i = Vector2i(cx + 4 + int(cos(angle) * float(r)), cy - length / 2 + r + int(sin(angle) * float(r)))
		var thick: int = 1 + int(2.0 * sin(float(a - 200) / 150.0 * PI))
		for d: int in range(0, thick + 1):
			_dot(img, p.x, p.y + d, ink if d == thick else (light if d == 0 else body))


static func _sword(img: Image, cx: int, cy: int, scale: float, body: Color, light: Color, ink: Color) -> void:
	var length: int = int(26.0 * scale)
	var tip: Vector2i = Vector2i(cx + length / 2, cy - length / 2)
	var hilt: Vector2i = Vector2i(cx - length / 4, cy + length / 4)
	var pommel: Vector2i = Vector2i(cx - length / 2, cy + length / 2)
	_thick_line(img, hilt, tip, 2, ink)
	_thick_line(img, hilt, tip, 1, body)
	_line(img, hilt, tip, light)
	_thick_line(img, hilt, pommel, 1, ink)
	_line(img, hilt, pommel, Color("5a3a28"))
	_thick_line(img, hilt + Vector2i(-3, -3), hilt + Vector2i(3, 3), 1, Color("c9a04a"))
	_fill_circle(img, pommel.x, pommel.y, 2, Color("c9a04a"))


static func _shield(img: Image, cx: int, cy: int, half_w: int, h: int, body: Color, light: Color, ink: Color) -> void:
	# Scudo a punta: largo sopra, stretto sotto.
	for dy: int in range(0, h + 1):
		var t: float = float(dy) / float(maxi(h, 1))
		var half: int = int(float(half_w) * (1.0 - t * t) + 0.5) if t > 0.35 else half_w
		var y: int = cy - h / 2 + dy
		for dx: int in range(-half, half + 1):
			var c: Color = body
			if absi(dx) == half or dy == 0 or dy == h:
				c = ink
			elif dx < 0 and dy < h / 2 and (dx + dy) % 2 == 0:
				c = light
			elif dx == 0:
				c = ink
			_dot(img, cx + dx, y, c)


static func _heart(img: Image, cx: int, cy: int, r: int, body: Color, light: Color, ink: Color) -> void:
	_fill_circle(img, cx - r / 2, cy - r / 3, r / 2 + 1, ink)
	_fill_circle(img, cx + r / 2, cy - r / 3, r / 2 + 1, ink)
	_fill_circle(img, cx - r / 2, cy - r / 3, r / 2, body)
	_fill_circle(img, cx + r / 2, cy - r / 3, r / 2, body)
	for dy: int in range(0, r + 1):
		var half: int = r - dy
		for dx: int in range(-half, half + 1):
			_dot(img, cx + dx, cy + dy, ink if absi(dx) == half or dy == r else body)
	_dot(img, cx - r / 2 - 1, cy - r / 2, light)
	_dot(img, cx - r / 2, cy - r / 2 - 1, light)


static func _star(img: Image, cx: int, cy: int, r: int, body: Color, light: Color, ink: Color) -> void:
	var points: PackedVector2Array = []
	for i: int in 10:
		var angle: float = -PI * 0.5 + float(i) * PI / 5.0
		var radius: float = float(r) if i % 2 == 0 else float(r) * 0.45
		points.append(Vector2(cx, cy) + Vector2(cos(angle), sin(angle)) * radius)
	_fill_polygon(img, points, body)
	for i: int in 10:
		_line(img, Vector2i(points[i]), Vector2i(points[(i + 1) % 10]), ink)
	_dot(img, cx - 1, cy - 2, light)
	_dot(img, cx, cy - 3, light)


static func _snowflake(img: Image, cx: int, cy: int, r: int, body: Color, dim: Color) -> void:
	for i: int in 6:
		var angle: float = float(i) * PI / 3.0
		var end: Vector2i = Vector2i(cx + int(cos(angle) * float(r)), cy + int(sin(angle) * float(r)))
		_line(img, Vector2i(cx, cy), end, body)
		var mid: Vector2i = Vector2i(cx + int(cos(angle) * float(r) * 0.55), cy + int(sin(angle) * float(r) * 0.55))
		for side: float in [-1.0, 1.0]:
			var branch: Vector2i = mid + Vector2i(int(cos(angle + side * 1.0) * float(r) * 0.35), int(sin(angle + side * 1.0) * float(r) * 0.35))
			_line(img, mid, branch, dim)
	_dot(img, cx, cy, body)


static func _leaf(img: Image, cx: int, cy: int, r: int, body: Color, ink: Color, flip: bool) -> void:
	var dir: int = -1 if flip else 1
	for dy: int in range(-r, r + 1):
		var t: float = float(dy + r) / float(maxi(r * 2, 1))
		var half: int = int(float(r) * 0.55 * sin(t * PI) + 0.5)
		for dx: int in range(-half, half + 1):
			var x: int = cx + dx + dir * (dy / 2)
			_dot(img, x, cy + dy, ink if absi(dx) == half else body)
	for dy: int in range(-r + 1, r):
		_dot(img, cx + dir * (dy / 2), cy + dy, body.darkened(0.3))


static func _drop(img: Image, cx: int, cy: int, r: int, body: Color, ink: Color) -> void:
	_fill_circle(img, cx, cy + r / 2, r + 1, ink)
	_fill_circle(img, cx, cy + r / 2, r, body)
	for dy: int in range(-r - 2, 0):
		var half: int = int(float(r) * float(dy + r + 2) / float(r + 2) + 0.4)
		for dx: int in range(-half, half + 1):
			_dot(img, cx + dx, cy + dy, ink if absi(dx) == half else body)
	_dot(img, cx - 1, cy, body.lightened(0.5))


static func _skull(img: Image, cx: int, cy: int, scale: float, body: Color, ink: Color) -> void:
	var r: int = int(7.0 * scale) + 1
	_fill_circle(img, cx, cy, r + 1, ink)
	_fill_circle(img, cx, cy, r, body)
	_fill_rect(img, cx - r / 2 - 1, cy + r - 2, r + 3, 4, ink)
	_fill_rect(img, cx - r / 2, cy + r - 2, r + 1, 3, body)
	_fill_circle(img, cx - r / 2, cy - 1, r / 3 + 1, ink)
	_fill_circle(img, cx + r / 2, cy - 1, r / 3 + 1, ink)
	_dot(img, cx, cy + 2, ink)
	for i: int in range(-1, 2):
		_dot(img, cx + i * 2, cy + r, ink)


static func _chalice(img: Image, cx: int, cy: int, scale: float, body: Color, light: Color, ink: Color) -> void:
	var w: int = int(8.0 * scale) + 2
	for dy: int in range(0, w + 2):
		var half: int = w - dy / 2
		for dx: int in range(-half, half + 1):
			_dot(img, cx + dx, cy - 8 + dy, ink if absi(dx) == half else (Color("8a1f2e") if dy < 3 else body))
	_thick_line(img, Vector2i(cx, cy + w - 6), Vector2i(cx, cy + w + 2), 1, ink)
	_fill_rect(img, cx - w / 2, cy + w + 2, w + 1, 2, ink)
	_fill_rect(img, cx - w / 2 + 1, cy + w + 2, w - 1, 1, light)
	_dot(img, cx - w + 2, cy - 6, light)


static func _horn(img: Image, cx: int, cy: int, scale: float, body: Color, light: Color, ink: Color) -> void:
	# Un corno da guerra: una curva che sale verso destra e si apre a campana.
	var length: int = int(26.0 * scale)
	var brass: Color = Color("d9a441")
	var brass_light: Color = Color("ffe6a3")
	for i: int in range(0, length + 1):
		var t: float = float(i) / float(length)
		var x: int = cx - length / 2 + i
		var y: int = cy + 6 - int(12.0 * t * t)
		var thick: int = 1 + int(3.0 * t)
		for d: int in range(-thick, thick + 1):
			_dot(img, x, y + d, ink if absi(d) == thick else (brass_light if d == -thick + 1 else brass))
	# La campana, piu' larga.
	var bx: int = cx + length / 2
	var by: int = cy + 6 - 12
	for d: int in range(-7, 8):
		_dot(img, bx + 1, by + d, ink)
		_dot(img, bx + 2, by + d, ink if absi(d) == 7 else brass)
		_dot(img, bx + 3, by + d, ink if absi(d) >= 6 else brass_light)
		_dot(img, bx + 4, by + d, ink if absi(d) >= 5 else brass)
		_dot(img, bx + 5, by + d, ink if absi(d) >= 4 else body)
	# Il bocchino e la cordicella.
	_fill_rect(img, cx - length / 2 - 3, cy + 4, 4, 5, ink)
	_fill_rect(img, cx - length / 2 - 2, cy + 5, 2, 3, brass_light)
	_line(img, Vector2i(cx - length / 2 + 4, cy + 10), Vector2i(cx + length / 4, cy + 12), Color("b03a3a"))
	_line(img, Vector2i(cx + length / 4, cy + 12), Vector2i(bx, cy + 2), Color("b03a3a"))
	_dot(img, cx + length / 4, cy + 13, light)


static func _cauldron(img: Image, cx: int, cy: int, scale: float, pal: Dictionary, rng: RandomNumberGenerator) -> void:
	var r: int = int(10.0 * scale) + 2
	_fill_circle(img, cx, cy + 2, r + 1, pal["ink"])
	_fill_circle(img, cx, cy + 2, r, Color("2b2a33"))
	_fill_rect(img, cx - r, cy - 4, r * 2 + 1, 3, pal["ink"])
	_fill_rect(img, cx - r + 1, cy - 3, r * 2 - 1, 1, pal["bright"])
	for _i: int in 8:
		var bx: int = cx + rng.randi_range(-r + 2, r - 2)
		var by: int = cy - 5 - rng.randi_range(0, 10)
		_ring(img, bx, by, rng.randi_range(1, 2), pal["bright"])
	for side: int in [-1, 1]:
		_fill_rect(img, cx + side * (r - 2) - 1, cy + r - 1, 3, 3, pal["ink"])


static func _fireball(img: Image, cx: int, cy: int, r: int, outer: Color, body: Color, core: Color, ink: Color) -> void:
	# La scia, verso sinistra: lingue di fuoco sempre piu' sottili, poi la palla.
	for i: int in range(0, r * 3):
		var tail_r: int = maxi(r - 1 - i / 2, 0)
		var x: int = cx - r - i
		var wave: int = int(2.0 * sin(float(i) * 0.6))
		for d: int in range(-tail_r, tail_r + 1):
			var c: Color = body if i < r else outer
			if absi(d) == tail_r:
				c = ink if _bayer(x, cy + d) < 0.6 else outer
			elif absi(d) <= tail_r / 2 and i < r:
				c = core
			_dot(img, x, cy + d + wave, c)
	_fill_circle(img, cx, cy, r + 1, ink)
	_fill_circle(img, cx, cy, r, body)
	_fill_circle(img, cx + 1, cy - 1, r / 2, core)
	# Le lingue che si staccano dalla palla.
	for a: int in [-60, -20, 20, 60]:
		var angle: float = deg_to_rad(float(a))
		var bx: int = cx + int(cos(angle) * float(r + 1))
		var by: int = cy + int(sin(angle) * float(r + 1))
		_line(img, Vector2i(bx, by), Vector2i(bx + 3, by + (1 if a > 0 else -1)), body)
		_dot(img, bx + 4, by + (2 if a > 0 else -2), core)


static func _phoenix(img: Image, cx: int, cy: int, scale: float, outer: Color, body: Color, core: Color, ink: Color) -> void:
	# Un uccello di fiamme: le ali sono due fiamme piegate, la coda una scia.
	var wing: int = int(16.0 * scale)
	for side: int in [-1, 1]:
		for i: int in range(0, wing):
			var t: float = float(i) / float(wing)
			var x: int = cx + side * (4 + i)
			var top: int = cy - int(10.0 * sin(t * PI * 0.8)) - 2
			var thick: int = maxi(int(6.0 * (1.0 - t)) + 1, 1)
			for d: int in range(0, thick + 1):
				var c: Color = body
				if d == thick or d == 0:
					c = ink
				elif d == 1:
					c = core
				elif d >= thick - 1:
					c = outer
				_dot(img, x, top + d, c)
			if i % 4 == 0:
				_flame(img, x, top, 5, 2, outer, body, core, ink)
	# Il corpo e la testa.
	_flame(img, cx, cy + 10, int(18.0 * scale), int(8.0 * scale), outer, body, core, ink)
	_fill_circle(img, cx, cy - 8, 3, ink)
	_fill_circle(img, cx, cy - 8, 2, core)
	_dot(img, cx + 3, cy - 8, Color("ffd166"))
	_dot(img, cx + 4, cy - 8, Color("ffd166"))
	_dot(img, cx - 1, cy - 9, ink)
	# La coda, che scende a sinistra.
	for i: int in range(0, 12):
		_dot(img, cx - 3 - i, cy + 10 + i / 2, body if i % 3 != 2 else core)
		_dot(img, cx - 3 - i, cy + 11 + i / 2, outer)


static func _blizzard(img: Image, cx: int, cy: int, scale: float, body: Color, light: Color, ink: Color, rng: RandomNumberGenerator) -> void:
	for _i: int in int(9.0 * scale):
		var p: Vector2i = Vector2i(cx + rng.randi_range(-22, 22), cy + rng.randi_range(-16, 14))
		var length: int = rng.randi_range(5, 10)
		_thick_line(img, p, p + Vector2i(-length / 2, length), 1, ink)
		_line(img, p, p + Vector2i(-length / 2, length), body)
		_dot(img, p.x, p.y, light)
	for _i: int in 5:
		_snowflake(img, cx + rng.randi_range(-20, 20), cy + rng.randi_range(-14, 12), rng.randi_range(3, 6), light, body)


static func _crystal(img: Image, cx: int, cy: int, scale: float, body: Color, bright: Color, light: Color, ink: Color) -> void:
	# Un blocco esagonale di ghiaccio, con le facce chiare e scure.
	var h: int = int(16.0 * scale)
	var w: int = int(11.0 * scale)
	for dy: int in range(-h, h + 1):
		var half: int = w if absi(dy) < h / 2 else int(float(w) * float(h - absi(dy)) / float(h / 2 + 1) + 0.5)
		for dx: int in range(-half, half + 1):
			var c: Color = body
			if absi(dx) == half or absi(dy) == h:
				c = ink
			elif dx < -half / 3:
				c = light
			elif dx > half / 3:
				c = bright.darkened(0.25)
			_dot(img, cx + dx, cy + dy, c)
	_line(img, Vector2i(cx - w / 3, cy - h), Vector2i(cx - w / 3, cy + h), ink)
	_line(img, Vector2i(cx + w / 3, cy - h), Vector2i(cx + w / 3, cy + h), ink)
	# Una crepa interna e il riflesso.
	_line(img, Vector2i(cx - w / 3 + 1, cy - h / 3), Vector2i(cx + w / 3 - 1, cy + h / 4), ink)
	_line(img, Vector2i(cx - w / 3 + 2, cy - h + 3), Vector2i(cx - w / 3 + 2, cy - h / 3), Color.WHITE)
	_dot(img, cx + w / 3 - 2, cy - h / 2, Color.WHITE)


static func _splash_puddle(img: Image, cx: int, cy: int, r: int, body: Color, light: Color, ink: Color) -> void:
	_blob(img, cx, cy, r + 4, 4, ink)
	_blob(img, cx, cy, r + 3, 3, body)
	_blob(img, cx - 2, cy - 1, r - 2, 1, light)


static func _splash(img: Image, cx: int, cy: int, scale: float, body: Color, light: Color, ink: Color) -> void:
	var r: int = int(10.0 * scale)
	_splash_puddle(img, cx, cy + 7, r, body, light, ink)
	_drop(img, cx, cy - 6, int(5.0 * scale) + 1, body, ink)
	for i: int in range(-2, 3):
		if i == 0:
			continue
		var x: int = cx + i * (r / 2 + 2)
		_drop(img, x, cy - 2 - absi(i) * 3, 1, body, ink)
	# Gli schizzi che risalgono dalla pozza.
	for i: int in range(-3, 4, 2):
		var x: int = cx + i * 3
		_line(img, Vector2i(x, cy + 4), Vector2i(x + (1 if i > 0 else -1), cy + 1 - absi(i)), body)
		_dot(img, x + (1 if i > 0 else -1), cy - absi(i), light)


static func _cloud(img: Image, cx: int, cy: int, scale: float, body: Color, edge: Color, ink: Color) -> void:
	var r: int = int(9.0 * scale) + 2
	for p: Vector2i in [Vector2i(-r, 2), Vector2i(0, -2), Vector2i(r, 3), Vector2i(-r / 2, 5), Vector2i(r / 2, 5)]:
		_fill_circle(img, cx + p.x, cy + p.y, r / 2 + 3, ink)
	for p: Vector2i in [Vector2i(-r, 2), Vector2i(0, -2), Vector2i(r, 3), Vector2i(-r / 2, 5), Vector2i(r / 2, 5)]:
		_fill_circle(img, cx + p.x, cy + p.y, r / 2 + 2, body)
	for p: Vector2i in [Vector2i(-r, 1), Vector2i(0, -3)]:
		_fill_circle(img, cx + p.x, cy + p.y, r / 4, edge.darkened(0.1))


static func _tree(img: Image, cx: int, cy: int, scale: float, pal: Dictionary, rng: RandomNumberGenerator) -> void:
	var h: int = int(26.0 * scale)
	_fill_rect(img, cx - 3, cy - h / 3, 7, h / 2 + 10, pal["ink"])
	_fill_rect(img, cx - 2, cy - h / 3, 5, h / 2 + 10, Color("5a3a28"))
	_fill_rect(img, cx - 1, cy - h / 3, 1, h / 2 + 8, Color("7a5240"))
	var canopy: Color = pal["bright"].darkened(0.25)
	for p: Vector2i in [Vector2i(0, -h / 2), Vector2i(-9, -h / 3), Vector2i(9, -h / 3), Vector2i(-4, -h / 5), Vector2i(5, -h / 5)]:
		_fill_circle(img, cx + p.x, cy + p.y, int(7.0 * scale) + 1, pal["ink"])
	for p: Vector2i in [Vector2i(0, -h / 2), Vector2i(-9, -h / 3), Vector2i(9, -h / 3), Vector2i(-4, -h / 5), Vector2i(5, -h / 5)]:
		_fill_circle(img, cx + p.x, cy + p.y, int(7.0 * scale), canopy)
	for _i: int in 8:
		_dot(img, cx + rng.randi_range(-12, 12), cy - h / 2 + rng.randi_range(-2, 14), pal["light"])


static func _dagger(img: Image, cx: int, cy: int, scale: float, body: Color, light: Color, ink: Color) -> void:
	var length: int = int(22.0 * scale)
	var tip: Vector2i = Vector2i(cx - length / 3, cy + length / 2)
	var guard: Vector2i = Vector2i(cx + length / 6, cy - length / 4)
	var pommel: Vector2i = Vector2i(cx + length / 3, cy - length / 2)
	_thick_line(img, guard, tip, 2, ink)
	_thick_line(img, guard, tip, 1, Color("c9c2b8"))
	_line(img, guard, tip, light)
	_thick_line(img, guard, pommel, 1, ink)
	_line(img, guard, pommel, body.darkened(0.3))
	_thick_line(img, guard + Vector2i(-3, -2), guard + Vector2i(3, 2), 1, body)
	_fill_circle(img, pommel.x, pommel.y, 2, body)


static func _dark_eye(img: Image, cx: int, cy: int, scale: float, pal: Dictionary) -> void:
	var rx: int = int(15.0 * scale)
	var ry: int = int(8.0 * scale)
	_blob(img, cx, cy, rx + 2, ry + 2, pal["ink"])
	_blob(img, cx, cy, rx, ry, pal["light"])
	_fill_circle(img, cx, cy, ry - 1, pal["bright"])
	_fill_circle(img, cx, cy, ry / 2, pal["ink"])
	_dot(img, cx - 2, cy - 2, Color.WHITE)
	for a: int in range(0, 360, 30):
		var angle: float = deg_to_rad(float(a))
		var p: Vector2i = Vector2i(cx + int(cos(angle) * float(rx + 5)), cy + int(sin(angle) * float(ry + 5)))
		_line(img, p, p + Vector2i(int(cos(angle) * 3.0), int(sin(angle) * 3.0)), pal["bright"].darkened(0.2))


static func _round_shield(img: Image, cx: int, cy: int, r: int, body: Color, light: Color, ink: Color) -> void:
	_fill_circle(img, cx, cy, r + 1, ink)
	_fill_circle(img, cx, cy, r, body)
	_ring(img, cx, cy, r - 2, ink)
	_fill_circle(img, cx, cy, 2, ink)
	for dy: int in range(-r, 0):
		for dx: int in range(-r, 0):
			if dx * dx + dy * dy < (r - 3) * (r - 3) and (dx + dy) % 2 == 0:
				_dot(img, cx + dx, cy + dy, light)


static func _brick_wall(img: Image, cx: int, cy: int, scale: float, mid: Color, light: Color, ink: Color) -> void:
	var w: int = int(16.0 * scale) + 4
	var h: int = int(11.0 * scale) + 2
	var brick_w: int = 6
	var brick_h: int = 3
	for row: int in range(0, h):
		var y: int = cy + h / 2 - row * (brick_h + 1)
		var offset: int = 0 if row % 2 == 0 else brick_w / 2
		var x: int = cx - w - offset
		while x < cx + w:
			var bw: int = mini(brick_w, cx + w - x)
			if bw > 1:
				_fill_rect(img, x, y - brick_h, bw + 1, brick_h + 1, ink)
				_fill_rect(img, x + 1, y - brick_h + 1, bw - 1, brick_h - 1, mid.lightened(0.25) if (row + x) % 3 != 0 else mid.lightened(0.1))
				_dot(img, x + 1, y - brick_h + 1, light)
			x += brick_w + 1
	_fill_rect(img, cx - w - 1, cy - h / 2 - brick_h * 2, (w + 1) * 2, 2, ink)


static func _flower(img: Image, cx: int, cy: int, scale: float, pal: Dictionary, rng: RandomNumberGenerator) -> void:
	var stem_h: int = int(16.0 * scale)
	_thick_line(img, Vector2i(cx, cy + stem_h), Vector2i(cx, cy - 2), 1, pal["ink"])
	_line(img, Vector2i(cx, cy + stem_h), Vector2i(cx, cy - 2), pal["bright"].darkened(0.3))
	_leaf(img, cx - 4, cy + stem_h / 2, 4, pal["bright"], pal["ink"], true)
	_leaf(img, cx + 4, cy + stem_h / 3, 3, pal["bright"], pal["ink"], false)
	var petal: Color = Color("ff8fb1")
	var r: int = int(4.0 * scale) + 1
	for a: int in range(0, 360, 60):
		var angle: float = deg_to_rad(float(a))
		_fill_circle(img, cx + int(cos(angle) * float(r + 2)), cy - 4 + int(sin(angle) * float(r + 2)), r, pal["ink"])
	for a: int in range(0, 360, 60):
		var angle: float = deg_to_rad(float(a))
		_fill_circle(img, cx + int(cos(angle) * float(r + 2)), cy - 4 + int(sin(angle) * float(r + 2)), r - 1, petal)
	_fill_circle(img, cx, cy - 4, r - 1, Color("ffe066"))
	_sparkles(img, cx, cy - 6, 12, 4, pal["light"], rng)


static func _potion(img: Image, cx: int, cy: int, scale: float, liquid: Color, light: Color, ink: Color) -> void:
	var r: int = int(8.0 * scale) + 2
	_fill_circle(img, cx, cy + 3, r + 1, ink)
	_fill_circle(img, cx, cy + 3, r, Color("9fd3e8"))
	for dy: int in range(-r / 2, r + 1):
		for dx: int in range(-r, r + 1):
			if dx * dx + (dy - 3) * (dy - 3) <= r * r and dy > 0:
				_dot(img, cx + dx, cy + dy + 2, liquid)
	_fill_rect(img, cx - 3, cy - r - 2, 7, r / 2 + 3, ink)
	_fill_rect(img, cx - 2, cy - r - 1, 5, r / 2 + 2, Color("9fd3e8"))
	_fill_rect(img, cx - 3, cy - r - 4, 7, 3, Color("5a3a28"))
	_dot(img, cx - r + 2, cy + 1, light)
	_dot(img, cx - r + 3, cy, light)


static func _drum(img: Image, cx: int, cy: int, scale: float, pal: Dictionary) -> void:
	var rx: int = int(13.0 * scale)
	var ry: int = int(5.0 * scale) + 1
	var h: int = int(12.0 * scale)
	_fill_rect(img, cx - rx - 1, cy - h / 2, rx * 2 + 3, h, pal["ink"])
	_fill_rect(img, cx - rx, cy - h / 2, rx * 2 + 1, h, Color("8a2b2b"))
	for i: int in range(-rx, rx + 1, 5):
		_line(img, Vector2i(cx + i, cy - h / 2), Vector2i(cx + i + 3, cy + h / 2), Color("e8c56a"))
	_blob(img, cx, cy + h / 2, rx + 1, ry + 1, pal["ink"])
	_blob(img, cx, cy + h / 2, rx, ry, Color("8a2b2b").darkened(0.2))
	_blob(img, cx, cy - h / 2, rx + 1, ry + 1, pal["ink"])
	_blob(img, cx, cy - h / 2, rx, ry, Color("f0e2c8"))
	_blob(img, cx, cy - h / 2, rx - 3, ry - 2, Color("e2cfae"))
	# Le bacchette.
	_thick_line(img, Vector2i(cx - 10, cy - h / 2 - 12), Vector2i(cx - 3, cy - h / 2 - 1), 1, pal["ink"])
	_line(img, Vector2i(cx - 10, cy - h / 2 - 12), Vector2i(cx - 3, cy - h / 2 - 1), Color("c9a04a"))
	_thick_line(img, Vector2i(cx + 10, cy - h / 2 - 12), Vector2i(cx + 3, cy - h / 2 - 1), 1, pal["ink"])
	_line(img, Vector2i(cx + 10, cy - h / 2 - 12), Vector2i(cx + 3, cy - h / 2 - 1), Color("c9a04a"))


static func _banner(img: Image, cx: int, cy: int, scale: float, body: Color, light: Color, ink: Color) -> void:
	var h: int = int(26.0 * scale)
	var w: int = int(12.0 * scale) + 2
	_fill_rect(img, cx - w - 2, cy - h / 2 - 2, 2, h + 8, ink)
	_fill_rect(img, cx - w - 1, cy - h / 2 - 2, 1, h + 8, Color("5a3a28"))
	for dy: int in range(0, h):
		var wave: int = int(2.0 * sin(float(dy) * 0.5))
		var width: int = w + wave
		var notch: int = maxi(0, dy - (h - 6)) if dy > h - 6 else 0
		for dx: int in range(0, width):
			if notch > 0 and absi(dx - width / 2) < notch:
				continue
			var c: Color = body if dy > 3 else light
			if dx == width - 1 or dy == 0 or dy == h - 1:
				c = ink
			_dot(img, cx - w + dx, cy - h / 2 + dy, c)
	_star(img, cx - w / 2 + 1, cy, 4, light, Color.WHITE, ink)


static func _target(img: Image, cx: int, cy: int, r: int, body: Color, light: Color, ink: Color) -> void:
	_fill_circle(img, cx, cy, r + 1, ink)
	_fill_circle(img, cx, cy, r, light)
	_ring(img, cx, cy, r - 3, body)
	_ring(img, cx, cy, r - 4, body)
	_fill_circle(img, cx, cy, r / 3, body)
	_fill_circle(img, cx, cy, 1, ink)
	_line(img, Vector2i(cx - r - 3, cy), Vector2i(cx + r + 3, cy), ink)
	_line(img, Vector2i(cx, cy - r - 3), Vector2i(cx, cy + r + 3), ink)


static func _orb(img: Image, cx: int, cy: int, r: int, body: Color, light: Color, ink: Color, rng: RandomNumberGenerator) -> void:
	_fill_circle(img, cx, cy, r + 1, ink)
	_fill_circle(img, cx, cy, r, body)
	_fill_circle(img, cx - r / 3, cy - r / 3, r / 3, light)
	for a: int in range(0, 360, 40):
		var angle: float = deg_to_rad(float(a) + (rng.randf_range(-10.0, 10.0) if rng != null else 0.0))
		var p: Vector2i = Vector2i(cx + int(cos(angle) * float(r + 2)), cy + int(sin(angle) * float(r + 2)))
		var q: Vector2i = p + Vector2i(int(cos(angle + 0.6) * 5.0), int(sin(angle + 0.6) * 5.0))
		var z: Vector2i = q + Vector2i(int(cos(angle - 0.4) * 5.0), int(sin(angle - 0.4) * 5.0))
		_line(img, p, q, light)
		_line(img, q, z, body)


static func _crack(img: Image, cx: int, cy: int, length: int, ink: Color) -> void:
	var p: Vector2i = Vector2i(cx, cy)
	for i: int in length:
		_dot(img, p.x, p.y, ink)
		p += Vector2i(1 if i % 3 == 0 else (-1 if i % 3 == 1 else 0), 1)


static func _sparkles(img: Image, cx: int, cy: int, radius: int, count: int, color: Color, rng: RandomNumberGenerator) -> void:
	for _i: int in count:
		var p: Vector2i = Vector2i(cx + rng.randi_range(-radius, radius), cy + rng.randi_range(-radius, radius))
		_dot(img, p.x, p.y, color)
		_dot(img, p.x - 1, p.y, Color(color, 0.6))
		_dot(img, p.x + 1, p.y, Color(color, 0.6))
		_dot(img, p.x, p.y - 1, Color(color, 0.6))
		_dot(img, p.x, p.y + 1, Color(color, 0.6))


static func _rays(img: Image, cx: int, cy: int, color: Color, rng: RandomNumberGenerator) -> void:
	for i: int in 12:
		var angle: float = float(i) * TAU / 12.0 + rng.randf_range(-0.1, 0.1)
		for d: int in range(10, 40):
			if d % 2 == 0:
				var p: Vector2i = Vector2i(cx + int(cos(angle) * float(d)), cy + int(sin(angle) * float(d)))
				if p.x >= 0 and p.y >= 0 and p.x < WIDTH and p.y < HEIGHT:
					img.set_pixel(p.x, p.y, img.get_pixel(p.x, p.y).lerp(color, 0.5))


static func _frame(img: Image, color: Color, width: int) -> void:
	for i: int in width:
		for x: int in WIDTH:
			img.set_pixel(x, i, color)
			img.set_pixel(x, HEIGHT - 1 - i, color)
		for y: int in HEIGHT:
			img.set_pixel(i, y, color)
			img.set_pixel(WIDTH - 1 - i, y, color)


static func _corners(img: Image, color: Color) -> void:
	for corner: Vector2i in [Vector2i(2, 2), Vector2i(WIDTH - 3, 2), Vector2i(2, HEIGHT - 3), Vector2i(WIDTH - 3, HEIGHT - 3)]:
		var sx: int = 1 if corner.x < WIDTH / 2 else -1
		var sy: int = 1 if corner.y < HEIGHT / 2 else -1
		for i: int in 5:
			_dot(img, corner.x + sx * i, corner.y, color)
			_dot(img, corner.x, corner.y + sy * i, color)
		_dot(img, corner.x + sx * 2, corner.y + sy * 2, color)


static func _vignette(img: Image, pal: Dictionary) -> void:
	var ink: Color = pal["ink"]
	for y: int in HEIGHT:
		for x: int in WIDTH:
			var dx: float = (float(x) - float(WIDTH) * 0.5) / (float(WIDTH) * 0.5)
			var dy: float = (float(y) - float(HEIGHT) * 0.5) / (float(HEIGHT) * 0.5)
			var d: float = dx * dx + dy * dy
			if d > 1.15 and _bayer(x, y) < (d - 1.15) * 2.0:
				img.set_pixel(x, y, img.get_pixel(x, y).lerp(ink, 0.5))


#endregion

#region Primitive


static func _bayer(x: int, y: int) -> float:
	return (float(BAYER4[posmod(y, 4) * 4 + posmod(x, 4)]) + 0.5) / 16.0


static func _dot(img: Image, x: int, y: int, c: Color) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return
	if c.a < 1.0:
		img.set_pixel(x, y, img.get_pixel(x, y).lerp(Color(c, 1.0), c.a))
	else:
		img.set_pixel(x, y, c)


static func _fill_rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy: int in range(y, y + h):
		for xx: int in range(x, x + w):
			_dot(img, xx, yy, c)


static func _fill_circle(img: Image, cx: int, cy: int, r: int, c: Color) -> void:
	for dy: int in range(-r, r + 1):
		for dx: int in range(-r, r + 1):
			if dx * dx + dy * dy <= r * r:
				_dot(img, cx + dx, cy + dy, c)


static func _ring(img: Image, cx: int, cy: int, r: int, c: Color) -> void:
	for dy: int in range(-r, r + 1):
		for dx: int in range(-r, r + 1):
			var d: int = dx * dx + dy * dy
			if d <= r * r and d > (r - 1) * (r - 1):
				_dot(img, cx + dx, cy + dy, c)


static func _blob(img: Image, cx: int, cy: int, rx: int, ry: int, c: Color) -> void:
	for dy: int in range(-ry, ry + 1):
		for dx: int in range(-rx, rx + 1):
			var fx: float = float(dx) / float(maxi(rx, 1))
			var fy: float = float(dy) / float(maxi(ry, 1))
			if fx * fx + fy * fy <= 1.0:
				_dot(img, cx + dx, cy + dy, c)


static func _line(img: Image, from: Vector2i, to: Vector2i, c: Color) -> void:
	var steps: int = maxi(absi(to.x - from.x), absi(to.y - from.y))
	for i: int in range(steps + 1):
		var t: float = float(i) / float(maxi(steps, 1))
		_dot(img, int(round(lerpf(from.x, to.x, t))), int(round(lerpf(from.y, to.y, t))), c)


static func _thick_line(img: Image, from: Vector2i, to: Vector2i, thickness: int, c: Color) -> void:
	for dy: int in range(-thickness, thickness + 1):
		for dx: int in range(-thickness, thickness + 1):
			if absi(dx) + absi(dy) <= thickness:
				_line(img, from + Vector2i(dx, dy), to + Vector2i(dx, dy), c)


static func _fill_polygon(img: Image, points: PackedVector2Array, c: Color) -> void:
	var min_y: int = HEIGHT
	var max_y: int = 0
	for p: Vector2 in points:
		min_y = mini(min_y, int(floor(p.y)))
		max_y = maxi(max_y, int(ceil(p.y)))
	for y: int in range(maxi(min_y, 0), mini(max_y, HEIGHT - 1) + 1):
		for x: int in WIDTH:
			if Geometry2D.is_point_in_polygon(Vector2(x, y), points):
				_dot(img, x, y, c)


#endregion
