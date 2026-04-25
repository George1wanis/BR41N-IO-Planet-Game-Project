extends Node3D

## Orbital parameters
@export var orbital_radius: float = 20.0  # Distance from sun
@export var orbital_period: float = 10.0  # Time in seconds to complete one orbit
@export var axial_rotation_speed: float = 0.5  # Speed of planet rotation on its axis

var current_orbital_angle: float = 0.0
var planet: Node3D = null

## Per-instance toggle — set by camera_navigator via toggle_all_orbits()
var is_orbiting: bool = true

func _ready():
	if get_child_count() > 0:
		planet = get_child(0)
	else:
		push_error("Planet orbit node has no child planet!")

func _process(delta):
	if not is_orbiting:
		return

	# Update orbital angle
	current_orbital_angle += (delta / orbital_period) * TAU

	# Keep angle within 0-TAU range
	if current_orbital_angle > TAU:
		current_orbital_angle -= TAU

	# Position planet in orbit
	var orbital_x = cos(current_orbital_angle) * orbital_radius
	var orbital_z = sin(current_orbital_angle) * orbital_radius
	position = Vector3(orbital_x, 0, orbital_z)

func get_orbital_angle() -> float:
	return current_orbital_angle

func set_orbital_angle(angle: float) -> void:
	current_orbital_angle = angle
