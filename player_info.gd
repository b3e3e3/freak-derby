class_name PlayerInfo extends Resource

@export var name: String
@export var peer_id: int
@export var color: Color
@export var spawn_pos: Vector3

func _init(player_name: String = "?", player_peer_id: int = 0, player_color: Color = Color.WHITE) -> void:
	self.name = player_name
	self.peer_id = player_peer_id
	self.color = player_color
	self.spawn_pos = Vector3(randf_range(-50, 50), 1, randf_range(-50, 50))
