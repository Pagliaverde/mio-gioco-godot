## Qualcosa da guardare da vicino: lo specchio rotto, il numero sul muro, il
## letto. Non ha uno sprite suo (di solito sta sopra un [WorldProp]): e' solo
## un'area di interazione con delle frasi.
##
## Nelle frasi [code]%d[/code] diventa il numero sul muro del camerino
## (quante volte hai cominciato).
class_name InspectPoint extends Node2D


## Le frasi, una per pagina.
@export_multiline var lines: PackedStringArray = []

## Il testo del fumetto.
@export var prompt: String = "Guarda"

## Se true, dopo aver guardato la vita torna piena (il letto del camerino).
@export var heals: bool = false

## Raggio dell'area.
@export var radius: float = 26.0

var interaction: Interactable


func _ready() -> void:
	interaction = Interactable.create(self, radius)
	interaction.prompt = prompt
	interaction.interacted.connect(func(player: Node) -> void:
		if Overworld.instance != null:
			Overworld.instance.director.inspect(self, player))
