extends Control
@onready var player_names_list: VBoxContainer = $PlayerNamesList
@onready var name_text_box: LineEdit = $VBoxContainer/Name
@onready var create_game_button: Button = $VBoxContainer/CreateGameButton
@onready var join_button: Button = $VBoxContainer/JoinButton
@onready var quit_button: Button = $HBoxContainer/QuitButton
@onready var start_button: Button = $HBoxContainer/StartButton
@onready var exit_lobby_button: Button = $ExitLobbyButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Lobby.player_connected.connect(_on_player_connected)
	Lobby.player_disconnected.connect(_on_player_disconnected)
	Lobby.server_disconnected.connect(_on_server_disconnected)


func _on_join_button_pressed() -> void:
	Lobby.player_info["name"] = name_text_box.text
	var error = Lobby.join_game()
	if error != 0:
		printerr(error_string(error))
	create_game_button.disabled = true
	exit_lobby_button.show()
	player_names_list.show()


func _on_create_game_button_pressed() -> void:
	Lobby.player_info["name"] = name_text_box.text
	var error = Lobby.create_game()
	if error != 0:
		printerr(error_string(error))
	join_button.disabled = true
	start_button.show()
	quit_button.show()
	player_names_list.show()
	


func _on_player_connected(peer_id: int, player_info: Dictionary) -> void:
	add_name_to_menu(peer_id, player_info["name"])


func _on_player_disconnected(peer_id: int) -> void:
	for child in player_names_list.get_children():
		if child is PlayerElement:
			if child.player_id == peer_id:
				child.queue_free()


func _on_server_disconnected() -> void:
	clear_player_list()
	player_names_list.hide()
	exit_lobby_button.hide()


func add_name_to_menu(p_id, p_name) -> void:
	var new_label = PlayerElement.new(p_id)
	player_names_list.add_child(new_label)
	new_label.text = p_name
	new_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


class PlayerElement:
	extends Label
	var player_id: int
	
	func _init(id: int) -> void:
		player_id = id


func _on_start_button_pressed() -> void:
	Lobby.load_game.rpc()


func _on_quit_button_pressed() -> void:
	Lobby.remove_multiplayer_peer()
	clear_player_list()
	start_button.hide()
	quit_button.hide()
	player_names_list.hide()
	

func clear_player_list() -> void:
	for child in player_names_list.get_children():
		if child is PlayerElement:
				child.queue_free()


func _on_exit_lobby_button_pressed() -> void:
	Lobby.remove_multiplayer_peer()
	clear_player_list()
	player_names_list.hide()
	exit_lobby_button.hide()
