class_name MPManager extends Control

@export var compression_mode := ENetConnection.COMPRESS_RANGE_CODER

@export var server_address := "127.0.0.1"
@export var server_port := 3000
var peer: ENetMultiplayerPeer

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_server_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)

	$MarginContainer/VBoxContainer/StartGameButton.hide()


#region server + client
func _on_peer_connected(peer_id: int) -> void:
	print("Player Connected " + str(peer_id))

func _on_peer_disconnected(peer_id: int) -> void:
	print("Player Disconnected " + str(peer_id))
#endregion

#region clients
func _on_server_connected() -> void:
	print("Connected to server")
	send_player_info.rpc_id(1, %NameEntry.text, multiplayer.get_unique_id(), %ColorPicker.color)

func _on_connection_failed() -> void:
	print("Connection failed")
#endregion

@rpc("any_peer")
func send_player_info(player_name: String, peer_id: int, player_color: Color):
	if !GameManager.players.has(peer_id):
		GameManager.players[peer_id] = PlayerInfo.new(player_name, peer_id, player_color)

	if multiplayer.is_server():
		for i in GameManager.players:
			var info := GameManager.players[i]
			send_player_info.rpc(info.name, i, info.color)

@rpc("any_peer", "call_local")
func start_game():
	var scene = load("res://sandbox.tscn").instantiate()
	get_tree().root.add_child(scene)
	self.hide()


func _on_join_pressed() -> void:
	if peer: return

	$MarginContainer/VBoxContainer.hide()

	var addr_entry: String = %ServerAddressEntry.text.strip_edges()
	if not addr_entry.is_empty():
		server_address = addr_entry

	peer = ENetMultiplayerPeer.new()
	peer.create_client(server_address, server_port)
	peer.get_host().compress(compression_mode)

	multiplayer.multiplayer_peer = peer


func _on_start_game_pressed() -> void:
	start_game.rpc()


func _on_host_pressed() -> void:
	if peer: return
	$MarginContainer/VBoxContainer/JoinBar.hide()
	$MarginContainer/VBoxContainer/HostButton.hide()
	$MarginContainer/VBoxContainer/StartGameButton.show()

	peer = ENetMultiplayerPeer.new()
	var error := peer.create_server(server_port, 2)

	if error != OK:
		print("Cannot host: " + error_string(error))
		return

	peer.get_host().compress(compression_mode)

	multiplayer.multiplayer_peer = peer
	print("Waiting for players...")
	send_player_info(%NameEntry.text, multiplayer.get_unique_id(), %ColorPicker.color)
