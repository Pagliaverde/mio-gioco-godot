## Il contenuto del mondo esplorabile, in un posto solo: le mappe, gli oggetti,
## i negozi e le comparse che si incontrano per strada.
##
## E' il fratello di [StoryData]: li' ci sono le zone, i boss e i testi della
## storia; qui c'e' quello che serve per [i]camminarci dentro[/i]. Se vuoi
## cambiare un prezzo, un oggetto o chi si incontra nel velluto: e' qui.
class_name WorldData extends RefCounted


## La mappa da cui comincia una partita nuova.
const START_MAP := &"camerino"

## Il punto d'arrivo di una partita nuova (vedi [WorldSpawn]).
const START_SPAWN := &"letto"

## Il nome della moneta del gioco.
const MONEY_NAME := "Biglietti"


#region Mappe


## Le mappe, nell'ordine della traversata. Ogni mappa e' una zona di [StoryData]
## (stesso id), e la sua scena sta in [code]World/maps/<id>.tscn[/code].
##
## Oltre alle sette zone della storia ci sono le [b]stanze laterali[/b]
## ([method side_rooms]): il ridotto, il magazzino, la graticcia, la sartoria.
## Non hanno boss: hanno casse, negozi, comparse e qualcuno con cui parlare.
static func map_ids() -> Array[StringName]:
	return [
		&"camerino", &"piazza", &"galleria", &"palco", &"corridoi", &"auditorium", &"fondo",
		&"ridotto", &"magazzino", &"graticcia", &"sartoria",
	]


## Il percorso della scena di una mappa.
static func map_path(map_id: StringName) -> String:
	return "res://World/maps/%s.tscn" % map_id


## True se la mappa esiste.
static func has_map(map_id: StringName) -> bool:
	return map_ids().has(map_id) and ResourceLoader.exists(map_path(map_id))


## La zona della storia che corrisponde a una mappa (titolo, colore, testi).
## Per le stanze laterali ne costruisce una al volo da [method side_rooms].
static func zone_for(map_id: StringName) -> StoryData.StoryZone:
	for zone: StoryData.StoryZone in StoryData.zones():
		if zone.id == map_id:
			return zone
	var side: Dictionary = side_rooms().get(map_id, {})
	if side.is_empty():
		return null
	var room: StoryData.StoryZone = StoryData.StoryZone.new()
	room.id = map_id
	room.title = side["title"]
	room.subtitle = side["subtitle"]
	room.intro = side["intro"]
	room.chest_text = side.get("chest_text", "")
	return room


## Le stanze laterali: titolo, sottotitolo e cosa si vede entrando.
static func side_rooms() -> Dictionary:
	return {
		&"ridotto": {
			"title": "Il Ridotto",
			"subtitle": "Il bar del teatro, tra un atto e l'altro",
			"intro": PackedStringArray([
				"Un foyer di velluto e specchi appannati. Il bancone del bar, la biglietteria con il vetro, poltroncine che nessuno usa.\n\nQui si aspetta che ricominci lo spettacolo. Ma lo spettacolo non ha mai smesso.",
			]),
		},
		&"magazzino": {
			"title": "Il Magazzino delle Scene",
			"subtitle": "Dove finiscono i fondali",
			"intro": PackedStringArray([
				"Fondali arrotolati, quinte appoggiate al muro, casse con scritto sopra il nome di spettacoli che nessuno ricorda.\n\nTra le casse qualcosa si muove. Non sono manichini del pubblico: sono quelli da prova, quelli col gesso addosso.",
			]),
		},
		&"graticcia": {
			"title": "La Graticcia",
			"subtitle": "Sopra il palco, tra le corde",
			"intro": PackedStringArray([
				"Una passerella di assi sopra il palco. Corde, contrappesi, riflettori appesi a testa in giu'.\n\nDa qui si vede tutto lo spettacolo dall'alto. Gli attori sembrano piccoli. Anche tu.",
			]),
		},
		&"sartoria": {
			"title": "La Sartoria",
			"subtitle": "Mille costumi, nessun corpo",
			"intro": PackedStringArray([
				"File di grucce, costumi appesi come persone che aspettano il turno. Manichini da sarto senza testa.\n\nIn fondo, dietro il bancone, qualcuno cuce una maschera che non finisce mai.",
			]),
		},
	}


#endregion

#region Oggetti


## Gli oggetti che si comprano e si trovano. Ogni oggetto ha:
## [code]name[/code], [code]text[/code] (cosa fa), [code]price[/code],
## [code]heal[/code] (vita ridata, -1 = tutta) e [code]shield[/code]
## (Favore con cui cominci la prossima scena).
static func items() -> Dictionary:
	return {
		&"te_caldo": {
			"name": "Te' caldo",
			"text": "Un bicchiere di te' del bar del teatro. Ridà 150 di vita.",
			"price": 60, "heal": 150, "shield": 0,
		},
		&"camomilla": {
			"name": "Camomilla del suggeritore",
			"text": "Il suggeritore la beve prima delle prime. Ridà tutta la vita.",
			"price": 180, "heal": -1, "shield": 0,
		},
		&"mazzo_di_fiori": {
			"name": "Mazzo di fiori",
			"text": "Qualcuno te li ha lasciati in camerino. La prossima scena cominci con 80 di Favore.",
			"price": 90, "heal": 0, "shield": 80,
		},
	}


## Un oggetto dal suo id, o un dizionario vuoto.
static func item(item_id: StringName) -> Dictionary:
	return items().get(item_id, {})


#endregion

#region Negozi


## I negozi del teatro. [code]stock[/code] e' una lista di
## [code][tipo, id][/code]: [code]"card"[/code] (una battuta da aggiungere al
## repertorio), [code]"mask"[/code] (una maschera dei Bauli) o
## [code]"item"[/code] (un oggetto di [method items]).
static func shops() -> Dictionary:
	return {
		&"burattinaio": {
			"title": "La Baracca del Burattinaio",
			"keeper": "Il Burattinaio",
			"greeting": "Il burattino nella baracca alza la testa di legno. \"Battute nuove, battute usate! Si paga in biglietti, come tutto qui.\"",
			"farewell": "\"Torna quando avrai piu' biglietti. Tornano tutti.\"",
			"stock": [
				["item", &"te_caldo"],
				["item", &"mazzo_di_fiori"],
				["card", &"fire_ember"],
				["card", &"ice_frost_bite"],
				["card", &"support_bulwark"],
				["card", &"nature_thorn_whip"],
				["card", &"lightning_static_bolt"],
				["card", &"poison_toxic_dart"],
				["mask", &"tragedia"],
				["mask", &"commedia"],
			],
		},
		&"spaccio": {
			"title": "Lo Spaccio del Personale",
			"keeper": "La Guardarobiera",
			"greeting": "Dietro il bancone, una donna con cento grucce. \"Per il personale. Ma se paghi, sei personale anche tu.\"",
			"farewell": "\"Riporta le grucce.\"",
			"stock": [
				["item", &"te_caldo"],
				["item", &"camomilla"],
				["item", &"mazzo_di_fiori"],
				["card", &"fire_blaze"],
				["card", &"ice_blizzard"],
				["card", &"lightning_thunder_strike"],
				["card", &"nature_life_bloom"],
				["card", &"dark_drain"],
				["card", &"support_iron_wall"],
				["mask", &"inganno"],
				["mask", &"presagio"],
			],
		},
		&"bigliettaia": {
			"title": "La Biglietteria",
			"keeper": "La Bigliettaia",
			"greeting": "Dietro il vetro, la bigliettaia. Non alza gli occhi. \"Platea esaurita. Ma per il resto, si vende tutto.\"",
			"farewell": "\"Lo spettacolo e' gia' cominciato. E' sempre gia' cominciato.\"",
			"stock": [
				["item", &"te_caldo"],
				["item", &"camomilla"],
				["item", &"mazzo_di_fiori"],
				["card", &"fire_inferno"],
				["card", &"ice_glacier_tomb"],
				["card", &"lightning_storm_surge"],
				["card", &"poison_plague"],
				["card", &"dark_blood_pact"],
				["card", &"support_war_drum"],
			],
		},
	}


## Un negozio dal suo id, o un dizionario vuoto.
static func shop(shop_id: StringName) -> Dictionary:
	return shops().get(shop_id, {})


## Il prezzo di una battuta: dipende dalla rarita'.
static func card_price(card: CardData) -> int:
	if card == null:
		return 0
	match card.rarity:
		CardTypes.Rarity.BASE:
			return 40
		CardTypes.Rarity.RARE:
			return 80
		CardTypes.Rarity.EPIC:
			return 160
		CardTypes.Rarity.LEGENDARY:
			return 320
		CardTypes.Rarity.UNIQUE:
			return 600
	return 100


## Il prezzo di una maschera dei Bauli comprata invece che trovata.
const MASK_PRICE := 260


#endregion

#region Comparse (gli incontri minori)


## Chi si incontra camminando nelle quinte. Non sono boss: scene brevi, con
## meno vita, che danno biglietti. [b]Non sono i manichini della platea[/b]:
## quelli non si muovono e non attaccano mai (vedi il documento di design).
## Sono i manichini [i]da prova[/i] del laboratorio, le macchie di vernice
## viva dei fondali, le controfigure.
static func extras() -> Dictionary:
	return {
		&"macchia": {
			"name": "Macchia di vernice",
			"line": "Una macchia di vernice viola si stacca dal fondale e ti si para davanti.",
			"deck": "poison", "level": 1, "risk": 0.30, "health": 0.30, "money": 22,
		},
		&"manichino_prova": {
			"name": "Manichino da prova",
			"line": "Un manichino da prova, di quelli del laboratorio, ti sbarra la strada. Ha i segni del gesso addosso.",
			"deck": "fortress", "level": 1, "risk": 0.20, "health": 0.30, "money": 25,
		},
		&"riflesso": {
			"name": "Riflesso ribelle",
			"line": "Un riflesso si stacca dallo specchio un attimo prima di te.",
			"deck": "mirror", "level": 2, "risk": 0.40, "health": 0.30, "money": 35,
		},
		&"controfigura": {
			"name": "Controfigura",
			"line": "Una controfigura in calzamaglia nera: recita la tua parte, ma peggio.",
			"deck": "aggressive", "level": 2, "risk": 0.45, "health": 0.40, "money": 40,
		},
		&"attrezzista": {
			"name": "Attrezzista",
			"line": "Un attrezzista con un rotolo di corda. \"Qui non puoi stare.\"",
			"deck": "ice", "level": 3, "risk": 0.30, "health": 0.40, "money": 50,
		},
	}


## Chi si incontra nelle quinte di una mappa (vuoto = nessuno).
static func encounter_table(map_id: StringName) -> Array[StringName]:
	match map_id:
		&"piazza":
			return [&"macchia", &"macchia", &"manichino_prova"]
		&"galleria":
			return [&"riflesso", &"riflesso", &"macchia"]
		&"palco":
			return [&"controfigura", &"manichino_prova"]
		&"corridoi":
			return [&"attrezzista", &"manichino_prova", &"controfigura"]
		&"magazzino":
			return [&"manichino_prova", &"manichino_prova", &"macchia"]
		&"graticcia":
			return [&"attrezzista", &"controfigura"]
		&"sartoria":
			return [&"manichino_prova", &"controfigura"]
	return []


## Una comparsa come [StoryData.StoryBoss], cosi' [StoryBattle] la recita
## senza sapere che non e' un boss.
static func extra_as_boss(extra_id: StringName) -> StoryData.StoryBoss:
	var data: Dictionary = extras().get(extra_id, {})
	if data.is_empty():
		return null
	var boss: StoryData.StoryBoss = StoryData.StoryBoss.new()
	boss.id = extra_id
	boss.display_name = data["name"]
	boss.level = int(data["level"])
	boss.risk_tolerance = float(data["risk"])
	boss.health_scale = float(data["health"])
	match str(data["deck"]):
		"mirror":
			boss.copies_player_deck = true
		"fortress":
			boss.deck_builder = CardLibrary.build_fortress_deck
		"aggressive":
			boss.deck_builder = CardLibrary.build_aggressive_deck
		"poison":
			boss.deck_builder = CardLibrary.build_elemental_deck.bind(CardTypes.Element.POISON)
		"ice":
			boss.deck_builder = CardLibrary.build_elemental_deck.bind(CardTypes.Element.ICE)
	StoryData.apply_difficulty(boss)
	return boss


#endregion

#region Ricompense


## I biglietti che lascia un boss battuto.
static func boss_money(boss_id: StringName) -> int:
	match boss_id:
		&"comparsa":
			return 120
		&"sostituto":
			return 180
		&"prima_attrice":
			return 250
		&"carceriere":
			return 320
		&"ultimo":
			return 400
	return 100


## Quanti biglietti perdi quando il teatro ripete la sera (una parte di quelli
## che hai).
const WHITEOUT_LOSS := 0.2


#endregion
