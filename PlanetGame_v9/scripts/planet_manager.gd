extends Node3D

# --- Configuration ---
@export var spacing: float = 40.0
@export var transition_duration: float = 0.8
@export var base_radius: float = 5.0

# System Depth Config
@export var background_z: float = -80.0
@export var background_scale: float = 1.0
@export var background_alpha: float = 0.4

# --- State ---
var systems: Array[Node3D] = []
var planet_nodes: Array[Array] = [[], []]
var active_system_idx: int = 0
var selected_planet_idx: Array[int] = [2, 0]

var camera: Camera3D
var spaceship: Node3D
var energy_manager: Node

# Info Panel References
var info_panel: Control
var planet_name_label: Label
var planet_desc_label: Label

# --- Metadata ---
var main_system_data = [
	{"name": "Mercury", "type": 0, "color": Color(0.6, 0.6, 0.6), "accent": Color(0.3, 0.3, 0.3), "desc": "A scorched fragment of silver, dancing too close to the Sun's blinding iris. Its skin is a mosaic of craters, singing songs of ancient impacts under an eternal, breathless sky."},
	{"name": "Venus", "type": 0, "color": Color(0.9, 0.7, 0.4), "accent": Color(0.6, 0.4, 0.2), "desc": "Draped in veils of golden poison, she hides a crushed world beneath. A furnace of amber light where the wind is a heavy, choking sigh."},
	{"name": "Earth", "type": 2, "color": Color(0.1, 0.3, 0.6), "accent": Color(0.2, 0.5, 0.2), "desc": "A sapphire heartbeat in the void, wrapped in the soft breath of clouds. Here, every drop of water is a mirror to a billion dreams, protected by the fragile embrace of dawn."},
	{"name": "Mars", "type": 0, "color": Color(0.8, 0.3, 0.1), "accent": Color(0.4, 0.1, 0.05), "desc": "The rusted warrior of the void, dreaming in iron and ochre. Dust devils haunt the valleys like ghosts of oceans long since bled into the stars."},
	{"name": "Jupiter", "type": 1, "color": Color(0.8, 0.6, 0.4), "accent": Color(0.5, 0.3, 0.1), "desc": "A king of storms, wearing a crown of swirling marble. His great eye watches the deep, a vortex of thunder and gas that could swallow worlds whole."},
	{"name": "Saturn", "type": 1, "color": Color(0.9, 0.8, 0.6), "accent": Color(0.7, 0.5, 0.3), "has_rings": true, "desc": "The jeweler of the heavens, ringed in a halo of frozen tears and starlight. A pale gold phantom gliding through the quiet dark of the outer reaches."},
	{"name": "Uranus", "type": 1, "color": Color(0.6, 0.8, 0.9), "accent": Color(0.4, 0.6, 0.7), "desc": "A tilted emerald, leaning into the infinite cold. An ice-giant dreaming on its side, draped in the silent chill of the deep azure."},
	{"name": "Neptune", "type": 1, "color": Color(0.2, 0.4, 0.8), "accent": Color(0.1, 0.2, 0.5), "desc": "The cerulean whisperer, wreathed in the fiercest winds of the dark. A lonely titan of storm and shadow, where the sky is a permanent indigo twilight."},
]

var back_system_data = [
	{"name": "Alpha Centauri Bb", "type": 0, "color": Color(0.7, 0.5, 0.4), "accent": Color(0.4, 0.2, 0.1), "desc": "A fire-kissed pebble orbiting a sibling sun. Its ground is a glowing hearth, burning with the embers of a stellar family's eternal warmth."},
	{"name": "Rigel VII", "type": 1, "color": Color(0.3, 0.4, 0.9), "accent": Color(0.1, 0.2, 0.5), "desc": "A blue giant's breath frozen in time. A world of crystalline shadows and neon mists, reflecting the piercing light of the sapphire star above."},
	{"name": "Kepler-16b", "type": 1, "color": Color(0.8, 0.7, 0.3), "accent": Color(0.5, 0.4, 0.1), "desc": "The world of the binary dawn. Where every shadow has a twin, and the sky is painted twice by the setting of two radiant masters."},
	{"name": "Gliese 581c", "type": 2, "color": Color(0.2, 0.5, 0.3), "accent": Color(0.1, 0.3, 0.2), "desc": "The super-Earth at the edge of the dark. A garden of twilight where the sun is a low, crimson coal, and the tide never breaks its rhythm."},
	{"name": "Tatooine", "type": 0, "color": Color(0.9, 0.8, 0.6), "accent": Color(0.7, 0.5, 0.3), "desc": "A twin-sunned desert of endless gold. Sand that remembers the heat of a thousand ages, and a horizon that promises a journey to the end of time."},
]

func _ready():
	camera = get_viewport().get_camera_3d()
	spaceship = get_parent().get_node_or_null("Spaceship")
	
	# Connect to EnergyManager
	energy_manager = get_parent().get_node_or_null("EnergyManager")
	var ui = get_parent().get_node_or_null("SSVEP_UI")
	if ui:
		if energy_manager:
			energy_manager.planet_manager = self
			energy_manager.zap_label = ui.get_node_or_null("ZapLabel")
		
		# Info Panel References
		info_panel = ui.get_node_or_null("InfoPanel")
		if info_panel:
			planet_name_label = info_panel.get_node_or_null("VBoxContainer/NameLabel")
			planet_desc_label = info_panel.get_node_or_null("VBoxContainer/DescLabel")
	
	setup_systems()
	update_selection(true)

func setup_systems():
	var main_node = Node3D.new()
	main_node.name = "MainSystem"
	add_child(main_node)
	systems.append(main_node)
	create_planets_for_system(main_node, main_system_data, 0, 1.0)
	
	var back_node = Node3D.new()
	back_node.name = "BackSystem"
	back_node.position.z = background_z
	back_node.scale = Vector3.ONE * background_scale
	add_child(back_node)
	systems.append(back_node)
	create_planets_for_system(back_node, back_system_data, 1, 1.0)

func create_planets_for_system(parent: Node3D, data_list: Array, system_idx: int, size_mult: float):
	var shader = load("res://assets/master_planet.gdshader")
	
	for i in range(data_list.size()):
		var data = data_list[i]
		var p_root = Node3D.new()
		p_root.name = data["name"]
		p_root.position.x = i * spacing
		parent.add_child(p_root)
		
		var mesh_inst = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = base_radius * size_mult
		sphere.height = base_radius * 2.0 * size_mult
		mesh_inst.mesh = sphere
		
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
		label.name = "Label3D"
		label.text = data["name"]
		label.position.y = (base_radius * size_mult) + 12.0 # Higher for large font
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 360 # 3x bigger
		label.outline_size = 48 # Scaled outline
		label.outline_modulate = Color(0, 0, 0, 1)
		p_root.add_child(label)
		
		planet_nodes[system_idx].append(p_root)

func _input(event):
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_RIGHT:
			change_selection(1)
		elif event.keycode == KEY_LEFT:
			change_selection(-1)
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
	if not is_inside_tree(): return 
	
	var active_system = systems[active_system_idx]
	var planets = planet_nodes[active_system_idx]
	var selected_planet = planets[selected_planet_idx[active_system_idx]]
	
	var target_x = -selected_planet.position.x * active_system.scale.x
	var target_z = -active_system.position.z
	
	if instant:
		position.x = target_x
		position.z = target_z
	else:
		var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(self, "position:x", target_x, transition_duration)
		tw.tween_property(self, "position:z", target_z, transition_duration)
	
	# Background Fade
	for i in range(systems.size()):
		var sys = systems[i]
		var is_active = (i == active_system_idx)
		var target_a = 1.0 if is_active else background_alpha
		
		var tw_fade = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw_fade.tween_property(sys, "modulate:a", target_a, transition_duration)
		
		for p_node in planet_nodes[i]:
			var label = p_node.get_node_or_null("Label3D")
			if label:
				create_tween().tween_property(label, "modulate:a", target_a, transition_duration)
	
	# Info Panel Update
	if planet_name_label and planet_desc_label:
		var data_list = main_system_data if active_system_idx == 0 else back_system_data
		var data = data_list[selected_planet_idx[active_system_idx]]
		
		planet_name_label.text = data["name"]
		planet_desc_label.text = data["desc"]
		
		if info_panel:
			var tw_ui = info_panel.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			info_panel.modulate.a = 0.5
			tw_ui.tween_property(info_panel, "modulate:a", 1.0, 0.3)

	# Notify Spaceship and Energy Manager
	if spaceship and spaceship.has_method("set_target"):
		spaceship.set_target(selected_planet)
		
	if energy_manager and energy_manager.has_method("check_collection"):
		energy_manager.check_collection(selected_planet)
