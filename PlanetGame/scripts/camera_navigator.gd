extends Camera3D

@export var move_speed: float = 5.0
@export var look_distance: float = 10.0
@export var sensitivity: float = 0.005

var target_position: Vector3
var is_moving: bool = false
var target_node: Node3D = null

# Orbit variables
var orbit_angle_v: float = 0.0
var orbit_angle_h: float = 0.0
var is_orbiting: bool = false

func _ready():
	target_position = global_position

func _input(event):
	# Handle Clicking to travel
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_attempt_travel(event.position)
	
	# Handle Dragging to Orbit
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not is_moving:
		if target_node:
			orbit_angle_h -= event.relative.x * sensitivity
			orbit_angle_v -= event.relative.y * sensitivity
			orbit_angle_v = clamp(orbit_angle_v, -PI/2.1, PI/2.1) # Prevent flipping
			is_orbiting = true

func _process(delta):
	if is_moving:
		_handle_movement(delta)
	elif target_node:
		_handle_orbit(delta)

func _handle_movement(delta):
	# Smoothly move position
	global_position = global_position.lerp(target_position, delta * move_speed)
	
	# Smoothly rotate to look at the planet
	var target_transform = global_transform.looking_at(target_node.global_position)
	var current_q = global_transform.basis.get_rotation_quaternion()
	var target_q = target_transform.basis.get_rotation_quaternion()
	var next_q = current_q.slerp(target_q, delta * move_speed)
	global_basis = Basis(next_q)
	
	if global_position.distance_to(target_position) < 0.05:
		is_moving = false
		# Initialize orbit angles based on arrival position
		var offset = global_position - target_node.global_position
		orbit_angle_h = atan2(offset.x, offset.z)
		orbit_angle_v = atan2(offset.y, Vector2(offset.x, offset.z).length())

func _handle_orbit(delta):
	# Calculate new position based on angles
	var x = cos(orbit_angle_v) * sin(orbit_angle_h)
	var y = sin(orbit_angle_v)
	var z = cos(orbit_angle_v) * cos(orbit_angle_h)
	
	var offset = Vector3(x, y, z) * look_distance
	var desired_pos = target_node.global_position + offset
	
	# Smoothly update camera to orbit position
	global_position = global_position.lerp(desired_pos, delta * move_speed * 2.0)
	look_at(target_node.global_position)

func _attempt_travel(mouse_pos: Vector2):
	var ray_length = 1000
	var from = project_ray_origin(mouse_pos)
	var to = from + project_ray_normal(mouse_pos) * ray_length
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	
	var result = space_state.intersect_ray(query)
	
	if result:
		var hit_object = result.collider
		if hit_object is StaticBody3D and hit_object != target_node:
			target_node = hit_object
			var direction = (global_position - target_node.global_position).normalized()
			target_position = target_node.global_position + (direction * look_distance)
			is_moving = true
			is_orbiting = false
			print("Flying to: ", hit_object.name)
