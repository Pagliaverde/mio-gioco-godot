## Le nove maschere del gioco, definite in codice (sul modello di [CardLibrary]).
##
## Quattro si trovano nei [b]Bauli di Scena[/b]: Tragedia, Commedia, Inganno,
## Presagio. Cinque si [b]vincono[/b] dai boss: la Comparsa (vuota), lo Specchio,
## l'Essere Amato, il Dovere e Tutte.
##
## Ogni maschera e' affinita' + regola dell'azzardo + postura + prezzo. I numeri
## sono qui, in un posto solo, e le regole sono hook in [BattleState].
class_name MaskLibrary extends RefCounted


## Costruisce una maschera a partire dai suoi pezzi.
static func make_mask(
	mask_id: StringName,
	mask_name: String,
	gambit: CardTypes.MaskGambit,
	affinity: Array[int],
	accent: Color,
	face: String
) -> MaskData:
	var mask: MaskData = MaskData.new()
	mask.id = mask_id
	mask.display_name = mask_name
	mask.gambit = gambit
	mask.element_affinity = affinity
	mask.accent = accent
	mask.face = face
	mask.synergies = synergies_for(affinity)
	return mask


## Il pacchetto di sinergie di un'affinita': le regole globali i cui elementi
## stanno tutti dentro l'affinita'. Un elemento fuori affinita' non ha sinergie.
static func synergies_for(affinity: Array[int]) -> Array[SynergyRule]:
	var rules: Array[SynergyRule] = []
	if affinity.is_empty():
		return rules
	for rule: SynergyRule in CardLibrary.build_synergies():
		if not affinity.has(int(rule.primary_element)):
			continue
		if rule.secondary_element != CardTypes.Element.NONE and not affinity.has(int(rule.secondary_element)):
			continue
		rules.append(rule)
	return rules


#region Le maschere base (nei Bauli)


## La Tragedia: Fuoco e Oscuro. Quando vai fuori copione, il rivale ti ruba la
## scena [b]x3[/b]. Devi giocare difensivo: meno carte, meno danno.
static func tragedy() -> MaskData:
	var mask: MaskData = make_mask(&"tragedia", "La Tragedia", CardTypes.MaskGambit.TRAGEDY,
		[CardTypes.Element.FIRE, CardTypes.Element.DARK], Color("b4342e"), "frown")
	mask.rarity = CardTypes.Rarity.RARE
	mask.quote = "Ogni battuta e' l'ultima."
	mask.description = "Fuoco e Oscuro sono in sinergia e fanno +40% danno. Il tuo danno sale del 10%."
	mask.drawback = "Se vai fuori copione, il rivale ti ruba la scena x3 invece che x2."
	mask.affinity_multiplier = 1.4
	mask.damage_scale = 1.1
	return mask


## La Commedia: Fulmine e Natura. La prima volta che vai fuori copione in un
## turno, non perdi il turno. Danno basso: vinci, ma lentamente.
static func comedy() -> MaskData:
	var mask: MaskData = make_mask(&"commedia", "La Commedia", CardTypes.MaskGambit.COMEDY,
		[CardTypes.Element.LIGHTNING, CardTypes.Element.NATURE], Color("d9a62b"), "smile")
	mask.rarity = CardTypes.Rarity.RARE
	mask.quote = "Sbagliare e' una battuta come un'altra."
	mask.description = "Fulmine e Natura sono in sinergia. Il primo passo falso di ogni turno e' perdonato: la carta torna nel mazzo e continui."
	mask.drawback = "Tutto il tuo danno e' ridotto del 20%."
	mask.damage_scale = 0.8
	return mask


## L'Inganno: Veleno e Oscuro. Il primo scudo di ogni turno e' raddoppiato e
## il rivale non vede il tuo mana. Nessun danno diretto: se ti chiude, non reagisci.
static func deceit() -> MaskData:
	var mask: MaskData = make_mask(&"inganno", "L'Inganno", CardTypes.MaskGambit.DECEIT,
		[CardTypes.Element.POISON, CardTypes.Element.DARK], Color("5f3f8f"), "half")
	mask.rarity = CardTypes.Rarity.RARE
	mask.quote = "Nessuno sa quanto pubblico hai davvero."
	mask.description = "Veleno e Oscuro sono in sinergia. Lo scudo piu' grande che giochi in un turno vale doppio, e il rivale non vede il tuo pubblico."
	mask.drawback = "Il tuo danno diretto e' ridotto del 15%."
	mask.damage_scale = 0.85
	return mask


## Il Presagio: Ghiaccio e Veleno. Vedi sempre la prossima carta prima di
## decidere. Nessun vantaggio nei numeri: se giochi male, e' come non averla.
static func omen() -> MaskData:
	var mask: MaskData = make_mask(&"presagio", "Il Presagio", CardTypes.MaskGambit.OMEN,
		[CardTypes.Element.ICE, CardTypes.Element.POISON], Color("3f8fb4"), "eye")
	mask.rarity = CardTypes.Rarity.RARE
	mask.quote = "So gia' cosa dirai."
	mask.description = "Ghiaccio e Veleno sono in sinergia. Vedi sempre la prossima carta del copione prima di decidere se pescare."
	mask.drawback = "Nessun bonus ai numeri: la fortuna diventa calcolo, e il calcolo tocca a te."
	mask.affinity_multiplier = 1.2
	return mask


#endregion

#region Le maschere dei boss


## La Comparsa (vuota): non ha regola, non ha affinita'. E' la maschera di chi
## non ha mai osato. Tenerla e' una scelta, e pesa.
static func extra() -> MaskData:
	var mask: MaskData = make_mask(&"comparsa", "La Comparsa", CardTypes.MaskGambit.NONE,
		[], Color("8a8a8a"), "empty")
	mask.rarity = CardTypes.Rarity.BASE
	mask.won_from = &"comparsa"
	mask.quote = "Fuori non c'e' niente. Meglio qui. Meglio qui."
	mask.description = "Non fa niente. Valgono le regole normali del gioco e tutte le sinergie."
	mask.drawback = "Nessun vantaggio. E' la maschera di chi non ha mai osato."
	return mask


## Lo Specchio: le carte che l'avversario ha giocato ti costano meno il turno
## dopo. Trasforma la sua forza nella tua.
static func mirror() -> MaskData:
	var mask: MaskData = make_mask(&"specchio", "Lo Specchio", CardTypes.MaskGambit.MIRROR,
		[CardTypes.Element.ICE, CardTypes.Element.LIGHTNING], Color("9fc7d9"), "mirror")
	mask.rarity = CardTypes.Rarity.EPIC
	mask.won_from = &"sostituto"
	mask.quote = "Ora ci sono tre di me. Nessuno e' quello vero."
	mask.description = "Ghiaccio e Fulmine sono in sinergia. Le carte che il rivale ha giocato nel suo turno ti costano il 30% in meno nel tuo."
	mask.drawback = "Riflette solo cio' che il rivale mostra: contro chi gioca poco, non serve."
	return mask


## L'Essere Amato: la prima volta che vai fuori copione, il pubblico ti perdona.
## Ma solo una volta per incontro: e' la maschera dell'attore che ha esaurito il credito.
static func beloved() -> MaskData:
	var mask: MaskData = make_mask(&"essere_amato", "L'Essere Amato", CardTypes.MaskGambit.FORGIVENESS,
		[CardTypes.Element.FIRE, CardTypes.Element.LIGHTNING], Color("d96b8c"), "heart")
	mask.rarity = CardTypes.Rarity.EPIC
	mask.won_from = &"prima_attrice"
	mask.quote = "Ho visto fuori. Non c'era pubblico."
	mask.description = "Fuoco e Fulmine sono in sinergia. La prima volta che vai fuori copione, il pubblico ti perdona e continui."
	mask.drawback = "Una volta sola per incontro. Il credito, poi, e' finito."
	return mask


## Il Dovere: la prima volta che lo scudo assorbe un colpo, non si consuma.
## Diventi tu il muro: e' la maschera del boss che hai appena battuto.
static func duty() -> MaskData:
	var mask: MaskData = make_mask(&"dovere", "Il Dovere", CardTypes.MaskGambit.GUARD,
		[CardTypes.Element.NATURE, CardTypes.Element.ICE], Color("4f8f5f"), "bars")
	mask.rarity = CardTypes.Rarity.EPIC
	mask.won_from = &"carceriere"
	mask.quote = "Se ti lascio uscire, mi tolgono la parte."
	mask.description = "Natura e Ghiaccio sono in sinergia. La prima volta che il tuo scudo assorbe un colpo, regge e non si consuma."
	mask.drawback = "Ti trasforma nel boss che hai appena battuto. Fermo, come lui."
	return mask


## Tutte: non e' una maschera, e' un mucchio. Ogni regola buona e' attiva, ogni
## elemento e' affine. E' la liberta' assoluta, e ha un prezzo che non e' nei numeri.
static func all_masks() -> MaskData:
	var mask: MaskData = make_mask(&"tutte", "Tutte", CardTypes.MaskGambit.ALL,
		[
			CardTypes.Element.FIRE, CardTypes.Element.ICE, CardTypes.Element.POISON,
			CardTypes.Element.LIGHTNING, CardTypes.Element.NATURE, CardTypes.Element.DARK,
		], Color("e8d9a8"), "many")
	mask.rarity = CardTypes.Rarity.LEGENDARY
	mask.won_from = &"ultimo"
	mask.quote = "Non puoi uscire da solo. E io non riesco. Quindi restiamo."
	mask.description = "Ogni elemento e' affine, ogni sinergia si attiva. Vedi la prossima carta, il pubblico ti perdona una volta, lo scudo regge, le carte del rivale ti costano meno."
	mask.drawback = "Per averla hai lasciato indietro l'unico che ti somigliava."
	mask.affinity_multiplier = 1.15
	mask.off_affinity_multiplier = 1.0
	return mask


#endregion


## Tutte le maschere, nell'ordine in cui compaiono nella storia.
static func build_all() -> Array[MaskData]:
	return [
		tragedy(), comedy(), deceit(), omen(),
		extra(), mirror(), beloved(), duty(), all_masks(),
	]


## Le quattro maschere che si trovano nei Bauli di Scena.
static func chest_masks() -> Array[MaskData]:
	return [tragedy(), comedy(), deceit(), omen()]


## Trova una maschera tramite id. Ritorna null se non esiste.
static func find_by_id(mask_id: StringName) -> MaskData:
	for mask: MaskData in build_all():
		if mask.id == mask_id:
			return mask
	return null
