extends Control



func _ready() -> void:
	Lobby.player_connected.connect(_on_player_connected)
	Lobby.player_disconnected.connect(_on_player_disconnected)
	Lobby.server_disconnected.connect(_on_server_disconnected)


func _on_join_button_pressed() -> void:
	if not %NameEdit.text.is_empty():
		Lobby.player_info["name"] = %NameEdit.text
	Lobby.join_game()
	%JoinButton.disabled = true
	%CreateButton.disabled = true
	%QuitButton.show()
	%PlayerNamesList.show()


func _on_create_game_button_pressed() -> void:
	if not %NameEdit.text.is_empty():
		Lobby.player_info["name"] = %NameEdit.text
	Lobby.create_game()
	%JoinButton.disabled = true
	%CreateButton.disabled = true
	%StartButton.show()
	%QuitButton.show()
	%PlayerNamesList.show()
	


func _on_player_connected(peer_id: int, player_info: Dictionary) -> void:
	add_name_to_menu(peer_id, player_info["name"])


func _on_player_disconnected(peer_id: int) -> void:
	%PlayerNamesList.get_children(
		).filter(func(node: Node) -> bool: return node is PlayerElement
		).filter(func(element: PlayerElement) -> bool: return element.player_id == peer_id
		)[0].queue_free()


func _on_server_disconnected() -> void:
	clear_player_list()
	%PlayerNamesList.hide()
	%QuitButton.hide()
	%JoinButton.disabled = false
	%CreateButton.disabled = false


func add_name_to_menu(p_id, p_name) -> void:
	var new_label = PlayerElement.new(p_id)
	%PlayerNamesList.add_child(new_label)
	new_label.text = p_name
	new_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _on_start_button_pressed() -> void:
	Lobby.load_game.rpc()


func _on_quit_button_pressed() -> void:
	Lobby.remove_multiplayer_peer()
	clear_player_list()
	%QuitButton.hide()
	%PlayerNamesList.hide()
	%JoinButton.disabled = false
	%CreateButton.disabled = false
	if %StartButton.visible:
		%StartButton.hide()


func clear_player_list() -> void:
	for child in %PlayerNamesList.get_children():
		if child is PlayerElement:
				child.queue_free()



class PlayerElement:
	extends Label
	
	
	
	var player_id: int
	
	
	
	func _init(id: int) -> void:
		player_id = id
