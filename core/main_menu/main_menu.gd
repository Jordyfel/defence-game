extends Control



func _ready() -> void:
	Lobby.player_connected.connect(_on_player_connected)
	Lobby.player_disconnected.connect(_on_player_disconnected)
	Lobby.server_disconnected.connect(_on_server_disconnected)


func _on_join_button_pressed() -> void:
	Lobby.player_info["name"] = %NameEdit.text
	Lobby.join_game()
	%CreateButton.disabled = true
	%ExitLobbyButton.show()
	%PlayerNamesList.show()


func _on_create_game_button_pressed() -> void:
	Lobby.player_info["name"] = %NameEdit.text
	Lobby.create_game()
	%JoinButton.disabled = true
	%StartButton.show()
	%QuitButton.show()
	%PlayerNamesList.show()
	


func _on_player_connected(peer_id: int, player_info: Dictionary) -> void:
	add_name_to_menu(peer_id, player_info["name"])


func _on_player_disconnected(peer_id: int) -> void:
	for child in %PlayerNamesList.get_children():
		if child is PlayerElement:
			if child.player_id == peer_id:
				child.queue_free()


func _on_server_disconnected() -> void:
	clear_player_list()
	%PlayerNamesList.hide()
	%ExitLobbyButton.hide()


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
	%StartButton.hide()
	%QuitButton.hide()
	%PlayerNamesList.hide()


func clear_player_list() -> void:
	for child in %PlayerNamesList.get_children():
		if child is PlayerElement:
				child.queue_free()


func _on_exit_lobby_button_pressed() -> void:
	Lobby.remove_multiplayer_peer()
	clear_player_list()
	%PlayerNamesList.hide()
	%ExitLobbyButton.hide()



class PlayerElement:
	extends Label
	
	
	
	var player_id: int
	
	
	
	func _init(id: int) -> void:
		player_id = id
