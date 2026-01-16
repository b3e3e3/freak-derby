extends Control

@onready var state_machine: MPManager = owner

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_host_button_pressed():
	state_machine.change_state($HostScreen)

func _on_start_game_button_pressed():
	state_machine.change_state($ConnectScreen)
