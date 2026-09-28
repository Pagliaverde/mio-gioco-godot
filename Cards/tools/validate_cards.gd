@tool
extends EditorScript

# Controlla tutte le carte contro il modello di potenza per rarita'.
#
# Come si usa:
#   1. Apri questo file nell'editor di Godot
#   2. Menu' File > Esegui (oppure Ctrl+Shift+X)
#   3. Guarda il pannello Output
#
# Non modifica nulla: e' un controllo di salute. Serve a scoprire se una carta
# mente sulla propria rarita' (fa troppo o troppo poco per la sua fascia),
# se due carte hanno lo stesso id, o se il costo esce dalla banda prevista.


func _run() -> void:
	var table: RarityTable = RarityTable.load_default()
	var database: CardDatabase = CardDatabase.load_default()
	var result: Dictionary = CardValidator.validate(database.cards, table)

	print("")
	print(CardValidator.format_report(result, table))
	print("")
