## Tutto il contenuto della storia, in un posto solo: le zone, i cinque boss,
## i testi, i finali. Niente logica di scena: quella sta in [StoryDirector].
##
## E' la traduzione in dati di [code]Docs/TRAMA_E_MASCHERE.md[/code]. Se vuoi
## cambiare una frase, un mazzo, un livello: e' qui.
class_name StoryData extends RefCounted


## Un boss: chi e', cosa porta, come combatte, cosa lascia.
class StoryBoss extends RefCounted:
	var id: StringName = &""
	var numeral: String = ""
	var display_name: String = ""
	var quote: String = ""
	var what: String = ""
	var wears: String = ""
	var mechanic: String = ""
	var lesson: String = ""

	## La maschera che lascia quando lo batti.
	var reward_mask_id: StringName = &""

	## La maschera che indossa. Vuoto = nessuna; "*tua*" = copia la tua.
	var worn_mask_id: StringName = &""

	## Gavetta del boss (livello: decide il mana).
	var level: int = 1

	## Quanto rischia l'IA (0-1).
	var risk_tolerance: float = 0.4

	## La gabbia: mana tolto al giocatore a ogni suo turno.
	var cage: int = 0

	## Vita e danno rispetto al normale.
	var health_scale: float = 1.0
	var damage_scale: float = 1.0

	## Se true gioca con il mazzo del giocatore (Il Sostituto).
	var copies_player_deck: bool = false

	## Il costruttore del mazzo (vuoto se copia quello del giocatore).
	var deck_builder: Callable

	var intro: PackedStringArray = []
	var victory: PackedStringArray = []
	var defeat: PackedStringArray = []

	## Il mazzo con cui combatte, dato quello del giocatore.
	func build_deck(player_deck: DeckData) -> DeckData:
		if copies_player_deck:
			var copy: DeckData = DeckData.new()
			copy.display_name = "Il tuo (riflesso)"
			copy.entries = player_deck.entries.duplicate()
			return copy
		if deck_builder.is_valid():
			return deck_builder.call()
		return CardLibrary.build_veteran_deck()


## Una zona del teatro.
class StoryZone extends RefCounted:
	var id: StringName = &""
	var title: String = ""
	var subtitle: String = ""
	var color: Color = Color(0.1, 0.08, 0.14)
	var intro: PackedStringArray = []

	## C'e' un Baule di Scena (una maschera base a caso).
	var has_chest: bool = false

	## Il testo del baule.
	var chest_text: String = ""

	## Si vede la platea.
	var shows_audience: bool = false

	## Il boss della zona, se c'e'.
	var boss: StoryBoss = null


#region Zone


static func zones() -> Array[StoryZone]:
	return [
		_camerino(), _piazza(), _galleria(), _palco(), _corridoi(), _auditorium(), _fondo(),
	]


static func _zone(zone_id: StringName, title: String, subtitle: String, color: Color) -> StoryZone:
	var zone: StoryZone = StoryZone.new()
	zone.id = zone_id
	zone.title = title
	zone.subtitle = subtitle
	zone.color = color
	return zone


static func _camerino() -> StoryZone:
	var zone: StoryZone = _zone(&"camerino", "Il Camerino", "La tua stanza", Color("1b1a1d"))
	zone.intro = [
		"Ti svegli in una stanza.\n\nUn letto. Un armadio. Uno specchio rotto, con le schegge ancora dentro la cornice. Al muro, maschere appese a un chiodo: nessuna e' la tua.",
		"Non hai un volto.\n\nNon e' una ferita. E' che nessuno ne ha scritto uno. In questo posto ogni cosa ha una parte: i palazzi sono palazzi, il pubblico e' pubblico, gli attori sono attori.\n\nTu sei l'unica cosa senza copione.",
		"Sul muro, accanto alla porta, qualcuno ha inciso un numero: [b]%d[/b].\n\nNon ricordi di averlo fatto. Ma la mano e' la tua.",
		"Per questo puoi indossare qualsiasi maschera. Per questo vuoi uscire: [i]una cosa senza ruolo non appartiene a una recita.[/i]\n\nDall'altra parte del teatro c'e' un muro. Dietro il muro, l'uscita.",
	]
	zone.has_chest = true
	zone.chest_text = "Sotto il letto c'e' un baule. Ha una targhetta: [b]Baule di Scena[/b].\n\nDentro, una maschera. Non la scegli tu: e' la prima che la mano trova."
	return zone


static func _piazza() -> StoryZone:
	var zone: StoryZone = _zone(&"piazza", "La Piazza Dipinta", "La citta' finta", Color("2a1f3a"))
	zone.intro = [
		"La porta del camerino da' su una piazza.\n\nIl cielo e' una tela dipinta: si vedono le pennellate. I palazzi sono facciate su cavalletti, e dietro c'e' il vuoto. Le strade sono assi di legno viola e velluto consumato.",
		"Gli alberi sono di cartapesta. Da vicino si vede la struttura.\n\nNiente, qui, e' vero. Eppure qualcuno ci ha vissuto per sempre.",
	]
	zone.has_chest = true
	zone.chest_text = "In un angolo della piazza, sotto un lampione che non ha mai fatto luce, un altro [b]Baule di Scena[/b]."
	zone.shows_audience = true
	zone.boss = _comparsa()
	return zone


static func _galleria() -> StoryZone:
	var zone: StoryZone = _zone(&"galleria", "La Galleria degli Specchi", "Migliaia di riflessi", Color("1d2238"))
	zone.intro = [
		"Un corridoio di specchi. Migliaia.\n\nTi vedi riflesso da ogni parte. Dopo un po' ti accorgi che non tutti i riflessi sono tuoi: alcuni si muovono un attimo dopo. Alcuni un attimo prima.",
		"Uno di loro si ferma, e ti guarda.",
	]
	zone.has_chest = true
	zone.chest_text = "Dietro uno specchio incrinato, un [b]Baule di Scena[/b]. Lo specchio riflette il baule, ma non la tua mano che lo apre."
	zone.shows_audience = true
	zone.boss = _sostituto()
	return zone


static func _palco() -> StoryZone:
	var zone: StoryZone = _zone(&"palco", "Il Palco", "Il primo vero pubblico", Color("3a2416"))
	zone.intro = [
		"Oro e rosso. Luci. Il palco vero.\n\nE per la prima volta, davanti a te, [b]c'e' il pubblico[/b]. File e file di manichini. Fermi. Ti fissano.",
		"Al centro del palco c'e' qualcuno che il pubblico ha gia' visto. Si capisce da come sta in piedi.",
	]
	zone.has_chest = true
	zone.chest_text = "Dietro le quinte, tra i fondali arrotolati, l'ultimo [b]Baule di Scena[/b]."
	zone.shows_audience = true
	zone.boss = _prima_attrice()
	return zone


static func _corridoi() -> StoryZone:
	var zone: StoryZone = _zone(&"corridoi", "I Corridoi", "Il dietro, il personale, la gabbia", Color("1c2a1e"))
	zone.intro = [
		"Dietro il palco, i corridoi. Verde malato, neon che friggono. I camerini degli altri, con i nomi sulle porte.\n\nQui lavora il personale del teatro. Gente che ha una parte.",
		"In fondo al corridoio c'e' una gabbia. E davanti alla gabbia, qualcuno con le chiavi.",
	]
	zone.shows_audience = true
	zone.boss = _carceriere()
	return zone


static func _auditorium() -> StoryZone:
	var zone: StoryZone = _zone(&"auditorium", "L'Auditorium", "I manichini", Color("2b1a3e"))
	zone.intro = [
		"La platea. Viola pieno.\n\nMigliaia di manichini, seduti, immobili. Ti danno le spalle: guardano il palco. Nessuno si gira.",
		"Tra te e il fondo della sala c'e' una persona sola. In piedi, nel corridoio centrale. Porta tante maschere, una sopra l'altra, che non si capisce dove finiscano.",
	]
	zone.shows_audience = true
	zone.boss = _ultimo()
	return zone


static func _fondo() -> StoryZone:
	var zone: StoryZone = _zone(&"fondo", "Il Fondo", "Dietro l'ultima fila", Color("0e0c12"))
	zone.intro = []
	return zone


#endregion

#region Boss


static func _boss(boss_id: StringName, numeral: String, boss_name: String) -> StoryBoss:
	var boss: StoryBoss = StoryBoss.new()
	boss.id = boss_id
	boss.numeral = numeral
	boss.display_name = boss_name
	return boss


## I. La Comparsa: non ha mai provato. Difesa pura, ti stanca.
static func _comparsa() -> StoryBoss:
	var boss: StoryBoss = _boss(&"comparsa", "I", "La Comparsa")
	boss.quote = "Fuori non c'e' niente. Meglio qui. Meglio qui."
	boss.what = "Un attore che non ha mai avuto una parte, e ha smesso di volerne una."
	boss.wears = "Nessuna. Ha smesso di sperare, non di recitare."
	boss.mechanic = "Si chiude, si cura, resiste. Non cerca di vincere: cerca che tu smetta."
	boss.lesson = "La difesa pura non vince mai. Chi ha paura di andare fuori copione resta qui."
	boss.reward_mask_id = &"comparsa"
	boss.level = 1
	boss.risk_tolerance = 0.15
	boss.deck_builder = CardLibrary.build_fortress_deck
	boss.intro = [
		"Seduto su una panchina dipinta, uno che non si alza.\n\n\"Fuori non c'e' niente\", dice senza guardarti. \"Meglio qui. Meglio qui.\"",
		"Non ti attacca. Si copre, e aspetta.\n\nIl primo ostacolo non e' il male: e' [b]la comodita'[/b].",
	]
	boss.victory = [
		"La Comparsa si siede di nuovo. Non sembra ferita. Sembra sollevata.\n\n\"Vai\", dice. \"Io resto. Meglio qui.\"",
		"I manichini in lontananza non reagiscono.",
	]
	boss.defeat = [
		"Ti sei fermato troppo. Hai aspettato che fosse lui a sbagliare, e lui non sbaglia mai: non fa niente.\n\n\"Visto?\", dice. \"Meglio qui.\"",
	]
	return boss


## II. Il Sostituto: uno come te, copiato. Gioca il tuo mazzo.
static func _sostituto() -> StoryBoss:
	var boss: StoryBoss = _boss(&"sostituto", "II", "Il Sostituto")
	boss.quote = "Ora ci sono tre di me. Nessuno e' quello vero."
	boss.what = "Uno come te. Ha provato a uscire, ed e' stato sostituito: il teatro ha fatto altre copie."
	boss.wears = "La tua faccia."
	boss.mechanic = "Lo specchio. Non ha un mazzo suo: gioca esattamente le tue carte, con la tua maschera."
	boss.lesson = "Non puoi vincere giocando come giochi sempre. Sei sostituibile: devi essere irripetibile."
	boss.reward_mask_id = &"specchio"
	boss.worn_mask_id = &"*tua*"
	boss.level = 1
	boss.risk_tolerance = 0.40
	boss.copies_player_deck = true
	boss.intro = [
		"Il riflesso che si era fermato esce dallo specchio.\n\nHa la tua faccia. Cioe': non ha un volto, come te. Ma e' la stessa assenza.",
		"\"Ora ci sono tre di me\", dice. \"Nessuno e' quello vero.\"\n\nTira fuori il tuo mazzo. Carta per carta.",
	]
	boss.victory = [
		"Il Sostituto si incrina. Non muore: si [b]sdoppia[/b], e i pezzi tornano negli specchi, uno per riflesso.\n\nTi lascia la sua faccia. Cioe': la tua.",
		"Nessuno, in platea, ha battuto le mani.",
	]
	boss.defeat = [
		"Ha giocato le tue carte meglio di te. Sapeva cosa avresti pescato, perche' l'aveva gia' pescato lui.\n\nUn riflesso ti guarda e sorride. Non hai una bocca per rispondere.",
	]
	return boss


## III. La Prima Attrice: e' uscita, e non c'era nessuno. Burst e Panico di scena.
static func _prima_attrice() -> StoryBoss:
	var boss: StoryBoss = _boss(&"prima_attrice", "III", "La Prima Attrice")
	boss.quote = "Ho visto fuori. Non c'era pubblico. Qui almeno qualcuno guarda."
	boss.what = "La star. E' uscita davvero, ha visto il fuori, ed e' tornata."
	boss.wears = "L'Essere Amato."
	boss.mechanic = "Ti toglie la voce: Panico di scena in grande quantita'. Non ti fa giocare."
	boss.lesson = "Il dubbio. Forse fuori non c'e' niente, e qui qualcuno ti guarda."
	boss.reward_mask_id = &"essere_amato"
	boss.worn_mask_id = &"essere_amato"
	boss.level = 2
	boss.risk_tolerance = 0.45
	boss.deck_builder = StoryData.build_diva_deck
	boss.intro = [
		"Lei non ha bisogno di presentarsi. Il pubblico la conosce.\n\n\"Ho visto fuori\", dice, e per la prima volta qualcuno ti parla come se avessi un volto. \"Non c'era pubblico. Nessuno. Qui almeno qualcuno guarda.\"",
		"Non e' una minaccia. E' un argomento. Ed e' vero.\n\nPoi alza la mano, e la sala si ghiaccia.",
	]
	boss.victory = [
		"La Prima Attrice si inchina. Al pubblico, non a te.\n\n\"Vedrai\", dice piano. \"Vedrai che avevo ragione.\"\n\nTi lascia la maschera dell'Essere Amato. E' leggera, e pesa piu' di tutte.",
		"I manichini restano girati verso il palco. Verso di lei, non verso di te.",
	]
	boss.defeat = [
		"Il Panico di scena ti ha tolto il pubblico, poi la voce. Sei rimasto fermo sotto le luci.\n\n\"Resta\", dice lei. \"Qui qualcuno ti guarda.\"",
	]
	return boss


## IV. Il Carceriere: e' diventato guardia per avere un ruolo. Controllo e gabbia.
static func _carceriere() -> StoryBoss:
	var boss: StoryBoss = _boss(&"carceriere", "IV", "Il Carceriere")
	boss.quote = "Se ti lascio uscire, mi tolgono la parte."
	boss.what = "Era come te. Ha chiesto una parte, e gliel'hanno data: guardiano di chi vuole uscire."
	boss.wears = "Il Dovere."
	boss.mechanic = "La gabbia. Ogni turno ti riduce il pubblico. Non ti uccide: ti tiene fermo finche' non rinunci."
	boss.lesson = "Il sistema non e' malvagio: e' fatto di gente che ha accettato. Serve pazienza, non potenza."
	boss.reward_mask_id = &"dovere"
	boss.worn_mask_id = &"dovere"
	boss.level = 3
	boss.risk_tolerance = 0.25
	boss.cage = 10
	boss.deck_builder = StoryData.build_warden_deck
	boss.intro = [
		"Ha le chiavi alla cintura e una maschera che non si toglie da tanto che la pelle ci e' cresciuta intorno.\n\n\"Se ti lascio uscire\", dice, \"mi tolgono la parte.\"",
		"Non e' cattivo. Era come te. Ha solo chiesto una parte, e questa era l'unica libera.\n\nChiude la gabbia. Da dentro, il pubblico sembra piu' piccolo a ogni turno.",
	]
	boss.victory = [
		"Il Carceriere apre la gabbia. Non te la apre: la apre e basta, come se avesse smesso di essere un lavoro.\n\n\"Tieni\", dice, e ti porge il Dovere. \"Ora il muro sei tu.\"",
		"Dalla sala non arriva un suono.",
	]
	boss.defeat = [
		"La gabbia ha fatto il suo lavoro. Hai avuto sempre meno pubblico, e a un certo punto hai smesso di provarci.\n\n\"Lo fanno tutti\", dice lui. \"Non e' colpa tua.\"",
	]
	return boss


## V. L'Ultimo: ha raggiunto la porta e ci sta davanti. Tutto, usato bene.
static func _ultimo() -> StoryBoss:
	var boss: StoryBoss = _boss(&"ultimo", "V", "L'Ultimo")
	boss.quote = "Non puoi uscire da solo. E io non riesco. Quindi restiamo."
	boss.what = "E' arrivato alla porta. E si e' fermato."
	boss.wears = "Tutte. Una sopra l'altra. Non e' piu' una persona."
	boss.mechanic = "Lo specchio finale. Ti mostra tutto quello che sai fare, usato bene. Non ti fa mai male davvero: ti fa vedere quanto e' lungo il gioco."
	boss.lesson = "L'ultimo test: riesci a lasciare qualcuno indietro?"
	boss.reward_mask_id = &"tutte"
	boss.worn_mask_id = &"tutte"
	boss.level = 4
	boss.risk_tolerance = 0.40
	boss.health_scale = 1.4
	boss.damage_scale = 0.75
	boss.deck_builder = StoryData.build_everything_deck
	boss.intro = [
		"\"Non puoi uscire da solo\", dice. Ha una voce per ogni maschera, e parlano tutte insieme. \"E io non riesco. Quindi restiamo.\"",
		"Non e' cattivo. E' solo. Ha fatto tutta la strada che stai facendo tu, e alla fine non ce l'ha fatta a lasciare la sala.\n\nVuole che tu resti con lui. E' l'unica cosa che vuole.",
	]
	boss.victory = [
		"L'Ultimo si siede nel corridoio centrale, tra i manichini. Le maschere gli scivolano di dosso una a una, e sotto l'ultima non c'e' niente. Come te.\n\n\"Vai\", dice. \"Io non ci riesco.\"",
		"Vincere significa lasciarlo li'. E' l'unica cosa in tutto il teatro che non sembra una vittoria.",
	]
	boss.defeat = [
		"Ti ha mostrato tutto quello che sai fare, fatto meglio. Non ti ha mai fatto davvero male: ti ha fatto vedere quanto e' lungo.\n\n\"Vedi?\", dice. \"Restiamo.\"",
	]
	return boss


## La difficolta' delle impostazioni sposta la gavetta di un boss di un passo:
## facile -1, difficile +1.
static func apply_difficulty(boss: StoryBoss) -> void:
	var delta: int = 0
	match Settings.difficulty():
		"easy":
			delta = -1
		"hard":
			delta = 1
	boss.level = maxi(boss.level + delta, 1)


## Trova un boss dal suo id.
static func find_boss(boss_id: StringName) -> StoryBoss:
	for zone: StoryZone in zones():
		if zone.boss != null and zone.boss.id == boss_id:
			return zone.boss
	return null


#endregion

#region Mazzi dei boss


## Il mazzo della Prima Attrice: burst Ghiaccio e Fulmine, con tanto Congelato.
static func build_diva_deck() -> DeckData:
	var deck: DeckData = DeckData.new()
	deck.display_name = "Prima Attrice"
	var entries: Array[DeckEntry] = [
		DeckEntry.of(CardLibrary.find_by_id(&"ice_frost_bite"), 4),
		DeckEntry.of(CardLibrary.find_by_id(&"support_bulwark"), 2),
		DeckEntry.of(CardLibrary.find_by_id(&"ice_lance"), 2),
		DeckEntry.of(CardLibrary.find_by_id(&"lightning_static_bolt"), 2),
		DeckEntry.of(CardLibrary.find_by_id(&"ice_blizzard"), 3),
		DeckEntry.of(CardLibrary.find_by_id(&"lightning_thunder_strike"), 3),
		DeckEntry.of(CardLibrary.find_by_id(&"ice_absolute_zero"), 1),
		DeckEntry.of(CardLibrary.find_by_id(&"ice_glacier_tomb"), 1),
		DeckEntry.of(CardLibrary.find_by_id(&"lightning_storm_surge"), 1),
	]
	deck.entries = entries
	return deck


## Il mazzo del Carceriere: controllo e chiusura. Scudo enorme, Congelato, status.
static func build_warden_deck() -> DeckData:
	var deck: DeckData = DeckData.new()
	deck.display_name = "Carceriere"
	var entries: Array[DeckEntry] = [
		DeckEntry.of(CardLibrary.find_by_id(&"support_bulwark"), 2),
		DeckEntry.of(CardLibrary.find_by_id(&"ice_frost_bite"), 3),
		DeckEntry.of(CardLibrary.find_by_id(&"nature_thorn_whip"), 2),
		DeckEntry.of(CardLibrary.find_by_id(&"support_iron_wall"), 2),
		DeckEntry.of(CardLibrary.find_by_id(&"poison_toxic_dart"), 2),
		DeckEntry.of(CardLibrary.find_by_id(&"nature_barrier"), 2),
		DeckEntry.of(CardLibrary.find_by_id(&"support_reinforce"), 2),
		DeckEntry.of(CardLibrary.find_by_id(&"ice_blizzard"), 2),
		DeckEntry.of(CardLibrary.find_by_id(&"support_eternal_bulwark"), 1),
		DeckEntry.of(CardLibrary.find_by_id(&"ice_glacier_tomb"), 1),
	]
	deck.entries = entries
	return deck


## Il mazzo dell'Ultimo: tutte le carte del gioco, una copia ciascuna.
static func build_everything_deck() -> DeckData:
	var deck: DeckData = DeckData.new()
	deck.display_name = "Tutto"
	var entries: Array[DeckEntry] = []
	for card: CardData in CardLibrary.build_all():
		entries.append(DeckEntry.of(card, 1))
	deck.entries = entries
	return deck


#endregion

#region Testi


## Le regole, dette nelle parole del teatro.
static func tutorial_pages() -> PackedStringArray:
	return [
		"[b]Come si recita.[/b]\n\nNon hai una mano. A ogni turno hai del [b]Pubblico[/b] (l'attenzione del momento) e peschi una [b]Battuta[/b] dal [b]Copione[/b]. Se puoi permettertela, la reciti. Poi decidi: pescare ancora, o fermarti.",
		"[b]Fuori copione.[/b]\n\nSe peschi una battuta che costa piu' del pubblico che ti resta, esci dal personaggio: la scena crolla, perdi tutto quello che avevi schierato, e il rivale [b]ti ruba la scena[/b] (danno doppio al suo turno).",
		"[b]Il Favore.[/b]\n\nSe ti fermi in tempo, il pubblico non speso ti resta addosso: diventa [b]Favore[/b], che attutisce i colpi. Chi non afferra ogni momento accumula autorevolezza.\n\nA fine turno tutto si somma insieme: l'ordine non conta. E' un quadro, non una sequenza.",
		"[b]Le maschere.[/b]\n\nUna maschera non cambia le battute: cambia le regole intorno. Ogni maschera ha elementi affini (le loro sinergie sono le uniche attive), una regola dell'azzardo, e un prezzo scritto in chiaro.\n\nScegli la maschera prima di ogni scena. Le trovi nei Bauli, o le prendi a chi batti.",
	]


## Cosa si vede guardando la platea, visita dopo visita.
static func audience_lines() -> PackedStringArray:
	return [
		"Da qui si vede la platea. Migliaia di manichini, seduti. Nessuno si muove. Nessuno si e' mai mosso.",
		"La platea, di nuovo. Uguale. Solo che... uno di loro ti sembra in un posto diverso. Sara' la luce.",
		"Quello. Si e' spostato di nuovo. Non fa niente, non parla, non si gira. E' solo... altrove.\n\nNessun altro se ne accorge.",
		"Lo cerchi subito, adesso. Ed e' ancora in un posto nuovo.\n\nIn un teatro dove tutto e' finto, una cosa sola e' vera: quella.",
		"E' li'. Spostato. Ti sei abituato a cercarlo, come si cerca un volto conosciuto in mezzo alla folla.",
	]


## Le pagine dell'ultimo atto, prima della scelta.
static func finale_pages() -> PackedStringArray:
	return [
		"Dietro L'Ultimo, in fondo alla sala, c'e' la porta. La scritta rossa che hai visto per tutto il gioco: [b]EXIT[/b].\n\nLa tocchi. E' tela. E' dipinta sul fondale.\n\nNon e' mai stata un'uscita.",
		"E allora dov'e'?\n\nTi giri. La platea. Migliaia di manichini che ti danno le spalle.\n\n[b]Dietro il pubblico.[/b]",
		"L'unica via d'uscita dal teatro e' attraversare la platea. Camminare tra i manichini, fino all'ultima fila, e uscire dal fondo.\n\nNessuno ci era mai riuscito perche' nessuno aveva capito: la fuga non e' dal palco. E' attraverso chi guarda.",
		"Cammini nel corridoio centrale. Una fila. Un'altra. Le teste di legno, immobili, a destra e a sinistra.\n\nL'ultima fila. Il muro. Una porta vera, di legno, senza scritte.\n\nE dietro di te, un rumore. Uno solo, come un respiro preso da mille petti insieme.",
		"Si sono girati.\n\nTutti. Insieme. Una volta sola.\n\nNon ti attaccano. Non ti parlano. Si sono girati e basta. Ti guardano.",
		"Alla porta, capisci cos'eri.\n\nNon sei un attore fuggito. Sei [b]un ruolo che non e' stato scritto[/b], e il teatro non sapeva dove metterti. Le maschere non erano un travestimento: erano il tuo modo di esistere in un mondo dove si esiste solo avendo una parte.",
		"Fuori c'e' qualcosa. Non e' il vuoto, e non e' un premio: e' il reale. Dove nessuno ha un copione, nessuno ti guarda, e nessuno si ricordera' di te.\n\nPer uscire, devi toglierle tutte. Fuori non ci sono parti.\n\n[b]Riesci a esistere senza essere guardato?[/b]",
	]


## I tre finali: id, titolo, descrizione della scelta, testo.
static func endings() -> Array[Dictionary]:
	return [
		{
			"id": &"vuoto",
			"label": "Esci vuoto",
			"choice": "Ti togli tutte le maschere e attraversi la porta senza niente.",
			"pages": [
				"Le togli una a una. La Tragedia, la Commedia, l'Inganno, il Presagio. Le facce dei boss. Le lasci sul pavimento, davanti all'ultima fila, in un mucchio ordinato.\n\nI manichini guardano il mucchio, non te. Era quello che guardavano da sempre.",
				"Apri la porta. Fuori c'e' luce, e nient'altro che si possa raccontare.\n\nSei libero. Sei anche niente: nessun ruolo, nessun volto, nessun nome. Nessuno sapra' mai che sei stato qui, e nessuno si ricordera' di te.",
				"[i]E' la liberta', e ha il costo esatto che il gioco ti aveva promesso per tutto il tempo.[/i]",
			],
		},
		{
			"id": &"pieno",
			"label": "Esci pieno",
			"choice": "Attraversi la porta con tutte le maschere addosso.",
			"pages": [
				"Le tieni. Tutte. Una sopra l'altra, come L'Ultimo. Apri la porta cosi'.\n\nFuori c'e' gente. Non ti guardano, all'inizio. Poi uno si gira. Poi un altro.",
				"Non esci davvero: il teatro esce con te. Le hai portate fuori, e dove vai le persone iniziano a guardarti. Diventi tu il prossimo teatro: gentile, pieno di storie, e affamato di pubblico.",
				"[i]E' la scelta piu' umana del gioco. Ed e' l'unica in cui il ciclo non si rompe.[/i]",
			],
		},
		{
			"id": &"resta",
			"label": "Non esci",
			"choice": "Ti fermi davanti alla porta e ti togli le maschere, ma resti.",
			"pages": [
				"Ti togli le maschere. Tutte. Poi non apri la porta.\n\nTi siedi nell'ultima fila, tra i manichini. Loro si rigirano verso il palco, uno a uno. Tu no.",
				"Non fuggi e non torni indietro: rinunci a entrambe le cose. Diventi, per la prima volta, una persona con un volto solo, in un posto che non ha piu' potere su di te perche' non gli stai piu' chiedendo niente.",
				"[i]E' il finale piu' difficile, e l'unico che rompe il teatro senza rompere te. Non sei libero e non sei al sicuro. Sei solo, finalmente, tuo.[/i]",
			],
		},
	]


#endregion
