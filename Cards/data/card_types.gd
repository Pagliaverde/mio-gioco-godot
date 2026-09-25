## Enumerazioni, nomi e colori condivisi da tutto il sistema di carte.
##
## Non contiene logica: serve solo a evitare di ripetere le stesse
## definizioni in ogni file e a dare un unico posto dove aggiungere
## un nuovo elemento, status o rarita'.
class_name CardTypes extends RefCounted


## Gli elementi a cui una carta puo' appartenere.
## Determina le sinergie di battuta e le resistenze future.
enum Element {
	NONE,
	FIRE,
	ICE,
	POISON,
	LIGHTNING,
	NATURE,
	DARK,
}

## Quanto e' rara e potente una carta. Usata dal negozio e dai pacchetti.
enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY,
}

## Effetti persistenti applicati a un giocatore.
## Ogni status ha un comportamento diverso deciso da [BattleBalance].
enum StatusType {
	BURN,      ## Danno nel tempo che si affievolisce.
	POISON,    ## Danno nel tempo che NON si affievolisce (si accumula).
	CHILL,     ## Riduce il mana disponibile nel turno.
	EMPOWER,   ## Aumenta in percentuale il danno inflitto.
	REGEN,     ## Cura nel tempo.
}

## Cosa succede quando peschi una carta che non puoi permetterti.
enum BustPenalty {
	RESOLVE_AND_END,       ## Le carte giocate si risolvono comunque, nessun critico.
	DISCARD_AND_END,       ## Le carte giocate sono perse, nessun critico.
	DISCARD_AND_CRIT_1_5,  ## Le carte sono perse, l'avversario fa danno x1.5.
	DISCARD_AND_CRIT_2,    ## Le carte sono perse, l'avversario fa danno x2.
}

## Esito di un'azione compiuta durante il turno.
enum TurnResult {
	PLAYING,      ## La carta e' stata giocata, si puo' continuare.
	STOPPED,      ## Il giocatore ha scelto di fermarsi.
	BUSTED,       ## Carta troppo cara: turno perso.
	DECK_EMPTY,   ## Non ci sono piu' carte da pescare.
	BATTLE_OVER,  ## La battaglia e' finita.
}

## Fase corrente della battaglia.
enum Phase {
	NOT_STARTED,
	AWAITING_ACTION,  ## In attesa che si peschi o si dica STOP.
	RESOLVING,
	FINISHED,
}

## Strategie usate dall'IA del simulatore.
enum AiPolicy {
	NEVER_STOP,      ## Continua finche' non fa bust (baseline sconsiderata).
	STOP_AT_MANA,    ## Si ferma quando il mana scende sotto una soglia fissa.
	STOP_AT_RATIO,   ## Si ferma quando il mana scende sotto una percentuale.
	ESTIMATED_RISK,  ## Stima la probabilita' di bust dal mazzo e decide di conseguenza.
}


## Nomi leggibili degli elementi (per la UI e i log).
const ELEMENT_NAMES: Dictionary = {
	Element.NONE: "Neutro",
	Element.FIRE: "Fuoco",
	Element.ICE: "Ghiaccio",
	Element.POISON: "Veleno",
	Element.LIGHTNING: "Fulmine",
	Element.NATURE: "Natura",
	Element.DARK: "Oscuro",
}

## Colore associato a ogni elemento (per bordi carta e log).
const ELEMENT_COLORS: Dictionary = {
	Element.NONE: Color(0.75, 0.75, 0.78),
	Element.FIRE: Color(0.95, 0.35, 0.15),
	Element.ICE: Color(0.35, 0.70, 0.95),
	Element.POISON: Color(0.55, 0.80, 0.25),
	Element.LIGHTNING: Color(0.98, 0.85, 0.25),
	Element.NATURE: Color(0.35, 0.75, 0.45),
	Element.DARK: Color(0.55, 0.35, 0.80),
}

## Nomi leggibili degli status.
const STATUS_NAMES: Dictionary = {
	StatusType.BURN: "Brucia",
	StatusType.POISON: "Veleno",
	StatusType.CHILL: "Congelato",
	StatusType.EMPOWER: "Potenziato",
	StatusType.REGEN: "Rigenerazione",
}

## Nomi leggibili delle rarita'.
const RARITY_NAMES: Dictionary = {
	Rarity.COMMON: "Comune",
	Rarity.UNCOMMON: "Non comune",
	Rarity.RARE: "Rara",
	Rarity.EPIC: "Epica",
	Rarity.LEGENDARY: "Leggendaria",
}


## Nome leggibile di un elemento.
static func element_name(element: Element) -> String:
	return ELEMENT_NAMES.get(element, "Sconosciuto")


## Colore di un elemento.
static func element_color(element: Element) -> Color:
	return ELEMENT_COLORS.get(element, Color.WHITE)


## Nome leggibile di uno status.
static func status_name(status: StatusType) -> String:
	return STATUS_NAMES.get(status, "Sconosciuto")


## Nome leggibile di una rarita'.
static func rarity_name(rarity: Rarity) -> String:
	return RARITY_NAMES.get(rarity, "Sconosciuta")


## Nome leggibile di una penalita' di bust.
static func bust_penalty_name(penalty: BustPenalty) -> String:
	match penalty:
		BustPenalty.RESOLVE_AND_END:
			return "carte risolte, nessun critico"
		BustPenalty.DISCARD_AND_END:
			return "carte perse, nessun critico"
		BustPenalty.DISCARD_AND_CRIT_1_5:
			return "carte perse, critico x1.5"
		BustPenalty.DISCARD_AND_CRIT_2:
			return "carte perse, critico x2"
	return "?"
