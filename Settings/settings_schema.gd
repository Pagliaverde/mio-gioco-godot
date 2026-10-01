## Cosa mostra la schermata delle impostazioni, scheda per scheda.
##
## [b]La schermata si costruisce da qui:[/b] per mostrare un'impostazione nuova
## aggiungi una riga alla scheda giusta (o una scheda nuova). Il controllo
## (slider, casella, tendina...) lo crea [SettingsMenu] in base al [code]type[/code].
##
## Tipi disponibili:
## [br]- [code]slider[/code]: [code]min[/code], [code]max[/code], [code]step[/code],
##   [code]format[/code] ("percent", "times" o "number");
## [br]- [code]toggle[/code]: si/no;
## [br]- [code]choice[/code]: [code]options[/code] = coppie [valore, etichetta];
## [br]- [code]color[/code]: un colore;
## [br]- [code]palette[/code]: la tavolozza di 8 colori;
## [br]- [code]text[/code]: un testo ([code]placeholder[/code] facoltativo);
## [br]- [code]preset[/code]: la scelta del tema pronto;
## [br]- [code]bindings[/code]: i comandi da rimappare (uno per azione);
## [br]- [code]header[/code]: un titoletto, senza impostazione.
##
## Ogni riga puo' avere [code]hint[/code]: una frase di spiegazione sotto il nome.
class_name SettingsSchema extends RefCounted


static func tabs() -> Array:
	return [
		{
			"title": "Audio",
			"section": "audio",
			"items": [
				{"type": "slider", "key": "master", "label": "Volume generale", "min": 0.0, "max": 1.0, "step": 0.05, "format": "percent"},
				{"type": "slider", "key": "music", "label": "Musica", "min": 0.0, "max": 1.0, "step": 0.05, "format": "percent"},
				{"type": "slider", "key": "sfx", "label": "Effetti", "min": 0.0, "max": 1.0, "step": 0.05, "format": "percent"},
				{"type": "slider", "key": "ui", "label": "Interfaccia", "min": 0.0, "max": 1.0, "step": 0.05, "format": "percent", "hint": "Click, menu e notifiche."},
				{"type": "slider", "key": "voice", "label": "Voci", "min": 0.0, "max": 1.0, "step": 0.05, "format": "percent"},
				{"type": "toggle", "key": "mute", "label": "Silenzia tutto"},
				{"type": "toggle", "key": "mute_unfocused", "label": "Silenzia in secondo piano", "hint": "Quando passi a un'altra finestra."},
			],
		},
		{
			"title": "Video",
			"section": "video",
			"items": [
				{"type": "choice", "key": "window_mode", "label": "Finestra", "options": [
					["windowed", "Finestra"], ["maximized", "Finestra ingrandita"],
					["fullscreen", "Schermo intero"], ["exclusive", "Schermo intero esclusivo"],
				]},
				{"type": "toggle", "key": "vsync", "label": "Sincronizzazione verticale", "hint": "Evita lo strappo dell'immagine."},
				{"type": "choice", "key": "max_fps", "label": "Limite FPS", "options": [
					[0, "Nessuno"], [30, "30"], [60, "60"], [120, "120"], [144, "144"], [240, "240"],
				]},
				{"type": "slider", "key": "ui_scale", "label": "Scala interfaccia", "min": 0.75, "max": 1.5, "step": 0.05, "format": "times"},
				{"type": "toggle", "key": "show_fps", "label": "Mostra FPS"},
				{"type": "header", "label": "Immagine"},
				{"type": "slider", "key": "brightness", "label": "Luminosità", "min": 0.5, "max": 1.5, "step": 0.05, "format": "percent"},
				{"type": "slider", "key": "contrast", "label": "Contrasto", "min": 0.5, "max": 1.5, "step": 0.05, "format": "percent"},
				{"type": "slider", "key": "saturation", "label": "Saturazione", "min": 0.0, "max": 1.5, "step": 0.05, "format": "percent"},
			],
		},
		{
			"title": "Gioco",
			"section": "game",
			"items": [
				{"type": "choice", "key": "language", "label": "Lingua", "options": [["it", "Italiano"], ["en", "English"]]},
				{"type": "choice", "key": "difficulty", "label": "Difficoltà", "options": [["easy", "Facile"], ["normal", "Normale"], ["hard", "Difficile"]]},
				{"type": "slider", "key": "text_speed", "label": "Velocità del testo", "min": 0.5, "max": 3.0, "step": 0.25, "format": "times", "hint": "Quanto velocemente scorrono i dialoghi."},
				{"type": "slider", "key": "screen_shake", "label": "Tremolio dello schermo", "min": 0.0, "max": 1.0, "step": 0.1, "format": "percent"},
				{"type": "toggle", "key": "auto_save", "label": "Salvataggio automatico"},
				{"type": "toggle", "key": "show_tutorials", "label": "Mostra i suggerimenti"},
				{"type": "toggle", "key": "confirm_quit", "label": "Chiedi conferma prima di uscire"},
			],
		},
		{
			"title": "Comandi",
			"section": "controls",
			"items": [
				{"type": "bindings", "label": "Clicca un comando e premi il nuovo tasto. Esc annulla."},
			],
		},
		{
			"title": "Accessibilità",
			"section": "accessibility",
			"items": [
				{"type": "slider", "key": "text_scale", "label": "Dimensione del testo", "min": 0.8, "max": 1.6, "step": 0.1, "format": "times"},
				{"type": "toggle", "key": "high_contrast", "label": "Contrasto alto", "hint": "Bordi più spessi e testi più netti."},
				{"type": "toggle", "key": "reduce_motion", "label": "Riduci il movimento", "hint": "Animazioni quasi istantanee, niente tremolii."},
				{"type": "choice", "key": "colorblind", "label": "Filtro per daltonici", "options": [
					["none", "Nessuno"], ["protanopia", "Protanopia (rosso)"],
					["deuteranopia", "Deuteranopia (verde)"], ["tritanopia", "Tritanopia (blu)"],
				]},
				{"type": "toggle", "key": "subtitles", "label": "Sottotitoli"},
			],
		},
		{
			"title": "Tema",
			"section": "theme",
			"items": [
				{"type": "preset", "key": "preset", "label": "Tema", "hint": "Un gruppo di colori pronto. Cambiane uno e diventa \"Personalizzato\"."},
				{"type": "header", "label": "Colori"},
				{"type": "color", "key": "background", "label": "Sfondo"},
				{"type": "color", "key": "panel", "label": "Pannelli"},
				{"type": "color", "key": "text", "label": "Testo"},
				{"type": "color", "key": "accent", "label": "Accento"},
				{"type": "color", "key": "paper", "label": "Carta"},
				{"type": "color", "key": "ink", "label": "Inchiostro"},
				{"type": "palette", "key": "palette", "label": "Colori delle carte", "hint": "Uno per voce del menu, in ordine."},
				{"type": "header", "label": "Carte e menu"},
				{"type": "slider", "key": "card_wear", "label": "Usura delle carte", "min": 0.0, "max": 1.0, "step": 0.1, "format": "percent", "hint": "Crepe, macchie e angoli rovinati."},
				{"type": "slider", "key": "stack_jitter", "label": "Disordine del mazzo", "min": 0.0, "max": 8.0, "step": 0.5, "format": "number"},
				{"type": "slider", "key": "stack_depth", "label": "Carte visibili nel mazzo", "min": 0, "max": 8, "step": 1, "format": "number"},
				{"type": "toggle", "key": "ambient_cards", "label": "Carte che scorrono sullo sfondo"},
				{"type": "choice", "key": "font", "label": "Carattere", "options": [["jersey", "Jersey 10"], ["grapesoda", "GrapeSoda"], ["system", "Sistema"]]},
				{"type": "slider", "key": "animation_speed", "label": "Velocità animazioni", "min": 0.5, "max": 2.0, "step": 0.25, "format": "times"},
				{"type": "text", "key": "menu_title", "label": "Titolo del menu", "placeholder": "Nome del gioco"},
				{"type": "text", "key": "menu_subtitle", "label": "Sottotitolo del menu"},
			],
		},
	]
