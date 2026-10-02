## Le parole del teatro: traduce i termini del motore in quelli della storia.
##
## Il motore parla di mana, scudo e bust (vedi [code]Cards/README.md[/code]).
## La storia parla di Pubblico, Favore e Fuori copione (vedi la tabella in
## [code]Docs/TRAMA_E_MASCHERE.md[/code]). Il motore non cambia: cambia solo
## cio' che il giocatore legge.
class_name StoryWords extends RefCounted


## Sostituzioni in ordine: le piu' specifiche prima, cosi' non si pestano.
const REPLACEMENTS: Array[Array] = [
	["✖ BUST!", "✖ FUORI COPIONE!"],
	["BUST", "FUORI COPIONE"],
	["ottiene il CRITICO", "ti ruba la scena"],
	["ha il CRITICO", "ha la scena rubata"],
	["CRITICO", "SCENA RUBATA"],
	["(le carte giocate vengono perse)", "(la scena crolla: le battute schierate sono perse)"],
	["converte", "trasforma"],
	["in scudo", "in favore"],
	["scudo avversario", "favore del rivale"],
	["con lo scudo", "con il favore"],
	["di scudo", "di favore"],
	["lo scudo", "il favore"],
	["scudo", "favore"],
	["mana", "pubblico"],
	["brucia:", "sotto i riflettori:"],
	["avvelenato:", "la maldicenza rode:"],
	["si rigenera:", "ha il bis:"],
	["potenziato:", "ispirato:"],
	["congelato", "panico di scena"],
	["Brucia", "Riflettori"],
	["Veleno", "Maldicenza"],
	["Congelato", "Panico di scena"],
	["Potenziato", "Ispirazione"],
	["Rigenerazione", "Bis"],
	["gioca ", "recita "],
	["Mazzo", "Repertorio"],
	["mazzo", "copione"],
	["carte", "battute"],
	["carta", "battuta"],
	["al prossimo turno", "alla prossima scena"],
	["il turno", "la scena"],
	["del turno", "della scena"],
	["Turno", "Scena"],
	["turno", "scena"],
	["BATTAGLIA", "SCENA"],
]


## Traduce una riga del log del motore.
static func translate(line: String) -> String:
	var out: String = line
	for pair: Array in REPLACEMENTS:
		out = out.replace(pair[0], pair[1])
	return out


## Il nome di uno status nelle parole del teatro.
static func status_name(status: CardTypes.StatusType) -> String:
	match status:
		CardTypes.StatusType.BURN:
			return "Riflettori"
		CardTypes.StatusType.POISON:
			return "Maldicenza"
		CardTypes.StatusType.CHILL:
			return "Panico"
		CardTypes.StatusType.EMPOWER:
			return "Ispirazione"
		CardTypes.StatusType.REGEN:
			return "Bis"
	return CardTypes.status_name(status)


## Il nome di una rarita' nelle parole del teatro.
static func rarity_name(rarity: CardTypes.Rarity) -> String:
	match rarity:
		CardTypes.Rarity.BASE:
			return "Ruolo Base"
		CardTypes.Rarity.RARE:
			return "Ruolo di Rilievo"
		CardTypes.Rarity.EPIC:
			return "Ruolo da Cartellone"
		CardTypes.Rarity.LEGENDARY:
			return "Ruolo da Locandina"
		CardTypes.Rarity.UNIQUE:
			return "Ruolo Unico"
	return CardTypes.rarity_name(rarity)


## Il livello e' la gavetta.
static func level_name(level: int) -> String:
	return "Gavetta %d" % level
