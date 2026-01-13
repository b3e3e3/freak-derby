extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.hide()
	%ChatBar.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# TODO: on submitted signal
	print(%ChatBox.has_focus())
	if Input.is_action_just_pressed(&"ui_text_submit"):
		if not is_chat_open():
			open_chat()
		else:
			if is_message_typed():
				send_message_from_chatbox()
			elif not %ChatBox.has_focus():
				open_chat()
			else:
				close_chat()


func is_message_typed() -> bool:
	return not %ChatBox.text.strip_edges().is_empty()

func open_chat():
	self.show()
	%ChatBar.show()
	await get_tree().process_frame
	%ChatBox.grab_focus()
	scroll_to_bottom.call_deferred()

func close_chat():
	%ChatBar.hide()
	self.hide()

func is_chat_open() -> bool:
	return self.visible and %ChatBar.visible


func send_message_from_chatbox() -> bool:
	var message: String = %ChatBox.text.strip_edges()
	if not is_message_typed():
		return false

	send_message.rpc(message, multiplayer.get_unique_id())
	%ChatBox.text = ""
	await get_tree().process_frame
	%ChatBox.grab_focus()

	return true

func scroll_to_bottom():
	await %ChatContainer.sort_children
	$ScrollContainer.scroll_vertical = $ScrollContainer.get_v_scroll_bar().max_value

func create_label(player: PlayerInfo, message: String) -> RichTextLabel:
	var label := RichTextLabel.new()
	label.fit_content = true
	label.bbcode_enabled = true
	label.text = "[b][color=%s]%s[/color][/b]: %s" % [player.color.to_html(false), player.name, message]

	return label

@rpc("any_peer", "call_local")
func send_message(message: String, sender_id: int):
	var player: PlayerInfo = GameManager.players[sender_id]
	var label := create_label(player, message)

	%ChatContainer.add_child(label)
	%ChatContainer.move_child(label, %ChatContainer.get_child_count() - 1)

	open_chat()

	if multiplayer.get_unique_id() == sender_id:
		return

	# if not is_chat_open():
		# open_chat()
		# await get_tree().create_timer(3.0).timeout
		# # only hide after the timer if the chatbox has not been typed in
		# if %ChatBox.text.is_empty():
		# 	self.hide()


func _on_send_button_pressed() -> void:
	send_message_from_chatbox()

# func _unhandled_input(event: InputEvent) -> void:
# 	if is_chat_open():
# 		%ChatBox.grab_focus()


func _on_close_button_pressed() -> void:
	close_chat()


func _on_chat_box_text_submitted(new_text: String) -> void:
	pass # Replace with function body.
