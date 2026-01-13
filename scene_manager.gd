extends Node3D

@export var player_scene: PackedScene

func spawn_player(info: PlayerInfo):
	var current_player := player_scene.instantiate() as Player
	current_player.name = str(info.peer_id)
	current_player.set_color(info.color)

	add_child(current_player)
	current_player.set_deferred(&"global_position", info.spawn_pos)

func _ready():
	for i in GameManager.players:
		var info := GameManager.players[i]
		spawn_player(info)
		print("Added player '%s' (%s) with color %s  |  is server? %s" % [info.name, str(i), str(info.color), str(multiplayer.is_server())])
