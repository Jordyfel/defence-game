extends VBoxContainer



var server_packet_peer: ENetPacketPeer



func _ready() -> void:
	if not multiplayer.is_server():
		server_packet_peer = multiplayer.multiplayer_peer.get_peer(1)
	else:
		$PingLabel.hide()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("display_perf_metrics"):
		visible = !visible


func _physics_process(_delta: float) -> void:
	if not visible:
		return
	
	$FpsLabel.text = str(Performance.get_monitor(Performance.TIME_FPS)) + " fps"
	if not multiplayer.is_server():
		var ping: float = server_packet_peer.get_statistic(ENetPacketPeer.PEER_ROUND_TRIP_TIME)
		$PingLabel.text = str(ping) + " ms"
