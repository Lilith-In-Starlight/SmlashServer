extends Node

remotesync var players := 0
remotesync var deaths := 0

var local_id := -1
var attacks := {}
var attacks_ever := 0
var player_data := {}

func _ready():
	var peer := NetworkedMultiplayerENet.new()
	peer.create_server(5555, 8)
	get_tree().network_peer = peer
	local_id = -1
	get_tree().connect("network_peer_connected", self, "on_entity_join")
	get_tree().connect("network_peer_disconnected", self, "on_entity_leave")
	
func _process(delta):
	if deaths >= players - 1 and players > 1:
		rset("deaths", 0)
		rpc("go_to_lobby")

func on_entity_join(id):
	print("Player joined with id: " + str(id))

func on_entity_leave(id):
	print("Player left with id: " + str(id))
	rset("players", players - 1)

remote func register_player(local):
	rset("players", players + 1)
	player_data[players] = local
	rpc("update_player_data", player_data)
	rpc_id(get_tree().get_rpc_sender_id(), "set_player_local_player", players)

remote func update_player_server_pos(pos, spd, id):
	player_data[id]["cspeed"] = spd
	player_data[id]["position"] = pos
	rpc_unreliable("update_player_data_from_server", player_data)
	
remote func player_attacks(who, damage, area):
	attacks[attacks_ever] = [who, damage, area, 0]
	attacks_ever += 1

remote func start_game():
	rpc("go_to_stage")

remote func damage_player(from, to, posfrom, posto, amount):
	player_data[to]["health"] += amount
	rpc_unreliable("player_was_attacked", from, to, posfrom, posto, amount)
	rpc_unreliable("update_player_data_ingame", player_data, to)

remote func update_player_health(id, new_health):
	player_data[id]["health"] = new_health
	rpc("update_player_data", player_data)
