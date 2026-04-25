extends Node3D

@export_group("Orbital Mechanics")
@export var orbit_radius: float = 14.0
@export var orbit_speed: float = 1.2
@export var orbit_tilt_deg: float = 35.0
@export var transition_speed: float = 2.5

@export_group("Animation")
@export var bob_amplitude: float = 0.4
@export var bob_speed: float = 2.0

var target_planet: Node3D = null
var orbit_center: Vector3 = Vector3.ZERO
var angle: float = 0.0
var time_acc: float = 0.0

@onready var rocket_body: Node3D = $RocketBody

func _ready():
	orbit_center = global_position

func _process(delta):
	if not target_planet:
		return
		
	time_acc += delta
	angle += delta * orbit_speed
	
	# 1. Smoothly follow the selected planet's position
	orbit_center = orbit_center.lerp(target_planet.global_position, delta * transition_speed)
	
	# 2. Calculate Orbit Position using a tilted plane
	# We create a basis that is tilted
	var tilt_axis = Vector3.RIGHT # Tilt around X axis
	var tilt_basis = Basis(tilt_axis, deg_to_rad(orbit_tilt_deg))
	
	# Local orbit position on a flat XZ plane
	var local_pos = Vector3(cos(angle), 0, sin(angle)) * orbit_radius
	
	# Add subtle bobbing
	local_pos.y += sin(time_acc * bob_speed) * bob_amplitude
	
	# Transform local orbit position to tilted world space
	var world_offset = tilt_basis * local_pos
	global_position = orbit_center + world_offset
	
	# 3. Orientation Logic (The "Look Forward" fix)
	# Calculate the tangent (direction of motion)
	# Derivative of (cos(a), 0, sin(a)) is (-sin(a), 0, cos(a))
	var local_tangent = Vector3(-sin(angle), 0, cos(angle))
	var world_tangent = tilt_basis * local_tangent
	
	if world_tangent.length() > 0.001:
		var target_look = global_position + world_tangent
		# Godot's look_at points -Z at the target. 
		# Our rocket's nose in main.tscn should be aligned with its local -Z.
		look_at(target_look, Vector3.UP)

func set_target(planet: Node3D):
	target_planet = planet
