## Esporta l'illustrazione di ogni carta come PNG in [code]Cards/art/[/code].
##
## Le immagini le dipinge [CardArtPainter], una per carta, dal suo id. Una
## volta esportate le puoi ritoccare con qualsiasi editor di pixel art: il
## gioco usa il file se esiste, altrimenti dipinge al volo.
##
## [b]Come si usa:[/b]
## [codeblock]
## godot --headless --path . --script res://Cards/tools/generate_card_art.gd
## [/codeblock]
## Scrive anche [code]Cards/art/contact_sheet.png[/code], tutte le carte in
## una tavola sola, ingrandite, per guardarle in un colpo.
extends SceneTree


const OUT_DIR: String = "res://Cards/art/"
const ZOOM: int = 4
const COLUMNS: int = 6


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var cards: Array[CardData] = CardLibrary.build_all()
	var written: int = 0
	var images: Array[Image] = []

	for card: CardData in cards:
		var image: Image = CardArtPainter.paint_image(card)
		var path: String = "%s%s.png" % [OUT_DIR, card.id]
		var error: Error = image.save_png(path)
		if error != OK:
			push_error("Impossibile scrivere %s (errore %d)" % [path, error])
		else:
			written += 1
		images.append(image)

	_save_contact_sheet(images)
	print("[generate_card_art] Scritte %d illustrazioni in %s" % [written, OUT_DIR])
	quit(0)


## La tavola riassuntiva: tutte le carte una accanto all'altra.
func _save_contact_sheet(images: Array[Image]) -> void:
	var w: int = CardArtPainter.WIDTH * ZOOM
	var h: int = CardArtPainter.HEIGHT * ZOOM
	var gap: int = 8
	var rows: int = int(ceil(float(images.size()) / float(COLUMNS)))
	var sheet: Image = Image.create_empty(COLUMNS * (w + gap) + gap, rows * (h + gap) + gap, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("222"))

	for i: int in images.size():
		var scaled: Image = images[i].duplicate()
		scaled.resize(w, h, Image.INTERPOLATE_NEAREST)
		var x: int = gap + (i % COLUMNS) * (w + gap)
		var y: int = gap + (i / COLUMNS) * (h + gap)
		sheet.blit_rect(scaled, Rect2i(0, 0, w, h), Vector2i(x, y))

	sheet.save_png(OUT_DIR + "contact_sheet.png")
