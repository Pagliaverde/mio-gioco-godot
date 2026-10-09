## Un negozio: un bancone (la baracca del burattinaio, un banco del personale)
## con qualcuno dietro. Premendo [code]E[/code] davanti si apre il negozio
## ([ShopMenu]) con la merce di [method WorldData.shop].
class_name ShopStall extends Node2D


## Quale negozio (id di [method WorldData.shops]).
@export var shop_id: StringName = &"burattinaio"

## L'oggetto di scena del bancone (vedi [WorldProp]).
@export var stall_kind: String = "baracca"

## Chi c'e' dietro: vuoto (la baracca ha gia' il suo burattino), [code]npc[/code]
## o [code]mc[/code].
@export var keeper_look: String = ""

## Il colore di chi c'e' dietro.
@export var keeper_tint: Color = Color.WHITE

var interaction: Interactable


func _ready() -> void:
	y_sort_enabled = true
	if keeper_look != "":
		var keeper: WorldCharacter = WorldCharacter.new()
		keeper.look = keeper_look
		keeper.tint = keeper_tint
		keeper.position = Vector2(0, -22)
		keeper.name = "Negoziante"
		add_child(keeper)
		# Il negoziante non risponde da solo: si parla al bancone.
		keeper.interaction.enabled = false

	var stall: WorldProp = WorldProp.new()
	stall.kind = stall_kind
	stall.name = "Bancone"
	add_child(stall)

	var title: Label = Label.new()
	title.text = str(WorldData.shop(shop_id).get("title", "Negozio"))
	title.add_theme_font_size_override("font_size", 8)
	title.add_theme_color_override("font_color", Color(1, 0.9, 0.6))
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	title.add_theme_constant_override("outline_size", 3)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(160, 12)
	title.position = Vector2(-80, -112 if stall_kind == "baracca" else -70)
	title.z_index = 40
	add_child(title)

	var light: PointLight2D = WorldLights.make_light(Color(1.0, 0.8, 0.5), 0.8, 3.0)
	light.position = Vector2(0, -40)
	add_child(light)

	interaction = Interactable.create(self, 30.0, Vector2(0, 14))
	interaction.prompt = "Compra"
	interaction.interacted.connect(_on_interacted)


func _on_interacted(player: Node) -> void:
	if Overworld.instance != null:
		Overworld.instance.director.open_shop(self, player)
