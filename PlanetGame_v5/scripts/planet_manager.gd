extends Node3D

# --- Configuration ---
@export var spacing: float = 18.0
@export var transition_duration: float = 0.8
@export var base_radius: float = 3.5
@export var focus_scale: float = 1.15

# --- State ---
var planets: Array[Node3D] = []
var current_page: int = 0
const VISIBLE_COUNT = 4

# --- Planet Metadata ---
var planet_data = [
	{"name": "Mercury", "color": Color(0.65, 0.65, 0.65)},
	{"name": "Venus", "color": Color(0.95, 0.75, 0.4)},
	{"name": "Earth", "color": Color(0.1, 0.4, 0.8), "is_earth": true},
	{"name": "Mars", "color": Color(0.85, 0.35, 0.2)},
	{"name": "Jupiter", "color": Color(0.8, 0.65, 0.5)},
	{"name": "Saturn", "color": Color(0.9, 0.85, 0.6), "has_rings": true},
	{"name": "Uranus", "color": Color(0.65, 0.85, 0.95)},
	{"name": "Neptune", "color": Color(0.3, 0.45, 0.9)},
	{"name": "Pluto", "color": Color(0.75, 0.65, 0.55)},
	{"name": "Proxima Centauri b", "color": Color(0.55, 0.45, 0.35)},
	{"name": "TRAPPIST-1e", "color": Color(0.35, 0.55, 0.35)},
	{"name": "TRAPPIST-1f", "color": Color(0.35, 0.35, 0.55)},
	{"name": "LHS 1140 b", "color": Color(0.5, 0.35, 0.25)}
]

func _ready():
	# Clear existing children just in case
	for child in get_children():
		child.queue_free()
		
	create_planets()
	# Initial view update (instant)
	update_view(true)

func create_planets():
	var earth_shader = load("res://scripts/earth_shader.gdshader")
	
	for i in range(planet_data.size()):
		var data = planet_data[i]
		
		# Root node for the planet
		var planet_root = Node3D.new()
		planet_root.name = data["name"]
		planet_root.position.x = i * spacing
		add_child(planet_root)
		
		# Mesh Instance
		var mesh_instance = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		
		# Apply slight randomized variation (±15%) for differentiation
		var variation = 1.0 + (randf() * 0.3 - 0.15)
		sphere.radius = base_radius * variation
		sphere.height = base_radius * 2.0 * variation
		
		mesh_instance.mesh = sphere
		
		# Apply Material
		if data.get("is_earth"):
			var shader_mat = ShaderMaterial.new()
			shader_mat.shader = earth_shader
			mesh_instance.material_override = shader_mat
		else:
			var mat = StandardMaterial3D.new()
			mat.albedo_color = data["color"]
			mat.roughness = 0.6
			# Rim lighting for depth
			mat.rim_enabled = true
			mat.rim = 0.4
			mesh_instance.material_override = mat
		
		planet_root.add_child(mesh_instance)
		
		# Saturn's Rings
		if data.get("has_rings"):
			var rings = MeshInstance3D.new()
			var torus = TorusMesh.new()
			torus.inner_radius = sphere.radius * 1.6
			torus.outer_radius = sphere.radius * 2.6
			rings.mesh = torus
			rings.scale.y = 0.02
			rings.rotate_x(deg_to_rad(15)) # Slight tilt
			planet_root.add_child(rings)
		
		# Label Implementation
		var label = Label3D.new()
		label.text = data["name"]
		label.position.y = (base_radius * 1.3) + 2.0 # Positioned above planet
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 56
		label.outline_size = 14
		label.render_priority = 10 # Ensure label is drawn on top
		planet_root.add_child(label)
		
		planets.append(planet_root)

func _input(event):
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_D:
			change_page(1)
		elif event.keycode == KEY_A:
			change_page(-1)

func change_page(dir: int):
	var total_planets = planets.size()
	# Calculate total possible shifts (by 4 planets)
	var max_page = floor((total_planets - 1) / VISIBLE_COUNT)
	var next_page = clamp(current_page + dir, 0, int(max_page))
	
	if next_page != current_page:
		current_page = next_page
		update_view()

func update_view(instant: bool = false):
	# Movement Logic:
	# We center the camera on the window of 4 planets.
	# If spacing is 18, 4 planets span 18 * 3 = 54 units.
	# The center of this group is (page * 4 + 1.5) * spacing.
	var center_idx = (current_page * VISIBLE_COUNT) + 1.5
	var target_x = -center_idx * spacing
	
	if instant:
		position.x = target_x
	else:
		var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "position:x", target_x, transition_duration)
	
	# Focus Scaling Logic:
	# Scale up planets that are currently in the visible window
	for i in range(planets.size()):
		var is_visible = (i >= current_page * VISIBLE_COUNT and i < (current_page + 1) * VISIBLE_COUNT)
		var target_scale = Vector3.ONE * (focus_scale if is_visible else 1.0)
		
		if instant:
			planets[i].scale = target_scale
		else:
			var s_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			s_tween.tween_property(planets[i], "scale", target_scale, transition_duration)
