## Il banco sulla mappa: avvicinati e premi [b]E[/b] per aprire il negozio.
##
## [b]E' lo stesso schema degli NPC.[/b] Un [Area2D] nel gruppo
## [code]interactable[/code] (layer 2) viene visto dall'[code]InteractionArea[/code]
## del personaggio (mask 2). Quando premi E, il personaggio cerca l'area piu'
## vicina e chiama [method interact] su di lei: qui sotto apriamo il negozio.
##
## [b]Non ha uno sprite[/b] di proposito: e' una zona invisibile da appoggiare
## sopra alla bottega della mappa. Spostala dove vuoi dal pannello Scena, come
## un NPC. Il riquadro "E" appare da solo quando il personaggio si avvicina.
##
## Vedi [code]Shop/README.md[/code].
class_name ShopStall extends Node2D


@onready var interaction_area: Area2D = $InteractionArea
@onready var interaction_prompt: Node2D = $InteractionArea/Prompt

## Il negozio aperto, se c'e'. Serve a non aprirne due sovrapposti.
var _screen: ShopScreen = null

## True mentre il personaggio e' dentro la zona.
var _player_nearby: bool = false


func _ready() -> void:
	interaction_prompt.visible = false
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)


## Chiamato dal personaggio quando preme E qui davanti.
func interact(_interactor: Node = null) -> void:
	if is_instance_valid(_screen):
		return

	_screen = ShopScreen.open_over(get_tree().current_scene)
	_screen.closed.connect(_on_shop_closed)

	# Il riquadro "E" sparisce finche' il negozio e' aperto: sotto c'e' lui.
	interaction_prompt.visible = false


func _on_shop_closed() -> void:
	_screen = null
	interaction_prompt.visible = _player_nearby


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = true
		interaction_prompt.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = false
		interaction_prompt.visible = false
