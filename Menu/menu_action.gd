## Una voce del menu principale.
##
## [b]Perche' una Resource e non un enum?[/b] Cosi' puoi aggiungere, togliere
## e riordinare le voci dall'inspector senza toccare il codice, e le voci
## restano dati come tutto il resto del progetto.
##
## Le voci di default sono definite in [method MainMenu.build_default_actions]:
## se lasci l'array vuoto sull'oggetto [MainMenu], usa quelle.
class_name MenuAction extends Resource


## Identificativo della voce (es. [code]&"deck"[/code]).
## Usato dal codice e dal segnale [signal MainMenu.action_selected].
@export var id: StringName = &""

## Testo mostrato nel menu.
@export var label: String = "Voce"

## Riga di descrizione mostrata sotto il menu quando la voce e' selezionata.
@export_multiline var description: String = ""

## Se false la voce appare spenta e non e' selezionabile.
## Utile per voci che non hai ancora implementato.
@export var enabled: bool = true

## Se valorizzato, selezionare la voce carica questa scena.
##
## Lascialo vuoto per le voci che gestisci dal codice (come [code]quit[/code])
## o che non hai ancora implementato: in quel caso il menu mostra un messaggio.
@export_file("*.tscn") var scene_path: String = ""

## Se true il menu chiede conferma prima di eseguire questa voce.
## Consigliato per [code]quit[/code], per evitare di chiudere per sbaglio.
@export var needs_confirmation: bool = false

## Le sotto-voci. Se ce ne sono, scegliere questa voce non cambia schermata:
## fa comparire i loro pulsanti sotto la carta (es. Storia → Riprendi,
## Nuova Partita, Altre Opzioni). Ogni sotto-voce funziona come una voce
## normale: Scene Path, Enabled, Needs Confirmation...
@export var sub_actions: Array[MenuAction] = []

@export_group("Carta")

## L'immagine mostrata sulla carta di questa voce.
##
## [b]E' qui che metti la tua illustrazione.[/b] Se la lasci vuota, la carta
## mostra l'emblema ([member emblem]); se non c'e' nemmeno quello, la lettera
## iniziale del titolo.
@export var art: Texture2D

## Il simbolo disegnato nella carta, se non hai un'immagine tua.
##
## I nomi disponibili sono in [constant MenuCardArt.EMBLEMS]:
## [codeblock]
##   mask   una maschera che sorride
##   deck   un mazzo di carte
##   shop   una tenda da negozio
##   gear   un ingranaggio
##   sword  una spada
##   exit   una porta con la freccia
##   play   un triangolo: riprendi
##   plus   una croce: ricomincia
## [/codeblock]
##
## Lascialo vuoto e la carta mostra la lettera iniziale. Se scrivi un nome che
## non esiste, la carta usa la lettera e ti avvisa in console.
@export var emblem: StringName = &""

## Il colore della carta: bordo, fascia del titolo e ombra.
##
## Lascia l'alfa a 0 per far scegliere il colore in automatico dalla tavolozza
## di [MenuEntryCard].
@export var accent: Color = Color(0, 0, 0, 0)

## True se questa voce ha un colore proprio.
func has_custom_accent() -> bool:
	return accent.a > 0.0

## True se questa voce ha un'illustrazione.
func has_art() -> bool:
	return art != null

## True se questa voce apre dei pulsanti invece di fare qualcosa da sola.
func has_sub_actions() -> bool:
	return not sub_actions.is_empty()


## Costruisce una voce al volo (comodo da codice).
static func of(
	action_id: StringName,
	action_label: String,
	action_description: String = "",
	action_scene: String = "",
	action_emblem: StringName = &""
) -> MenuAction:
	var action: MenuAction = MenuAction.new()
	action.id = action_id
	action.label = action_label
	action.description = action_description
	action.scene_path = action_scene
	action.emblem = action_emblem
	return action


## True se questa voce porta a una scena.
func has_scene() -> bool:
	return not scene_path.is_empty()


func _to_string() -> String:
	return "<MenuAction %s '%s'>" % [id, label]
