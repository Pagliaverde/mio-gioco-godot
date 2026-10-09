## Cosa vende il negozio, a che prezzo, e quanto si guadagna combattendo.
##
## [b]Il prezzo dipende dalla rarita', non dalla singola carta.[/b] Cosi' i
## numeri stanno in una tabella sola ([constant BASE_PRICE]) e ribilanciare il
## negozio non vuol dire toccare trentasette carte.
##
## Non e' arbitrario: la rarita' [i]e' gia'[/i] il modello di potenza del gioco.
## [RarityProfile] dice che una leggendaria rende di piu' e costa meno mana:
## quindi vale di piu', e costa di piu'. Il negozio non inventa una scala nuova,
## usa quella che c'e'.
##
## [b]Cosa finisce in vendita:[/b] tutto [CardDatabase]. Se aggiungi una carta al
## gioco, compare in negozio da sola. Non c'e' una lista da tenere aggiornata.
##
## Vedi [code]Shop/README.md[/code].
class_name ShopCatalog extends RefCounted


#region Prezzi


## Prezzo base per rarita', in monete.
##
## [b]E' l'unico numero da toccare per ribilanciare il negozio.[/b] Aggiungi qui
## una fascia di rarita' (quando esistera') e il negozio la vende.
const BASE_PRICE: Dictionary = {
	CardTypes.Rarity.BASE: 60,
	CardTypes.Rarity.RARE: 120,
	CardTypes.Rarity.EPIC: 220,
	CardTypes.Rarity.LEGENDARY: 380,
	CardTypes.Rarity.UNIQUE: 600,
}

## Quanto pesa il costo in mana sul prezzo.
##
## Una carta da piu' mana e' piu' forte: pagarla quanto una da poco non avrebbe
## senso. Il peso e' piccolo di proposito, perche' il grosso lo fa la rarita'.
const PRICE_PER_MANA := 2


## Il prezzo di [param card], in monete.
static func price_of(card: CardData) -> int:
	if card == null:
		return 0
	var base: int = int(BASE_PRICE.get(card.rarity, 100))
	return base + card.cost * PRICE_PER_MANA


#endregion

#region Guadagni


## Le monete con cui si comincia, la prima volta. Vedi [method ShopWallet.ensure_started].
##
## Sta qui e non in [ShopWallet] perche' e' una decisione di [i]economia[/i],
## non di memoria: se un giorno vorrai cambiare quanto si parte, lo cambi con
## gli altri numeri del negozio.
const STARTING_COINS := 300

## Quanto si guadagna vincendo una partita, qualunque essa sia.
##
## [b]Non e' ancora collegato a niente:[/b] la mappa non ha ancora un modo per
## vincere. Quando lo avrai, chiama [code]ShopWallet.add_coins(ShopCatalog.WIN_PAYOUT)[/code]
## dove assegni la vittoria. Vedi [code]Shop/README.md[/code].
const WIN_PAYOUT := 90


#endregion

#region Vetrina


## Tutto quello che il negozio ha in vendita, dal piu' economico al piu' caro.
##
## Ogni voce e' un dizionario:
## [code]{"card": CardData, "price": int, "owned": bool}[/code].
##
## [b]Non filtra le carte possedute:[/b] le mostra lo stesso, con
## [code]owned = true[/code]. Vederle e' mezza la soddisfazione di comprarle, e
## cosi' il negozio non cambia forma sotto gli occhi del giocatore.
static func offers() -> Array[Dictionary]:
	var database: CardDatabase = CardDatabase.load_default()
	var out: Array[Dictionary] = []

	for card: CardData in database.all():
		if card == null:
			continue
		out.append({
			"card": card,
			"price": price_of(card),
			"owned": ShopWallet.owns(card.id),
		})

	return out


## Quante carte ci sono in vendita.
static func offer_count() -> int:
	return CardDatabase.load_default().size()


## Le stesse offerte, raggruppate per rarita'.
##
## Ogni gruppo e' [code]{"profile": RarityProfile, "offers": Array[Dictionary]}[/code],
## dal piu' comune al piu' raro.
##
## [b]Perche' raggruppare:[/b] con trentasette carte in fila il giocatore non sa
## dove guardare. In gruppi la vetrina si legge come una scaletta: prima quello
## che puoi permetterti, poi il resto da desiderare.
##
## L'ordine lo da' [method RarityTable.ordered], che e' gia' la progressione di
## valore del gioco: non ne serve una nuova.
static func groups() -> Array[Dictionary]:
	var table: RarityTable = RarityTable.load_default()
	var all: Array[Dictionary] = offers()
	var groups: Array[Dictionary] = []

	for profile: RarityProfile in table.ordered():
		var bucket: Array[Dictionary] = []
		for offer: Dictionary in all:
			var card: CardData = offer["card"]
			if card != null and card.rarity == profile.rarity:
				bucket.append(offer)
		if bucket.is_empty():
			continue
		groups.append({"profile": profile, "offers": bucket})

	return groups


#endregion
