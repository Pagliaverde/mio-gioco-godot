@tool
extends EditorScript

# Riscansiona le carte .tres e aggiorna l'indice (res://Cards/data/card_database.tres).
#
# Come si usa:
#   1. Apri questo file nell'editor di Godot
#   2. Menu' File > Esegui (oppure Ctrl+Shift+X)
#   3. Guarda il pannello Output
#
# Va eseguito dopo aver aggiunto, rinominato o spostato delle carte .tres.
# Non crea carte: quelle le crei dal dock "Carte" o con generate_cards.gd.


func _run() -> void:
	print("")
	print("=== AGGIORNAMENTO INDICE CARTE ===")
	print("")

	# 1. La tabella delle rarita' deve esistere per poter validare.
	var table: RarityTable = RarityTable.ensure_default_file()
	print("Tabella rarita': %s" % RarityTable.DEFAULT_PATH)

	# 2. Assicura che le sottocartelle per elemento esistano.
	CardDatabase.ensure_folders()

	# 3. Scandisce la cartella e ricostruisce l'indice.
	var database: CardDatabase = CardDatabase.new()
	var found: int = database.rebuild_from_folder()

	if found == 0:
		print("")
		print("Nessuna carta .tres trovata in %s." % CardDatabase.CARDS_ROOT)
		print("Esegui prima generate_cards.gd per materializzare le carte in codice.")
		print("")
		return

	# 4. Salva l'indice.
	var error: Error = database.save_default()
	if error != OK:
		push_error("Impossibile salvare l'indice (codice %d)." % error)
		return

	print("Indice aggiornato: %s" % CardDatabase.DEFAULT_PATH)
	print("")

	# 5. Report di cosa c'e' dentro e controllo del modello di potenza.
	print(database.describe())
	print("")
	print(CardValidator.format_report(database.validate(table), table))
	print("")

	# 6. Fa ricomparire subito i file nuovi nel pannello FileSystem.
	EditorInterface.get_resource_filesystem().scan()
