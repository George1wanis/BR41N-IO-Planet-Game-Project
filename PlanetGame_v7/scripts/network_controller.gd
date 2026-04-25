extends Node

## BCI Network Receiver for Godot 4.4.1
## Listens for TCP commands (LEFT/RIGHT) from the Python SSVEP Classifier.

@export var port: int = 4242
var server := TCPServer.new()
var peer : StreamPeerTCP

# Path to the planet manager (assumed to be in /root/Main/PlanetContainer)
@onready var planet_manager = get_node("/root/Main/PlanetContainer")

func _ready():
	var err = server.listen(port)
	if err != OK:
		print("BCI Receiver: Failed to listen on port ", port)
	else:
		print("BCI Receiver: Listening on port ", port, "...")

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
			# Split by newlines in case multiple commands arrived in one packet
			var commands = raw_data.strip_edges().split("\n")
			for cmd in commands:
				if cmd.strip_edges() != "":
					_execute_command(cmd.strip_edges())

func _execute_command(cmd: String):
	print("BCI Command Received: ", cmd)
	
	if not planet_manager:
		print("BCI Error: PlanetContainer not found!")
		return
		
	if cmd == "LEFT":
		# Trigger the same logic as the Left Arrow key
		planet_manager.change_selection(-1)
	elif cmd == "RIGHT":
		# Trigger the same logic as the Right Arrow key
		planet_manager.change_selection(1)
	else:
		print("BCI Warning: Unknown command: ", cmd)
