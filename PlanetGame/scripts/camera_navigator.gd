extends Camera3D

@export var move_speed: float = 3.0
@export var look_distance: float = 15.0
@export var rotation_sensitivity: float = 0.005

var is_transitioning: bool = false   # Flying toward a new planet
var focused_planet: Node3D = null    # The planet the camera is locked to

# Orbit angles (spherical coordinates around focused planet)
var orbit_angle_h: float = 0.0      # Horizontal (yaw) around planet
var orbit_angle_v: float = 0.3      # Vertical (pitch) — slight upward tilt

# 120-degree increment
const ANGLE_INCREMENT: float = TAU / 3.0  # 2π/3 ≈ 120 degrees

# Transition tracking
var transition_start: Vector3 = Vector3.ZERO
var transition_progress: float = 0.0

func _ready():
	# Earth is nested: Main/EarthOrbit/Earth
	var earth_path := "EarthOrbit/Earth"
	if get_parent().has_node(earth_path):
		_focus_planet(get_parent().get_node(earth_path))
	else:
		push_error("Camera: Could not find node at path: " + earth_path)

func _input(event):
	# --- MOUSE CLICKS ---
	if event is InputEventMouseButton and event.pressed:

		# Left-click: click a planet to fly to it, or click same planet to rotate 120° clockwise
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_left_click(event.position)

		# Right-click: rotate 120° counterclockwise around focused planet
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if focused_planet:
				orbit_angle_h -= ANGLE_INCREMENT
				_begin_rotation_transition()

	# --- KEYBOARD ARROW KEYS ---
	if event is InputEventKey and event.pressed and not event.echo:
		if focused_planet:
			if event.keycode == KEY_RIGHT:
				# Right arrow → rotate 120° clockwise
				orbit_angle_h += ANGLE_INCREMENT
				_begin_rotation_transition()

			elif event.keycode == KEY_LEFT:
				# Left arrow → rotate 120° counterclockwise
				orbit_angle_h -= ANGLE_INCREMENT
				_begin_rotation_transition()

	# --- MIDDLE MOUSE DRAG: fine orbit control ---
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE) and focused_planet:
		orbit_angle_h -= event.relative.x * rotation_sensitivity
		orbit_angle_v -= event.relative.y * rotation_sensitivity
		orbit_angle_v = clamp(orbit_angle_v, -PI / 2.1, PI / 2.1)

func _process(delta):
	if not focused_planet:
		return

	if is_transitioning:
		_handle_transition(delta)
	else:
		# Steady state: lock camera tightly to orbit position so it moves WITH the planet
		_track_planet(delta)

# ─────────────────────────────────────────────────────────────
# TRANSITION: smooth fly-in toward the orbit slot around the planet
# ─────────────────────────────────────────────────────────────
func _handle_transition(delta):
	transition_progress += delta * move_speed
	transition_progress = clamp(transition_progress, 0.0, 1.0)

	# Ease-in-out curve so motion feels cinematic
	var t = _ease_in_out(transition_progress)

	# The destination moves with the planet every frame
	var destination = _get_orbit_position()

	global_position = transition_start.lerp(destination, t)

	# Always look at the planet during transition
	_safe_look_at(focused_planet.global_position)

	# Transition ends when close enough
	if global_position.distance_to(destination) < 0.2:
		is_transitioning = false
		transition_progress = 0.0

# ─────────────────────────────────────────────────────────────
# TRACKING: snap camera tightly to orbit position every frame
# so it always moves WITH the orbiting planet
# ─────────────────────────────────────────────────────────────
func _track_planet(delta):
	var desired = _get_orbit_position()
	# High lerp factor keeps camera glued to the planet without any lag
	global_position = global_position.lerp(desired, clamp(delta * 20.0, 0.0, 1.0))
	_safe_look_at(focused_planet.global_position)

# ─────────────────────────────────────────────────────────────
# FOCUS: fly camera to a new planet
# ─────────────────────────────────────────────────────────────
func _focus_planet(planet: Node3D):
	if not is_instance_valid(planet):
		push_error("Camera: _focus_planet() received an invalid node!")
		return

	focused_planet = planet

	# Compute starting orbit angles from the current camera direction toward the planet
	var offset = global_position - planet.global_position
	if offset.length() > 0.001:
		orbit_angle_h = atan2(offset.x, offset.z)
		orbit_angle_v = clamp(
			atan2(offset.y, Vector2(offset.x, offset.z).length()),
			-PI / 2.1, PI / 2.1
		)
	else:
		orbit_angle_h = 0.0
		orbit_angle_v = 0.3

	_begin_rotation_transition()
	print("Camera focusing on: ", planet.name)

# ─────────────────────────────────────────────────────────────
# ROTATION: begin a smooth 120° rotation move
# ─────────────────────────────────────────────────────────────
func _begin_rotation_transition():
	if not focused_planet:
		return
	transition_start = global_position
	transition_progress = 0.0
	is_transitioning = true

# ─────────────────────────────────────────────────────────────
# RAYCAST LEFT-CLICK HANDLER
# ─────────────────────────────────────────────────────────────
func _handle_left_click(mouse_pos: Vector2):
	var from = project_ray_origin(mouse_pos)
	var to   = from + project_ray_normal(mouse_pos) * 2000.0
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space.intersect_ray(query)

	if result.is_empty():
		return

	var hit = result.collider
	if not (hit is StaticBody3D):
		return
	if hit.name == "Sun":
		return   # Don't focus the Sun

	if hit != focused_planet:
		# Different planet clicked → fly to it
		_focus_planet(hit)
	else:
		# Same planet clicked → rotate 120° clockwise
		orbit_angle_h += ANGLE_INCREMENT
		_begin_rotation_transition()

# ─────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────

# Returns the world-space position the camera should sit at
# for the current orbit angles around the focused planet.
func _get_orbit_position() -> Vector3:
	var x = cos(orbit_angle_v) * sin(orbit_angle_h)
	var y = sin(orbit_angle_v)
	var z = cos(orbit_angle_v) * cos(orbit_angle_h)
	return focused_planet.global_position + Vector3(x, y, z) * look_distance

# look_at() crashes when target equals origin; this guard prevents that.
func _safe_look_at(target: Vector3):
	if global_position.distance_to(target) > 0.01:
		look_at(target, Vector3.UP)

# Smooth cubic ease-in-out: starts slow, accelerates, then slows to a stop.
func _ease_in_out(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)
