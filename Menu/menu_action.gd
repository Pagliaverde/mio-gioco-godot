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

@export_group("Carta")

## L'immagine mostrata sulla carta di questa voce.
##
## [b]E' qui che metti la tua illustrazione.[/b] Lascia vuoto e la carta
## mostrera' la lettera iniziale del titolo su un fondo del colore della voce:
## funziona lo stesso, serve solo a vedere come viene.
@export var art: Texture2D

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


## Costruisce una voce al volo (comodo da codice).
static func of(
	action_id: StringName,
	action_label: String,
	action_description: String = "",
	action_scene: String = ""
) -> MenuAction:
	var action: MenuAction = MenuAction.new()
	action.id = action_id
	action.label = action_label
	action.description = action_description
	action.scene_path = action_scene
	return action


## True se questa voce porta a una scena.
func has_scene() -> bool:
	return not scene_path.is_empty()


func _to_string() -> String:
	return "<MenuAction %s '%s'>" % [id, label]
