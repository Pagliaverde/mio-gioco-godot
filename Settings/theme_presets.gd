## I temi pronti: ognuno e' un gruppo di colori per menu, carte e interfaccia.
##
## [b]Per aggiungere un tema[/b] basta aggiungere una voce a [method all]: compare
## da sola nella scheda Tema delle impostazioni. I campi che non scrivi
## prendono il valore del tema "pergamena".
class_name ThemePresets extends RefCounted


## Il nome del tema usato quando il giocatore modifica a mano un colore.
const CUSTOM := "custom"


## Tutti i temi, per nome.
static func all() -> Dictionary:
	return {
		"pergamena": {
			"label": "Pergamena",
			"background": Color(0.05, 0.06, 0.09),
			"panel": Color("1b1a20"),
			"text": Color(0.95, 0.95, 0.97),
			"accent": Color(0.98, 0.72, 0.30),
			"paper": Color("dccb9d"),
			"ink": Color("2b1d14"),
			"palette": [
				Color("c9772f"), Color("3f7fb0"), Color("5a8f3c"), Color("7d5296"),
				Color("b0463e"), Color("c9a336"), Color("3a8c86"), Color("b0607e"),
			],
		},
		"notte": {
			"label": "Notte",
			"background": Color("0a0f1e"),
			"panel": Color("141c30"),
			"text": Color("dfe7f5"),
			"accent": Color("7fb2ff"),
			"paper": Color("b7c0cf"),
			"ink": Color("121826"),
			"palette": [
				Color("4f6fb8"), Color("3a8fb7"), Color("5b5fa8"), Color("7b6bc4"),
				Color("3f9a9a"), Color("8a8fb8"), Color("2f6f9a"), Color("9a6fb0"),
			],
		},
		"foresta": {
			"label": "Foresta",
			"background": Color("0b1710"),
			"panel": Color("15241a"),
			"text": Color("e6efd9"),
			"accent": Color("9bd16b"),
			"paper": Color("d6cfa2"),
			"ink": Color("1f2a17"),
			"palette": [
				Color("5a8f3c"), Color("8a9a3a"), Color("3f7f5c"), Color("a37a3c"),
				Color("6f8f2f"), Color("4f7a6f"), Color("9a6a3a"), Color("7a9a5a"),
			],
		},
		"brace": {
			"label": "Brace",
			"background": Color("170a08"),
			"panel": Color("261410"),
			"text": Color("f6e3d3"),
			"accent": Color("ff8a3d"),
			"paper": Color("e0b98a"),
			"ink": Color("2e130b"),
			"palette": [
				Color("c4542a"), Color("d9822b"), Color("a8322f"), Color("c9a336"),
				Color("8f3a5a"), Color("b0602e"), Color("d26a4f"), Color("7a3a2a"),
			],
		},
		"contrasto": {
			"label": "Contrasto alto",
			"background": Color(0, 0, 0),
			"panel": Color("101010"),
			"text": Color(1, 1, 1),
			"accent": Color("ffd400"),
			"paper": Color("f2f2f2"),
			"ink": Color(0, 0, 0),
			"palette": [
				Color("ffd400"), Color("00b4ff"), Color("00d15e"), Color("c86bff"),
				Color("ff4d4d"), Color("ff9a00"), Color("00e0d0"), Color("ff6fb5"),
			],
		},
	}


## I valori di un tema. Se il nome non esiste restituisce "pergamena".
static func get_preset(preset_name: String) -> Dictionary:
	var presets: Dictionary = all()
	var base: Dictionary = presets["pergamena"]
	var chosen: Dictionary = presets.get(preset_name, base)
	var merged: Dictionary = base.duplicate(true)
	merged.merge(chosen.duplicate(true), true)
	return merged


## Coppie [nome, etichetta] per i menu a tendina.
static func choices() -> Array:
	var out: Array = []
	var presets: Dictionary = all()
	for key: String in presets:
		out.append([key, presets[key]["label"]])
	out.append([CUSTOM, "Personalizzato"])
	return out
