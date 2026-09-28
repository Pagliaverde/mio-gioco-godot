## Controlla che ogni carta rispetti il modello di potenza della sua rarita'.
##
## [b]Non e' un bilanciatore:[/b] non ti dice se una carta e' divertente.
## Ti dice se una carta [i]mente sulla propria rarita'[/i], cioe' se fa piu'
## o meno di quanto la sua fascia promette. E' cosi' che si tengono sotto
## controllo centinaia di carte senza tararle una per una.
##
## Controlla:
## [codeblock]
##   - id presente, univoco e in formato valido
##   - costo dentro la banda della rarita'
##   - potenza (power_score) vicina al budget, con la tolleranza del profilo
##   - effetti e illustrazione presenti
## [/codeblock]
##
## La potenza e' la stessa misura usata dal simulatore: cosi' il modello di
## rarita' e la simulazione parlano la stessa lingua.
@tool
class_name CardValidator extends RefCounted


## Quanto e' grave un problema trovato.
enum Severity {
	WARNING,  ## La carta e' giocabile ma incoerente col modello.
	ERROR,    ## La carta rompe qualcosa (id mancante o duplicato, costo impossibile).
}


## Somma la potenza dichiarata dagli effetti di una carta.
## Stessa formula di [method CardInstance.power_score], ma senza istanza.
static func card_power(card: CardData) -> float:
	if card == null:
		return 0.0
	var total: float = 0.0
	for effect: CardEffect in card.effects:
		if effect != null:
			total += effect.power_score(card)
	return total


## Efficienza di una carta: potenza per punto di mana.
static func card_efficiency(card: CardData) -> float:
	if card == null or card.cost <= 0:
		return 0.0
	return card_power(card) / float(card.cost)


## Controlla una singola carta. Ritorna l'elenco dei problemi trovati.
##
## Ogni voce e' [code]{ "severity": Severity, "message": String }[/code].
static func validate_card(card: CardData, table: RarityTable) -> Array[Dictionary]:
	var issues: Array[Dictionary] = []

	if card == null:
		issues.append(_issue(Severity.ERROR, "Carta nulla."))
		return issues

	var id_text: String = String(card.id).strip_edges()
	if id_text.is_empty():
		issues.append(_issue(Severity.ERROR, "Id mancante."))
	elif not _is_valid_id(id_text):
		issues.append(_issue(Severity.WARNING,
			"Id '%s': usa minuscolo, numeri e underscore (es. fire_inferno)." % id_text))

	if card.display_name.strip_edges().is_empty():
		issues.append(_issue(Severity.WARNING, "Nome mancante."))

	if card.cost <= 0:
		issues.append(_issue(Severity.ERROR, "Costo %d: una carta deve costare almeno 1 mana." % card.cost))
		return issues

	if card.effects.is_empty():
		issues.append(_issue(Severity.WARNING, "Nessun effetto: la carta non fa niente."))

	var profile: RarityProfile = table.get_profile(card.rarity) if table != null else null
	if profile != null:
		if not profile.is_cost_in_band(card.cost):
			issues.append(_issue(Severity.WARNING,
				"Costo %d fuori banda per '%s' (%s)." % [
					card.cost, profile.display_name, profile.band_label(),
				]))

		var budget: float = profile.power_budget(card.cost)
		var power: float = card_power(card)
		var low: float = budget * (1.0 - profile.tolerance)
		var high: float = budget * (1.0 + profile.tolerance)

		if power < low:
			issues.append(_issue(Severity.WARNING,
				"Potenza %.1f sotto il budget di '%s' (%.1f attesi, minimo %.1f): debole per la sua rarita'." % [
					power, profile.display_name, budget, low,
				]))
		elif power > high:
			issues.append(_issue(Severity.WARNING,
				"Potenza %.1f sopra il budget di '%s' (%.1f attesi, massimo %.1f): troppo forte per la sua rarita'." % [
					power, profile.display_name, budget, high,
				]))

	if card.art == null:
		issues.append(_issue(Severity.WARNING, "Nessuna illustrazione assegnata."))

	return issues


## Controlla un intero insieme di carte e aggrega i problemi.
##
## Ritorna [code]{ checked, errors, warnings, entries, by_rarity }[/code].
## [code]entries[/code] elenca solo le carte con problemi; [code]by_rarity[/code]
## contiene l'efficienza media osservata per fascia, da confrontare con l'attesa.
static func validate(cards: Array[CardData], table: RarityTable) -> Dictionary:
	var entries: Array[Dictionary] = []
	var errors: int = 0
	var warnings: int = 0
	var seen_ids: Dictionary = {}
	var by_rarity: Dictionary = {}

	for card: CardData in cards:
		if card == null:
			continue

		# Distribuzione osservata (anche per le carte senza problemi).
		var key: int = card.rarity
		if not by_rarity.has(key):
			by_rarity[key] = {"count": 0, "total_efficiency": 0.0}
		by_rarity[key]["count"] = int(by_rarity[key]["count"]) + 1
		by_rarity[key]["total_efficiency"] = float(by_rarity[key]["total_efficiency"]) + card_efficiency(card)

		var card_issues: Array[Dictionary] = validate_card(card, table)

		var id_text: String = String(card.id).strip_edges()
		if not id_text.is_empty():
			if seen_ids.has(id_text):
				card_issues.append(_issue(Severity.ERROR, "Id duplicato: '%s' esiste gia'." % id_text))
			else:
				seen_ids[id_text] = true

		for issue: Dictionary in card_issues:
			if issue["severity"] == Severity.ERROR:
				errors += 1
			else:
				warnings += 1

			entries.append({
				"id": card.id,
				"name": card.display_name,
				"rarity": card.rarity,
				"cost": card.cost,
				"efficiency": card_efficiency(card),
				"severity": issue["severity"],
				"message": issue["message"],
			})

	return {
		"checked": cards.size(),
		"errors": errors,
		"warnings": warnings,
		"entries": entries,
		"by_rarity": by_rarity,
	}


## Trasforma il risultato di [method validate] in un report leggibile.
static func format_report(result: Dictionary, table: RarityTable) -> String:
	var lines: PackedStringArray = []
	var sep: String = "=".repeat(78)

	lines.append(sep)
	lines.append("  VALIDAZIONE CARTE  (%d carte controllate)" % result["checked"])
	lines.append(sep)
	lines.append("  Errori : %d" % result["errors"])
	lines.append("  Avvisi : %d" % result["warnings"])
	lines.append("")

	if table != null:
		lines.append(table.describe())
		lines.append("")

	lines.append(_distribution_lines(result, table))
	lines.append("")

	var entries: Array = result["entries"]
	if entries.is_empty():
		lines.append("  [ok] Nessun problema: tutte le carte rispettano il modello.")
		lines.append(sep)
		return "\n".join(lines)

	lines.append("  PROBLEMI PER CARTA")
	lines.append("-".repeat(78))
	for raw_entry: Variant in entries:
		var entry: Dictionary = raw_entry
		var tag: String = "[ERRORE]" if entry["severity"] == Severity.ERROR else "[avviso]"
		lines.append("  %s %s  (%s, %d mana, eff. %.2f)" % [
			tag, entry["name"], String(entry["id"]), entry["cost"], entry["efficiency"],
		])
		lines.append("        %s" % entry["message"])

	lines.append(sep)
	return "\n".join(lines)


## Confronta l'efficienza media osservata con quella attesa per ogni rarita'.
##
## E' la riga che dice se le carte [i]esprimono[/i] la progressione: se la
## colonna OSSERVATA non sale salendo di rarita', il modello non e' applicato.
static func _distribution_lines(result: Dictionary, table: RarityTable) -> String:
	var lines: PackedStringArray = []
	var stats: Dictionary = result.get("by_rarity", {})
	if stats.is_empty():
		return ""

	lines.append("  EFFICIENZA OSSERVATA vs ATTESA")
	lines.append("-".repeat(52))
	lines.append("  %-14s %7s %10s %12s" % ["RARITA'", "CARTE", "ATTESA", "OSSERVATA"])
	lines.append("-".repeat(52))

	for raw_rarity: Variant in stats:
		var rarity: CardTypes.Rarity = raw_rarity
		var entry: Dictionary = stats[rarity]
		var count: int = int(entry["count"])
		var observed: float = float(entry["total_efficiency"]) / maxf(float(count), 1.0)

		var expected: float = 0.0
		if table != null:
			var profile: RarityProfile = table.get_profile(rarity)
			if profile != null:
				expected = profile.power_per_mana

		lines.append("  %-14s %7d %10.1f %12.2f" % [
			CardTypes.rarity_name(rarity), count, expected, observed,
		])

	lines.append("-".repeat(52))
	return "\n".join(lines)


## Crea una voce di problema.
static func _issue(severity: Severity, message: String) -> Dictionary:
	return {"severity": severity, "message": message}


## True se l'id usa solo minuscolo, numeri e underscore.
static func _is_valid_id(text: String) -> bool:
	var regex: RegEx = RegEx.new()
	regex.compile("^[a-z0-9_]+$")
	return regex.search(text) != null
