extends Node

## BCI Network Receiver for Godot 4.4.1
## Listens for TCP commands (LEFT/RIGHT) from the Python SSVEP Classifier.

@export var port: int = 4242
var server := TCPServer.new()
var peer : StreamPeerTCP

# Use a relative path and safe initialization
@onready var planet_manager = get_parent().get_node_or_null("PlanetContainer")

func _ready():
	var err = server.listen(port)
	if err != OK:
		print("BCI Receiver: Failed to listen on port ", port)
	else:
		print("BCI Receiver: Listening on port ", port, "...")
	
	if not planet_manager:
		print("BCI Error: PlanetContainer not found during initialization!")

func _process(_delta):
	# Check for new connection
	if server.is_connection_available():
		peer = server.take_connection()
		print("BCI Receiver: Python Classifier Connected!")

	# Process incoming data from connected peer
	if peer and peer.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		var bytes = peer.get_available_bytes()
		if bytes > 0:
			var raw_data = peer.get_utf8_string(bytes)
			var commands = raw_data.strip_edges().split("\n")
			for cmd in commands:
				if cmd.strip_edges() != "":
					_execute_command(cmd.strip_edges())

func _execute_command(cmd: String):
	# Re-check manager in case of scene changes
	if not is_instance_valid(planet_manager):
		planet_manager = get_parent().get_node_or_null("PlanetContainer")
	
	if not planet_manager:
		return
		
	print("BCI Command Received: ", cmd)
	
	if cmd == "LEFT":
		planet_manager.change_selection(-1)
	elif cmd == "RIGHT":
		planet_manager.change_selection(1)
	elif cmd == "FORWARD":
		if planet_manager.has_method("cycle_system"):
			planet_manager.cycle_system(1)
		else:
			# Fallback if method name is different
			planet_manager.switch_system((planet_manager.active_system_idx + 1) % planet_manager.systems.size())
