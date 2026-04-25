extends Node3D

# --- Configuration ---
@export var spacing: float = 40.0
@export var transition_duration: float = 0.8
@export var base_radius: float = 5.0

# System Depth Config
@export var background_z: float = -150.0
@export var background_scale: float = 0.4

# --- State ---
var systems: Array[Node3D] = []
var planet_nodes: Array[Array] = [[], []] # [ [system0_planets], [system1_planets] ]
var active_system_idx: int = 0
var selected_planet_idx: Array[int] = [2, 0] # Start on Earth in Main, 1st in Back

var camera: Camera3D
var spaceship: Node3D

# --- Metadata ---
var main_system_data = [
	{"name": "Mercury", "type": 0, "color": Color(0.6, 0.6, 0.6), "accent": Color(0.3, 0.3, 0.3)},
	{"name": "Venus", "type": 0, "color": Color(0.9, 0.7, 0.4), "accent": Color(0.6, 0.4, 0.2)},
	{"name": "Earth", "type": 2, "color": Color(0.1, 0.3, 0.6), "accent": Color(0.2, 0.5, 0.2)},
	{"name": "Mars", "type": 0, "color": Color(0.8, 0.3, 0.1), "accent": Color(0.4, 0.1, 0.05)},
	{"name": "Jupiter", "type": 1, "color": Color(0.8, 0.6, 0.4), "accent": Color(0.5, 0.3, 0.1)},
	{"name": "Saturn", "type": 1, "color": Color(0.9, 0.8, 0.6), "accent": Color(0.7, 0.5, 0.3), "has_rings": true},
	{"name": "Uranus", "type": 1, "color": Color(0.6, 0.8, 0.9), "accent": Color(0.4, 0.6, 0.7)},
	{"name": "Neptune", "type": 1, "color": Color(0.2, 0.4, 0.8), "accent": Color(0.1, 0.2, 0.5)},
]

var back_system_data = [
	{"name": "Alpha Centauri Bb", "type": 0, "color": Color(0.7, 0.5, 0.4), "accent": Color(0.4, 0.2, 0.1)},
	{"name": "Rigel VII", "type": 1, "color": Color(0.3, 0.4, 0.9), "accent": Color(0.1, 0.2, 0.5)},
	{"name": "Kepler-16b", "type": 1, "color": Color(0.8, 0.7, 0.3), "accent": Color(0.5, 0.4, 0.1)},
	{"name": "Gliese 581c", "type": 2, "color": Color(0.2, 0.5, 0.3), "accent": Color(0.1, 0.3, 0.2)},
	{"name": "Tatooine", "type": 0, "color": Color(0.9, 0.8, 0.6), "accent": Color(0.7, 0.5, 0.3)},
]

func _ready():
	camera = get_viewport().get_camera_3d()
	spaceship = get_parent().get_node_or_null("Spaceship")
	
	setup_systems()
	update_selection(true)

func setup_systems():
	# System 0: Main (Foreground)
	var main_node = Node3D.new()
	main_node.name = "MainSystem"
	add_child(main_node)
	systems.append(main_node)
	create_planets_for_system(main_node, main_system_data, 0, 1.0)
	
	# System 1: Background
	var back_node = Node3D.new()
	back_node.name = "BackSystem"
	back_node.position.z = background_z
	back_node.scale = Vector3.ONE * background_scale
	add_child(back_node)
	systems.append(back_node)
	create_planets_for_system(back_node, back_system_data, 1, 1.0) # Scale is handled by parent

func create_planets_for_system(parent: Node3D, data_list: Array, system_idx: int, size_mult: float):
	var shader = load("res://assets/master_planet.gdshader")
	
	for i in range(data_list.size()):
		var data = data_list[i]
		var p_root = Node3D.new()
		p_root.name = data["name"]
		p_root.position.x = i * spacing
		parent.add_child(p_root)
		
		# Mesh
		var mesh_inst = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = base_radius * size_mult
		sphere.height = base_radius * 2.0 * size_mult
		mesh_inst.mesh = sphere
		
		# Realism Shader Material
		var mat = ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("planet_type", data["type"])
		mat.set_shader_parameter("base_color", data["color"])
		mat.set_shader_parameter("accent_color", data["accent"])
		mesh_inst.material_override = mat
		p_root.add_child(mesh_inst)
		
		if data.get("has_rings"):
			var rings = MeshInstance3D.new()
			var torus = TorusMesh.new()
			torus.inner_radius = sphere.radius * 1.5
			torus.outer_radius = sphere.radius * 2.5
			rings.mesh = torus
			rings.scale.y = 0.01
			p_root.add_child(rings)
			
		var label = Label3D.new()
		label.text = data["name"]
		label.position.y = (base_radius * size_mult) + 5.0
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 72
		p_root.add_child(label)
		
		planet_nodes[system_idx].append(p_root)

func _input(event):
	if event is InputEventKey and event.pressed and not event.is_echo():
		# Horizontal Navigation
		if event.keycode == KEY_RIGHT:
			change_selection(1)
		elif event.keycode == KEY_LEFT:
			change_selection(-1)
		
		# Vertical Navigation (System Switch)
		elif event.keycode == KEY_UP:
			switch_system(1)
		elif event.keycode == KEY_DOWN:
			switch_system(0)

func change_selection(dir: int):
	var planets = planet_nodes[active_system_idx]
	selected_planet_idx[active_system_idx] = (selected_planet_idx[active_system_idx] + dir + planets.size()) % planets.size()
	update_selection()

func switch_system(idx: int):
	if idx != active_system_idx:
		active_system_idx = idx
		update_selection()

func update_selection(instant: bool = false):
	var active_system = systems[active_system_idx]
	var planets = planet_nodes[active_system_idx]
	var selected_planet = planets[selected_planet_idx[active_system_idx]]
	
	# 1. Smoothly center the active system and the selected planet
	# We move the *entire* container (self) so that the selected planet is at X=0
	# and the active system is at Z=0 relative to camera
	var target_x = -selected_planet.position.x * active_system.scale.x
	var target_z = -active_system.position.z
	
	if instant:
		position.x = target_x
		position.z = target_z
	else:
		var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(self, "position:x", target_x, transition_duration)
		tw.tween_property(self, "position:z", target_z, transition_duration)
	
	# 2. Update Background Fade (Optional cinematic touch)
	for i in range(systems.size()):
		var is_active = (i == active_system_idx)
		var target_alpha = 1.0 if is_active else 0.4
		# We could use depth fog or transparency here
		
	# 3. Notify Spaceship
	if spaceship and spaceship.has_method("set_target"):
		spaceship.set_target(selected_planet)
