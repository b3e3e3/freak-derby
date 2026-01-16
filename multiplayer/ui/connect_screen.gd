extends Control

var time: int = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed():
	if visible:
		$ConnectingLabel.text = "Connecting..."
		time = 0

func _process(_delta: float) -> void:
	if not visible: return
	await get_tree().create_timer(1.0).timeout
	time += 1
	$ConnectingLabel.text = "Connecting... (%ss)" % str(time)
