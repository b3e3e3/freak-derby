class_name MPManager extends Control

@export var compression_mode := ENetConnection.COMPRESS_RANGE_CODER

@export var server_address := "127.0.0.1"
@export var server_port := 3000
var peer: ENetMultiplayerPeer

@onready var current_state: Control = $StartScreen


var player_list: Dictionary[int, Control] = {}


func change_state(new_state: Control):
	current_state.hide()
	current_state = new_state
	current_state.show()

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_server_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)

	change_state(current_state)
	# $MarginContainer/VBoxContainer/StartGameButton.hide()


#region server + client
func _on_peer_connected(peer_id: int) -> void:
	print("Player Connected " + str(peer_id))

func _on_peer_disconnected(peer_id: int) -> void:
	print("Player Disconnected " + str(peer_id))
#endregion

@rpc("any_peer", "call_local")
func create_or_update_player_label(peer_id: int, player_name: String, player_color: Color):
	var label: Control

	if not player_list.has(peer_id):
		label = preload("res://player_label.tscn").instantiate()
		player_list[peer_id] = label
		%PlayerListContainer.add_child(label)
	else:
		label = player_list[peer_id]

	label.set_info(player_name, player_color)

#region clients
func _on_server_connected() -> void:
	print("Connected to server")
	var peer_id := multiplayer.get_unique_id()
	send_player_info.rpc_id(1, "", peer_id, Color.WHITE)
	change_state($LobbyScreen)

func _on_connection_failed() -> void:
	print("Connection failed")
	$ErrorDialog.show()
	$ErrorDialog.title = server_address

# func _on_error_dialog_confirmed():
# 	change_state($LobbyScreen)

# func _on_error_dialog_canceled():
# 	change_state($LobbyScreen)
#endregion

@rpc("any_peer", "call_local")
func send_player_info(player_name: String, peer_id: int, player_color: Color):
	if not multiplayer.is_server(): return

	if player_name.is_empty():
		player_name = "Player" + str(peer_id)

	# if !GameManager.players.has(peer_id):
	GameManager.players[peer_id] = PlayerInfo.new(player_name, peer_id, player_color)

	if multiplayer.is_server():
		for i in GameManager.players:
			var info := GameManager.players[i]
			broadcast_player_info.rpc(info.name, i, info.color)

@rpc("authority", "call_local")
func broadcast_player_info(player_name: String, peer_id: int, player_color: Color):
	create_or_update_player_label(peer_id, player_name, player_color)

@rpc("any_peer", "call_local")
func start_game():
	var scene = load("res://sandbox.tscn").instantiate()
	get_tree().root.add_child(scene)
	self.hide()


func _on_join_button_pressed() -> void:
	$JoinDialog.show()

func _on_join_dialog_confirmed() -> void:
	if not multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		return

	change_state($ConnectScreen)

	var addr_entry: String = %ServerAddressEntry.text.strip_edges()
	if not addr_entry.is_empty():
		server_address = addr_entry

	peer = ENetMultiplayerPeer.new()

	# TODO: for some reason, we can join localhost without a server running
	var error := peer.create_client(server_address, server_port)
	if error != OK:
		$ErrorDialog.show()
		change_state($StartScreen)

	peer.get_host().compress(compression_mode)
	multiplayer.multiplayer_peer = peer

	change_state($LobbyScreen)


func _on_start_game_pressed() -> void:
	start_game.rpc()


func _on_host_button_pressed() -> void:
	if not multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		return

	change_state($LobbyScreen)

	peer = ENetMultiplayerPeer.new()
	var error := peer.create_server(server_port, 2)

	if error != OK:
		print("Cannot host: " + error_string(error))
		return

	peer.get_host().compress(compression_mode)

	multiplayer.multiplayer_peer = peer
	print("Waiting for players...")
	send_player_info.rpc(%NameEntry.text, multiplayer.get_unique_id(), %ColorPicker.color)


func _on_name_entry_text_changed(new_text: String) -> void:
	send_player_info.rpc(new_text, multiplayer.get_unique_id(), %ColorPicker.color)


func _on_color_picker_color_changed(color: Color) -> void:
	send_player_info.rpc(%NameEntry.text, multiplayer.get_unique_id(), color)
