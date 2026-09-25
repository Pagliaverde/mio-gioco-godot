## Le carte del gioco, definite in codice.
##
## [b]Perche' in codice e non in .tres?[/b] Perche' cosi' il motore e il
## simulatore funzionano subito, senza dover creare a mano decine di file.
##
## Quando vorrai modificarle dall'inspector, esegui
## [code]res://Cards/tools/generate_cards.gd[/code]: genera i .tres a partire
## da questa stessa tabella.
##
## [b]═══ LA REGOLA STRUTTURALE ═══[/b]
##
## [b]Il costo di una carta dice cosa fa.[/b] Questa e' la regola piu'
## importante del gioco, piu' di qualsiasi numero:
##
## [codeblock]
##   3-4 mana  ->  SETUP   non fa danno. Scudo, cura, Congelato, buff.
##   5-6 mana  ->  ATTrito Brucia e Veleno: danno LENTO ma sicuro.
##   7-9 mana  ->  BURST   danno IMMEDIATO. Veloce ma rischi il bust.
## [/codeblock]
##
## [b]Perche' funziona:[/b] cosi' non esiste una scala di efficienza, esistono
## due modi diversi di vincere.
##
## [codeblock]
##   Economico  ->  accumuli status, vinci in ~10 turni, non rischi mai
##   Costoso    ->  burst, vinci in ~5 turni, ma rischi il bust
## [/codeblock]
##
## E' la tensione classica tra [i]attrito[/i] e [i]esplosione[/i]: il deck
## building diventa una scelta di identita', non di ottimizzazione.
##
## [b]═══ PERCHE' IL VELENO NON STA TRA LE CARTE ECONOMICHE ═══[/b]
##
## Il Veleno non decade mai, quindi si accumula in modo [b]esponenziale[/b]:
## 8, 16, 24, 32... Se lo si potesse applicare con carte da 3 mana, un mazzo
## tutto-veleno vincerebbe in 5 turni [b]senza mai rischiare[/b], e la
## meccanica del bust diventerebbe inutile.
##
## Per questo gli status stanno nel tier intermedio (5-6 mana). Le carte da
## 3-4 mana sono pura difesa, che non puo' vincere da sola.
##
## Se il simulatore mostrera' che il Veleno domina comunque, basta mettere
## [code]poison_decay = 1[/code] in [BattleBalance]: il Veleno diventa un
## Brucia potenziato. E' un numero, non un cambio di struttura.
class_name CardLibrary extends RefCounted


#region Costruzione carte


## Crea una carta a partire dai suoi pezzi.
static func make_card(
	card_id: StringName,
	card_name: String,
	cost: int,
	element: CardTypes.Element,
	rarity: CardTypes.Rarity,
	effects: Array,
	tags: PackedStringArray = PackedStringArray()
) -> CardData:
	var card: CardData = CardData.new()
	card.id = card_id
	card.display_name = card_name
	card.cost = cost
	card.element = element
	card.rarity = rarity
	card.tags = tags

	var typed_effects: Array[CardEffect] = []
	for effect: CardEffect in effects:
		typed_effects.append(effect)
	card.effects = typed_effects

	return card


## Scorciatoia per "infliggi N danni".
static func damage(amount: int, element_override: CardTypes.Element = CardTypes.Element.NONE) -> DealDamageEffect:
	var effect: DealDamageEffect = DealDamageEffect.new()
	effect.amount = amount
	effect.element_override = element_override
	return effect


## Scorciatoia per "guadagni N scudo".
static func shield(amount: int) -> GainShieldEffect:
	var effect: GainShieldEffect = GainShieldEffect.new()
	effect.amount = amount
	return effect


## Scorciatoia per "recuperi N vita".
static func heal(amount: int) -> HealEffect:
	var effect: HealEffect = HealEffect.new()
	effect.amount = amount
	return effect


## Scorciatoia per "applica N strati di uno status".
static func status(what: CardTypes.StatusType, stacks: int, self_target: bool = false) -> ApplyStatusEffect:
	var effect: ApplyStatusEffect = ApplyStatusEffect.new()
	effect.status = what
	effect.stacks = stacks
	effect.to_self = self_target
	return effect


## Scorciatoia per "questo turno +N% danno".
static func turn_buff(percent: int) -> TurnDamageBuffEffect:
	var effect: TurnDamageBuffEffect = TurnDamageBuffEffect.new()
	effect.percent = percent
	return effect


## Scorciatoia per "questo turno +N danno piatto".
static func flat_bonus(amount: int) -> FlatDamageBonusEffect:
	var effect: FlatDamageBonusEffect = FlatDamageBonusEffect.new()
	effect.amount = amount
	return effect


## Scorciatoia per "perdi N vita".
static func self_damage(amount: int) -> LoseHealthEffect:
	var effect: LoseHealthEffect = LoseHealthEffect.new()
	effect.amount = amount
	return effect


## Scorciatoia per "questo turno +N a ogni status inflitto".
static func amplify_status(extra: int) -> AmplifyStatusEffect:
	var effect: AmplifyStatusEffect = AmplifyStatusEffect.new()
	effect.extra_stacks = extra
	return effect


#endregion

#region Elementi


## Le carte del Fuoco: Brucia (danno lento) e danno diretto.
##
## [b]Brucia vs Veleno:[/b] con lo stesso decadimento, la differenza sta negli
## strati. La Brucia usa [b]strati piccoli[/b] (2-4) quindi dura pochi turni:
## e' un danno rapido e affidabile. Il Veleno usa [b]strati grandi[/b] (4-7)
## e quindi dura molto di piu': e' un investimento.
##
## Brucia 3 = 3+2+1 = 6 danni in 3 turni.
## Veleno 6 = 6+5+4+3+2+1 = 21 danni in 6 turni.
static func fire_cards() -> Array[CardData]:
	var Element: CardTypes.Element = CardTypes.Element.FIRE
	return [
		# --- SETUP (3-4): nessun danno immediato ---
		make_card(&"fire_flame_guard", "Guardia Fiammeggiante", 4, Element, CardTypes.Rarity.COMMON,
			[shield(8)]),

		# --- ATTrito (5-6): danno lento ---
		make_card(&"fire_ember", "Braci", 5, Element, CardTypes.Rarity.COMMON,
			[status(CardTypes.StatusType.BURN, 4)]),
		make_card(&"fire_flame_slash", "Fendente di Fiamma", 6, Element, CardTypes.Rarity.COMMON,
			[damage(12)]),

		# --- BURST (7-9): danno immediato ---
		make_card(&"fire_blaze", "Vampa", 7, Element, CardTypes.Rarity.COMMON,
			[damage(15)]),
		make_card(&"fire_inferno", "Inferno", 8, Element, CardTypes.Rarity.RARE,
			[damage(17), status(CardTypes.StatusType.BURN, 2)]),
		make_card(&"fire_conflagration", "Conflagrazione", 9, Element, CardTypes.Rarity.EPIC,
			[damage(23)]),
	]


## Le carte del Ghiaccio: controllo e difesa.
##
## Il Congelato toglie mana all'avversario: e' l'unica carta "economica" che
## rallenta davvero, perche' non fa danno ma gli toglie una risorsa.
static func ice_cards() -> Array[CardData]:
	var Element: CardTypes.Element = CardTypes.Element.ICE
	return [
		# --- SETUP (3-4) ---
		make_card(&"ice_frost_bite", "Morso di Gelo", 3, Element, CardTypes.Rarity.COMMON,
			[status(CardTypes.StatusType.CHILL, 2)]),
		make_card(&"ice_barrier", "Barriera di Gelo", 4, Element, CardTypes.Rarity.COMMON,
			[shield(8)]),

		# --- BURST (6-9) ---
		make_card(&"ice_lance", "Lancia di Ghiaccio", 6, Element, CardTypes.Rarity.COMMON,
			[damage(13)]),
		make_card(&"ice_blizzard", "Tormenta", 7, Element, CardTypes.Rarity.UNCOMMON,
			[damage(13), status(CardTypes.StatusType.CHILL, 2)]),
		make_card(&"ice_absolute_zero", "Zero Assoluto", 9, Element, CardTypes.Rarity.EPIC,
			[damage(22), status(CardTypes.StatusType.CHILL, 3)]),
	]


## Le carte del Veleno: il danno lento che [b]dura a lungo[/b].
##
## [b]Tier: ATTrito e BURST.[/b] Il Veleno si applica in strati grandi, quindi
## totalizza molto danno ma arriva lentamente. Vedi la nota in cima al file.
##
## Il Veleno [b]deve decadere[/b]: senza decadimento il suo danno dipende dalla
## durata della partita e diventa 3-4 volte piu' efficiente del danno diretto.
static func poison_cards() -> Array[CardData]:
	var Element: CardTypes.Element = CardTypes.Element.POISON
	return [
		# --- ATTrito (5-6): il Veleno come investimento ---
		make_card(&"poison_toxic_dart", "Dardo Tossico", 5, Element, CardTypes.Rarity.COMMON,
			[status(CardTypes.StatusType.POISON, 4)]),
		make_card(&"poison_acid_spit", "Sputo Acido", 6, Element, CardTypes.Rarity.COMMON,
			[damage(9), status(CardTypes.StatusType.POISON, 2)]),

		# --- BURST (7-9) ---
		make_card(&"poison_venom_cloud", "Nube Venefica", 7, Element, CardTypes.Rarity.UNCOMMON,
			[status(CardTypes.StatusType.POISON, 6)]),
		make_card(&"poison_plague", "Piaga", 8, Element, CardTypes.Rarity.RARE,
			[damage(14), status(CardTypes.StatusType.POISON, 4)]),
		make_card(&"poison_miasma", "Miasma Letale", 9, Element, CardTypes.Rarity.EPIC,
			[damage(18), status(CardTypes.StatusType.POISON, 4)]),
	]


## Le carte del Fulmine: burst puro e potenziamenti.
static func lightning_cards() -> Array[CardData]:
	var Element: CardTypes.Element = CardTypes.Element.LIGHTNING
	return [
		# --- SETUP (3-4) ---
		make_card(&"lightning_charge", "Carica", 3, Element, CardTypes.Rarity.COMMON,
			[flat_bonus(4)]),
		make_card(&"lightning_shield_arc", "Arco Elettrico", 4, Element, CardTypes.Rarity.COMMON,
			[shield(8)]),

		# --- BURST (6-9) ---
		make_card(&"lightning_static_bolt", "Dardo Statico", 6, Element, CardTypes.Rarity.COMMON,
			[damage(13)]),
		make_card(&"lightning_thunder_strike", "Colpo di Tuono", 7, Element, CardTypes.Rarity.UNCOMMON,
			[damage(16)]),
		make_card(&"lightning_storm_surge", "Tempesta", 9, Element, CardTypes.Rarity.EPIC,
			[damage(15), turn_buff(30)]),
	]


## Le carte della Natura: sostegno, cura e rigenerazione.
##
## [b]Tier: quasi tutte SETUP.[/b] La Natura non vince da sola: serve a farti
## sopravvivere abbastanza a lungo da far lavorare gli status o il burst.
static func nature_cards() -> Array[CardData]:
	var Element: CardTypes.Element = CardTypes.Element.NATURE
	return [
		# --- SETUP (3-4) ---
		make_card(&"nature_rejuvenate", "Rinvigorire", 3, Element, CardTypes.Rarity.COMMON,
			[heal(8)]),
		make_card(&"nature_thorn_whip", "Frusta di Spine", 4, Element, CardTypes.Rarity.COMMON,
			[shield(8)]),

		# --- SETUP / ATTrito (5-7) ---
		make_card(&"nature_barrier", "Barriera di Rovi", 6, Element, CardTypes.Rarity.COMMON,
			[shield(12)]),
		make_card(&"nature_life_bloom", "Fioritura", 7, Element, CardTypes.Rarity.UNCOMMON,
			[heal(16), status(CardTypes.StatusType.REGEN, 4, true)]),

		# --- BURST (8) ---
		make_card(&"nature_forest_wrath", "Ira della Foresta", 8, Element, CardTypes.Rarity.UNCOMMON,
			[damage(18)]),
	]


## Le carte dell'Oscuro: ruba vita, ma a un prezzo.
static func dark_cards() -> Array[CardData]:
	var Element: CardTypes.Element = CardTypes.Element.DARK
	return [
		# --- SETUP (4) ---
		make_card(&"dark_drain_minor", "Risucchio Minore", 4, Element, CardTypes.Rarity.COMMON,
			[heal(9), self_damage(2)]),

		# --- ATTrito / BURST (6-9) ---
		make_card(&"dark_drain", "Risucchio", 6, Element, CardTypes.Rarity.COMMON,
			[damage(13), heal(5)]),
		make_card(&"dark_curse", "Maledizione", 7, Element, CardTypes.Rarity.UNCOMMON,
			[status(CardTypes.StatusType.POISON, 5)]),
		make_card(&"dark_sacrifice", "Sacrificio", 9, Element, CardTypes.Rarity.RARE,
			[damage(28), self_damage(7)]),
	]


## Le carte di supporto: neutre, potenziano le altre o difendono.
##
## [b]Tier: quasi tutte SETUP.[/b] Sono le carte che rendono possibile un mazzo
## economico, e che danno all'attrito il suo equivalente dei moltiplicatori.
##
## [b]Nota sui potenziamenti:[/b] i moltiplicatori percentuali valgono in
## proporzione a quante carte giochi. Con 12 mana e carte da 6-9, ne giochi solo
## 2 per turno: quindi costano poco e rendono poco. E' voluto, cosi' restano
## carte da mazzo economico e non dominano quello esplosivo.
static func support_cards() -> Array[CardData]:
	var None: CardTypes.Element = CardTypes.Element.NONE
	return [
		# --- SETUP economico (3-4) ---
		make_card(&"support_bulwark", "Baluardo", 3, None, CardTypes.Rarity.COMMON,
			[shield(6)]),
		make_card(&"support_focus", "Concentrazione", 3, None, CardTypes.Rarity.COMMON,
			[flat_bonus(4)]),
		make_card(&"support_toxic_recipe", "Ricetta Tossica", 4, None, CardTypes.Rarity.UNCOMMON,
			[amplify_status(2)]),
		make_card(&"support_battle_cry", "Grido di Battaglia", 4, None, CardTypes.Rarity.UNCOMMON,
			[turn_buff(25)]),

		# --- ATTrito / difesa pesante (5-7) ---
		make_card(&"support_iron_wall", "Muro di Ferro", 5, None, CardTypes.Rarity.COMMON,
			[shield(10)]),
		make_card(&"support_war_drum", "Tamburo di Guerra", 5, None, CardTypes.Rarity.RARE,
			[turn_buff(40)]),
		make_card(&"support_reinforce", "Rinforzi", 7, None, CardTypes.Rarity.COMMON,
			[shield(14)]),
	]


## Tutte le carte del gioco, in un unico array.
static func build_all() -> Array[CardData]:
	var all_cards: Array[CardData] = []
	all_cards.append_array(fire_cards())
	all_cards.append_array(ice_cards())
	all_cards.append_array(poison_cards())
	all_cards.append_array(lightning_cards())
	all_cards.append_array(nature_cards())
	all_cards.append_array(dark_cards())
	all_cards.append_array(support_cards())
	return all_cards


## Trova una carta tramite id.
static func find_by_id(card_id: StringName) -> CardData:
	for card: CardData in build_all():
		if card.id == card_id:
			return card
	return null


## Tutte le carte di un elemento.
static func cards_of_element(element: CardTypes.Element) -> Array[CardData]:
	var result: Array[CardData] = []
	for card: CardData in build_all():
		if card.element == element:
			result.append(card)
	return result


#endregion

#region Mazzi


## Mazzo [b]ATTrito[/b]: difesa economica + Veleno. Vince lentamente, senza rischiare.
##
## [b]E' una filosofia di gioco, non una scala di efficienza.[/b] Non fa quasi
## danno immediato: accumula scudo e Veleno e aspetta.
##
## Il suo punto debole e' la lentezza: se l'avversario lo chiude in fretta,
## il Veleno non ha il tempo di ripagare l'investimento.
static func build_attrition_deck() -> DeckData:
	var deck: DeckData = DeckData.new()
	deck.display_name = "Attrito"

	var entries: Array[DeckEntry] = [
		# Difesa pura (3 mana): non puo' vincere, ma ti tiene in vita.
		DeckEntry.of(find_by_id(&"support_bulwark"), 3),
		DeckEntry.of(find_by_id(&"nature_rejuvenate"), 2),
		DeckEntry.of(find_by_id(&"ice_frost_bite"), 2),
		# L'amplificatore: il "moltiplicatore" dell'attrito.
		DeckEntry.of(find_by_id(&"support_toxic_recipe"), 2),
		# Danno lento: e' questo che uccide.
		DeckEntry.of(find_by_id(&"fire_ember"), 2),
		DeckEntry.of(find_by_id(&"poison_toxic_dart"), 3),
		DeckEntry.of(find_by_id(&"support_iron_wall"), 2),
		DeckEntry.of(find_by_id(&"poison_venom_cloud"), 2),
	]
	deck.entries = entries
	return deck


## Mazzo [b]EQUILIBRATO[/b]: la meta' strada tra attrito ed esplosione.
##
## E' il mazzo di riferimento: non eccelle in niente, quindi non deve dominare,
## ma nemmeno essere ingiocabile. Se questo mazzo sta intorno al 50%, il gioco
## e' sano.
static func build_starter_deck() -> DeckData:
	var deck: DeckData = DeckData.new()
	deck.display_name = "Equilibrato"

	var entries: Array[DeckEntry] = [
		# Setup
		DeckEntry.of(find_by_id(&"support_bulwark"), 2),
		DeckEntry.of(find_by_id(&"ice_frost_bite"), 2),
		DeckEntry.of(find_by_id(&"nature_rejuvenate"), 1),
		# Attrito
		DeckEntry.of(find_by_id(&"poison_toxic_dart"), 2),
		DeckEntry.of(find_by_id(&"support_iron_wall"), 2),
		# Burst
		DeckEntry.of(find_by_id(&"fire_flame_slash"), 2),
		DeckEntry.of(find_by_id(&"ice_lance"), 2),
		DeckEntry.of(find_by_id(&"nature_barrier"), 1),
		DeckEntry.of(find_by_id(&"lightning_thunder_strike"), 2),
		DeckEntry.of(find_by_id(&"fire_blaze"), 1),
		DeckEntry.of(find_by_id(&"fire_inferno"), 1),
		DeckEntry.of(find_by_id(&"poison_plague"), 1),
	]
	deck.entries = entries
	return deck


## Mazzo [b]ESPLOSIVO[/b]: quasi solo carte costose. Veloce, ma il bust e' dietro l'angolo.
##
## [b]E' la scommessa:[/b] ogni carta vale molto mana per punto, quindi fa molto
## danno... ma se peschi quella da 9 mana con 7 disponibili, perdi il turno.
##
## Se questo mazzo domina, le carte costose sono troppo forti.
## Se perde sempre, nessuno rischiera' mai e il bust e' una meccanica inutile.
static func build_burst_deck() -> DeckData:
	var deck: DeckData = DeckData.new()
	deck.display_name = "Esplosivo"

	var entries: Array[DeckEntry] = [
		DeckEntry.of(find_by_id(&"fire_flame_slash"), 2),
		DeckEntry.of(find_by_id(&"lightning_static_bolt"), 2),
		DeckEntry.of(find_by_id(&"ice_lance"), 2),
		DeckEntry.of(find_by_id(&"fire_blaze"), 2),
		DeckEntry.of(find_by_id(&"lightning_thunder_strike"), 2),
		DeckEntry.of(find_by_id(&"fire_inferno"), 2),
		DeckEntry.of(find_by_id(&"poison_plague"), 2),
		DeckEntry.of(find_by_id(&"nature_forest_wrath"), 1),
		DeckEntry.of(find_by_id(&"fire_conflagration"), 2),
		DeckEntry.of(find_by_id(&"poison_miasma"), 1),
	]
	deck.entries = entries
	return deck


## Mazzo [b]AGGRESSIVO[/b]: danno + potenziamenti economici.
##
## Non punta sulle carte piu' costose ma sui moltiplicatori. Con "Grido di
## Battaglia" (+25%) e "Tamburo di Guerra" (+40%) ogni carta vale di piu'.
##
## [b]Nota:[/b] i moltiplicatori rendono in proporzione a quante carte giochi,
## quindi questo mazzo e' piu' forte quando riesce a giocare 3+ carte per turno.
static func build_aggressive_deck() -> DeckData:
	var deck: DeckData = DeckData.new()
	deck.display_name = "Aggressivo"

	var entries: Array[DeckEntry] = [
		DeckEntry.of(find_by_id(&"support_focus"), 2),
		DeckEntry.of(find_by_id(&"support_battle_cry"), 2),
		DeckEntry.of(find_by_id(&"support_bulwark"), 2),
		DeckEntry.of(find_by_id(&"fire_flame_slash"), 3),
		DeckEntry.of(find_by_id(&"lightning_static_bolt"), 2),
		DeckEntry.of(find_by_id(&"fire_blaze"), 2),
		DeckEntry.of(find_by_id(&"fire_inferno"), 2),
		DeckEntry.of(find_by_id(&"lightning_storm_surge"), 2),
		DeckEntry.of(find_by_id(&"dark_sacrifice"), 1),
	]
	deck.entries = entries
	return deck


## Mazzo [b]FORTEZZA[/b]: scudo a volonta' e pochi colpi pesanti per chiudere.
##
## Serve a rispondere a una domanda precisa: [b]la difesa pura puo' vincere?[/b]
## Se questo mazzo resta sotto il 40%, la risposta e' no — e va bene cosi':
## significa che serve comunque un piano offensivo.
##
## Se invece accumulare scudo basta a vincere, lo scudo e' troppo forte e va
## ridotto [code]mana_to_shield_ratio[/code].
static func build_fortress_deck() -> DeckData:
	var deck: DeckData = DeckData.new()
	deck.display_name = "Fortezza"

	var entries: Array[DeckEntry] = [
		DeckEntry.of(find_by_id(&"support_bulwark"), 3),
		DeckEntry.of(find_by_id(&"nature_thorn_whip"), 2),
		DeckEntry.of(find_by_id(&"ice_barrier"), 2),
		DeckEntry.of(find_by_id(&"support_iron_wall"), 2),
		DeckEntry.of(find_by_id(&"nature_barrier"), 3),
		DeckEntry.of(find_by_id(&"nature_life_bloom"), 2),
		DeckEntry.of(find_by_id(&"support_reinforce"), 2),
		DeckEntry.of(find_by_id(&"fire_conflagration"), 2),
	]
	deck.entries = entries
	return deck


## Mazzo [b]mono-elemento[/b]: serve a testare quanto sono forti le sinergie.
##
## Con 2 copie di ogni carta dello stesso elemento, le sinergie si attivano
## quasi ogni turno. Se questo mazzo stravince, alza [code]Min Primary[/code]
## delle sinergie da 2 a 3.
static func build_elemental_deck(element: CardTypes.Element) -> DeckData:
	var deck: DeckData = DeckData.new()
	deck.display_name = "Mono %s" % CardTypes.element_name(element)

	var cards: Array[CardData] = cards_of_element(element)
	if cards.is_empty():
		return deck

	var entries: Array[DeckEntry] = []
	for card: CardData in cards:
		entries.append(DeckEntry.of(card, 2))

	# Qualche scudo neutro, altrimenti i mazzi senza difesa crollano subito.
	entries.append(DeckEntry.of(find_by_id(&"support_bulwark"), 3))
	deck.entries = entries
	return deck


## Mazzo [b]VETERANO[/b]: avversario di riferimento, onesto e senza trucchi.
##
## [b]E' il mazzo da usare contro un giocatore umano.[/b] Mescola difesa
## economica, danno medio e due carte pesanti per chiudere.
##
## Non usa Veleno, non accumula scudo all'infinito, non sfrutta nessuna
## meccanica in modo estremo: e' un avversario che gioca "come un giocatore
## normale", quindi adatto a misurare se il bilanciamento e' sano.
##
## Se batti sempre anche questo, il problema non e' l'avversario.
static func build_veteran_deck() -> DeckData:
	var deck: DeckData = DeckData.new()
	deck.display_name = "Veterano"

	var entries: Array[DeckEntry] = [
		# Difesa economica (3-4): tiene il passo senza dominare.
		DeckEntry.of(find_by_id(&"support_bulwark"), 3),
		DeckEntry.of(find_by_id(&"ice_frost_bite"), 2),
		DeckEntry.of(find_by_id(&"nature_rejuvenate"), 2),
		# Danno medio (6): il corpo del mazzo.
		DeckEntry.of(find_by_id(&"fire_flame_slash"), 2),
		DeckEntry.of(find_by_id(&"ice_lance"), 2),
		DeckEntry.of(find_by_id(&"lightning_static_bolt"), 2),
		DeckEntry.of(find_by_id(&"support_iron_wall"), 2),
		# Peso (7-9): pochi colpi pesanti per chiudere.
		DeckEntry.of(find_by_id(&"lightning_thunder_strike"), 2),
		DeckEntry.of(find_by_id(&"fire_blaze"), 2),
		DeckEntry.of(find_by_id(&"fire_inferno"), 1),
		DeckEntry.of(find_by_id(&"fire_conflagration"), 1),
	]
	deck.entries = entries
	return deck


## Gli archetipi a confronto nel torneo.
##
## [b]Servono a rispondere a una domanda sola:[/b] esiste una strategia che
## domina tutte le altre? Se si', il deck building non e' piu' una scelta.
##
## Nota: due mazzi per le sinergie estreme (Mono Fuoco, Mono Veleno) e uno
## per ogni filosofia (Attrito, Equilibrato, Esplosivo, Aggressivo, Fortezza).
static func meta_decks() -> Array[DeckData]:
	var decks: Array[DeckData] = [
		build_veteran_deck(),
		build_attrition_deck(),
		build_starter_deck(),
		build_aggressive_deck(),
		build_burst_deck(),
		build_fortress_deck(),
		build_elemental_deck(CardTypes.Element.FIRE),
		build_elemental_deck(CardTypes.Element.POISON),
	]
	return decks


## Tabella degli archetipi: costo, rischio ed efficienza a confronto.
##
## La colonna che conta di piu' e' [b]TIPO[/b]: mostra come ogni mazzo vince.
static func describe_archetypes(mana_start: int) -> String:
	var lines: PackedStringArray = []
	var sep: String = "=".repeat(104)

	lines.append(sep)
	lines.append("  ARCHETIPI DI MAZZO  (rischio calcolato con %d mana per turno)" % mana_start)
	lines.append(sep)
	lines.append("  %-14s %6s %7s %8s %11s %9s %-11s" % [
		"MAZZO", "CARTE", "COSTO", "MAX", "EFFICIENZA", "RISCHIO", "TIPO",
	])
	lines.append("-".repeat(104))

	for deck: DeckData in meta_decks():
		lines.append("  %-14s %6d %7.2f %8d %11.2f %8.1f%% %-11s" % [
			deck.display_name,
			deck.card_count(),
			deck.average_cost(),
			deck.highest_cost(),
			deck.average_efficiency(),
			deck.average_risk(mana_start) * 100.0,
			deck.risk_archetype(mana_start),
		])

	lines.append(sep)
	lines.append("  TIPO = quanto e' disposto a rischiare il mazzo:")
	lines.append("    prudente    = quasi mai bust")
	lines.append("    equilibrato = bust occasionale")
	lines.append("    avido       = bust frequente, ma carte molto efficienti")
	lines.append("    temerario   = bust molto frequente")
	lines.append("")
	lines.append("  Lettura: EFFICIENZA e' la ricompensa del rischio. Se il mazzo")
	lines.append("  piu' avido non ha efficienza piu' alta, le carte costose")
	lines.append("  non ripagano e nessuno rischiera' mai.")
	lines.append(sep)

	return "\n".join(lines)


#endregion

#region Sinergie


## Le sinergie di default: premi per chi specializza il mazzo su un elemento.
##
## Sono il modo in cui il "bravo a costruire il deck" viene ricompensato,
## visto che l'ordine delle carte non conta.
static func build_synergies() -> Array[SynergyRule]:
	var rules: Array[SynergyRule] = []

	# --- Specializzazioni mono-elemento --------------------------------------

	var fire_rule: SynergyRule = SynergyRule.new()
	fire_rule.id = &"syn_fire_overflow"
	fire_rule.display_name = "Fuoco Divampante"
	fire_rule.primary_element = CardTypes.Element.FIRE
	fire_rule.min_primary = 2
	fire_rule.damage_multiplier = 1.4
	fire_rule.applies_to_element = CardTypes.Element.FIRE
	rules.append(fire_rule)

	var ice_rule: SynergyRule = SynergyRule.new()
	ice_rule.id = &"syn_ice_dominance"
	ice_rule.display_name = "Dominio del Gelo"
	ice_rule.primary_element = CardTypes.Element.ICE
	ice_rule.min_primary = 2
	ice_rule.damage_multiplier = 1.25
	ice_rule.applies_to_element = CardTypes.Element.ICE
	ice_rule.bonus_status = CardTypes.StatusType.CHILL
	ice_rule.bonus_status_stacks = 2
	rules.append(ice_rule)

	var poison_rule: SynergyRule = SynergyRule.new()
	poison_rule.id = &"syn_poison_toxicity"
	poison_rule.display_name = "Tossicita' Crescente"
	poison_rule.primary_element = CardTypes.Element.POISON
	poison_rule.min_primary = 2
	poison_rule.bonus_status = CardTypes.StatusType.POISON
	poison_rule.bonus_status_stacks = 4
	rules.append(poison_rule)

	var lightning_rule: SynergyRule = SynergyRule.new()
	lightning_rule.id = &"syn_lightning_overload"
	lightning_rule.display_name = "Sovraccarico"
	lightning_rule.primary_element = CardTypes.Element.LIGHTNING
	lightning_rule.min_primary = 2
	lightning_rule.damage_multiplier = 1.45
	lightning_rule.applies_to_element = CardTypes.Element.LIGHTNING
	rules.append(lightning_rule)

	var nature_rule: SynergyRule = SynergyRule.new()
	nature_rule.id = &"syn_nature_growth"
	nature_rule.display_name = "Rigoglio"
	nature_rule.primary_element = CardTypes.Element.NATURE
	nature_rule.min_primary = 2
	nature_rule.bonus_shield = 8
	rules.append(nature_rule)

	var dark_rule: SynergyRule = SynergyRule.new()
	dark_rule.id = &"syn_dark_ritual"
	dark_rule.display_name = "Rituale Oscuro"
	dark_rule.primary_element = CardTypes.Element.DARK
	dark_rule.min_primary = 2
	dark_rule.damage_multiplier = 1.3
	dark_rule.applies_to_element = CardTypes.Element.DARK
	dark_rule.bonus_status = CardTypes.StatusType.POISON
	dark_rule.bonus_status_stacks = 3
	rules.append(dark_rule)

	# --- Combo tra elementi diversi ------------------------------------------

	var steam_rule: SynergyRule = SynergyRule.new()
	steam_rule.id = &"syn_fire_ice_steam"
	steam_rule.display_name = "Vapore Tossico"
	steam_rule.primary_element = CardTypes.Element.FIRE
	steam_rule.min_primary = 1
	steam_rule.secondary_element = CardTypes.Element.ICE
	steam_rule.min_secondary = 1
	steam_rule.bonus_status = CardTypes.StatusType.POISON
	steam_rule.bonus_status_stacks = 3
	rules.append(steam_rule)

	var storm_rule: SynergyRule = SynergyRule.new()
	storm_rule.id = &"syn_ice_lightning_storm"
	storm_rule.display_name = "Tempesta di Ghiaccio"
	storm_rule.primary_element = CardTypes.Element.ICE
	storm_rule.min_primary = 1
	storm_rule.secondary_element = CardTypes.Element.LIGHTNING
	storm_rule.min_secondary = 1
	storm_rule.damage_multiplier = 1.2
	storm_rule.applies_to_element = CardTypes.Element.NONE
	rules.append(storm_rule)

	return rules


#endregion
