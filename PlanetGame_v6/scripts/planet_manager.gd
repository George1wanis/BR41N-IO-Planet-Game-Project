extends Node3D

# --- Configuration ---
@export var spacing: float = 35.0
@export var transition_duration: float = 0.7
@export var base_radius: float = 4.5
@export var selection_scale: float = 1.3

# Zoom settings
@export var min_zoom: float = 25.0
@export var max_zoom: float = 100.0
@export var zoom_speed: float = 6.0
var current_zoom: float = 60.0

# --- State ---
var planets: Array[Node3D] = []
var selected_index: int = 2 
var camera: Camera3D
var spaceship: Node3D

# --- Planet Metadata ---
# Types: 0: Terrestrial, 1: Gas Giant, 2: Earth
var planet_data = [
	{"name": "Mercury", "type": 0, "color": Color(0.6, 0.6, 0.6), "accent": Color(0.3, 0.3, 0.3)},
	{"name": "Venus", "type": 0, "color": Color(0.9, 0.7, 0.4), "accent": Color(0.6, 0.4, 0.2)},
	{"name": "Earth", "type": 2, "color": Color(0.1, 0.3, 0.6), "accent": Color(0.2, 0.5, 0.2)},
	{"name": "Mars", "type": 0, "color": Color(0.8, 0.3, 0.1), "accent": Color(0.4, 0.1, 0.05)},
	{"name": "Jupiter", "type": 1, "color": Color(0.8, 0.6, 0.4), "accent": Color(0.5, 0.3, 0.1)},
	{"name": "Saturn", "type": 1, "color": Color(0.9, 0.8, 0.6), "accent": Color(0.7, 0.5, 0.3), "has_rings": true},
	{"name": "Uranus", "type": 1, "color": Color(0.6, 0.8, 0.9), "accent": Color(0.4, 0.6, 0.7)},
	{"name": "Neptune", "type": 1, "color": Color(0.2, 0.4, 0.8), "accent": Color(0.1, 0.2, 0.5)},
	{"name": "Pluto", "type": 0, "color": Color(0.7, 0.6, 0.5), "accent": Color(0.4, 0.3, 0.2)},
	
	# --- Expanded Planets (24 more) ---
	{"name": "Proxima b", "type": 0, "color": Color(0.5, 0.4, 0.3), "accent": Color(0.2, 0.1, 0.1)},
	{"name": "TRAPPIST-1e", "type": 2, "color": Color(0.2, 0.6, 0.3), "accent": Color(0.1, 0.4, 0.1)},
	{"name": "TRAPPIST-1f", "type": 0, "color": Color(0.3, 0.3, 0.6), "accent": Color(0.1, 0.1, 0.3)},
	{"name": "LHS 1140 b", "type": 0, "color": Color(0.5, 0.3, 0.2), "accent": Color(0.3, 0.1, 0.05)},
	{"name": "Kepler-186f", "type": 2, "color": Color(0.1, 0.5, 0.4), "accent": Color(0.05, 0.3, 0.2)},
	{"name": "Kepler-452b", "type": 2, "color": Color(0.4, 0.6, 0.2), "accent": Color(0.2, 0.4, 0.1)},
	{"name": "55 Cancri e", "type": 0, "color": Color(0.9, 0.3, 0.3), "accent": Color(0.5, 0.1, 0.1)},
	{"name": "Gliese 581g", "type": 0, "color": Color(0.4, 0.4, 0.5), "accent": Color(0.2, 0.2, 0.3)},
	{"name": "HD 209458 b", "type": 1, "color": Color(0.3, 0.5, 0.9), "accent": Color(0.1, 0.3, 0.6)},
	{"name": "WASP-12b", "type": 1, "color": Color(0.2, 0.2, 0.2), "accent": Color(0.8, 0.4, 0.1)},
	{"name": "HD 189733 b", "type": 1, "color": Color(0.1, 0.2, 0.9), "accent": Color(0.05, 0.1, 0.5)},
	{"name": "Kepler-10b", "type": 0, "color": Color(0.9, 0.6, 0.2), "accent": Color(0.6, 0.3, 0.1)},
	{"name": "Kepler-22b", "type": 2, "color": Color(0.2, 0.4, 0.9), "accent": Color(0.1, 0.2, 0.6)},
	{"name": "70 Virginis b", "type": 1, "color": Color(0.8, 0.8, 0.4), "accent": Color(0.5, 0.5, 0.2)},
	{"name": "COROT-7b", "type": 0, "color": Color(0.4, 0.2, 0.1), "accent": Color(0.8, 0.1, 0.1)},
	{"name": "Hat-P-7b", "type": 1, "color": Color(0.2, 0.6, 0.8), "accent": Color(0.1, 0.3, 0.5)},
	{"name": "Kepler-62f", "type": 2, "color": Color(0.3, 0.7, 0.8), "accent": Color(0.1, 0.4, 0.5)},
	{"name": "Kepler-62e", "type": 2, "color": Color(0.5, 0.8, 0.6), "accent": Color(0.2, 0.5, 0.3)},
	{"name": "Gliese 667 Cc", "type": 0, "color": Color(0.7, 0.4, 0.3), "accent": Color(0.4, 0.2, 0.1)},
	{"name": "Epsilon Eridani b", "type": 1, "color": Color(0.5, 0.5, 0.7), "accent": Color(0.3, 0.3, 0.5)},
	{"name": "PSR B1257+12 B", "type": 0, "color": Color(0.2, 0.2, 0.2), "accent": Color(0.4, 0.4, 0.4)},
	{"name": "K2-18b", "type": 2, "color": Color(0.2, 0.4, 0.7), "accent": Color(0.1, 0.2, 0.4)},
	{"name": "Tau Ceti e", "type": 0, "color": Color(0.6, 0.5, 0.4), "accent": Color(0.4, 0.3, 0.2)},
	{"name": "Luyten b", "type": 0, "color": Color(0.3, 0.6, 0.2), "accent": Color(0.1, 0.3, 0.1)}
]

func _ready():
	camera = get_viewport().get_camera_3d()
	spaceship = get_parent().get_node_or_null("Spaceship")
	
	create_planets()
	select_planet(selected_index, true)

func create_planets():
	var master_shader = load("res://assets/master_planet.gdshader")
	
	for i in range(planet_data.size()):
		var data = planet_data[i]
		
		var p_root = Node3D.new()
		p_root.name = data["name"]
		p_root.position.x = i * spacing
		add_child(p_root)
		
		var mesh_inst = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = base_radius
		sphere.height = base_radius * 2.0
		mesh_inst.mesh = sphere
		
		var mat = ShaderMaterial.new()
		mat.shader = master_shader
		mat.set_shader_parameter("planet_type", data["type"])
		mat.set_shader_parameter("base_color", data["color"])
		mat.set_shader_parameter("accent_color", data["accent"])
		mesh_inst.material_override = mat
		p_root.add_child(mesh_inst)
		
		if data.get("has_rings"):
			var rings = MeshInstance3D.new()
			var torus = TorusMesh.new()
			torus.inner_radius = base_radius * 1.5
			torus.outer_radius = base_radius * 2.5
			rings.mesh = torus
			rings.scale.y = 0.01
			rings.rotate_x(deg_to_rad(15))
			p_root.add_child(rings)
			
		var label = Label3D.new()
		label.text = data["name"]
		label.position.y = base_radius + 4.0
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 64
		label.outline_size = 14
		p_root.add_child(label)
		
		planets.append(p_root)

func _input(event):
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_RIGHT:
			select_planet(selected_index + 1)
		elif event.keycode == KEY_LEFT:
			select_planet(selected_index - 1)
			
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			current_zoom = clamp(current_zoom - zoom_speed, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			current_zoom = clamp(current_zoom + zoom_speed, min_zoom, max_zoom)

func _process(delta):
	if camera:
		camera.position.z = lerp(camera.position.z, current_zoom, delta * 5.0)

func select_planet(index: int, instant: bool = false):
	selected_index = (index + planets.size()) % planets.size()
	var target_planet = planets[selected_index]
	
	var target_x = -target_planet.position.x
	if instant:
		position.x = target_x
	else:
		var tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(self, "position:x", target_x, transition_duration)
		
	for i in range(planets.size()):
		var is_selected = (i == selected_index)
		var t_scale = Vector3.ONE * (selection_scale if is_selected else 1.0)
		
		if instant:
			planets[i].scale = t_scale
		else:
			var s_tw = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			s_tw.tween_property(planets[i], "scale", t_scale, transition_duration)
			
	if spaceship and spaceship.has_method("set_target"):
		spaceship.set_target(target_planet)
