extends Node

## Energy Manager for Planet Game
## Handles spawning EnergyFields on planets and global Zap count.

@export var spawn_interval: float = 5.0
@export var max_fields: int = 3
@export var energy_field_scene: PackedScene

var zap_count: int = 0
var active_fields: Dictionary = {} # Planet (Node3D) -> EnergyField (Node)
var _spawn_timer: float = 0.0

# References set by Main scene
var planet_manager: Node3D
var zap_label: Label

func _ready():
	_spawn_timer = spawn_interval * 0.5 

func _process(delta: float):
	_spawn_timer += delta
	if _spawn_timer >= spawn_interval:
		_spawn_timer = 0.0
		if active_fields.size() < max_fields:
			spawn_field()

func spawn_field():
	if not planet_manager: return
	
	# 1. Get currently active planet to exclude it
	var active_system = planet_manager.planet_nodes[planet_manager.active_system_idx]
	var current_planet = active_system[planet_manager.selected_planet_idx[planet_manager.active_system_idx]]
	
	# 2. Filter available planets (exclude current and already occupied)
	var available_planets = []
	for system_planets in planet_manager.planet_nodes:
		for p in system_planets:
			if p != current_planet and not active_fields.has(p):
				available_planets.append(p)
	
	if available_planets.is_empty(): return
	
	# 3. Pick random planet and determine type
	var target_planet = available_planets.pick_random()
	
	# 80% Green (1 zap), 20% Blue (2 zaps)
	var is_blue = randf() < 0.2
	var field_value = 2 if is_blue else 1
	var field_color = Color(0.2, 0.4, 1.0) if is_blue else Color(0.0, 1.0, 0.2)
	
	# 4. Instance and configure
	var field = energy_field_scene.instantiate()
	target_planet.add_child(field)
	
	# Set type properties on the field script
	if field.has_method("setup_field"):
		field.setup_field(field_value, field_color)
	
	active_fields[target_planet] = field
	
	field.collected.connect(_on_field_collected.bind(target_planet, field_value))
	field.expired.connect(_on_field_expired.bind(target_planet))

func _on_field_collected(planet, value):
	active_fields.erase(planet)
	zap_count += value
	_update_ui()

func _on_field_expired(planet):
	active_fields.erase(planet)

func _update_ui():
	if zap_label:
		zap_label.text = "⚡ " + str(zap_count)
		zap_label.pivot_offset = zap_label.size / 2
		
		var tw = zap_label.create_tween().set_parallel(true)
		tw.tween_property(zap_label, "scale", Vector3(1.5, 1.5, 1.5), 0.05)
		tw.tween_property(zap_label, "modulate", Color(1.5, 1.5, 2.0), 0.05) 
		
		var tw_back = zap_label.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw_back.tween_interval(0.05)
		tw_back.tween_property(zap_label, "scale", Vector3.ONE, 0.2)
		tw_back.tween_property(zap_label, "modulate", Color.WHITE, 0.2)

func check_collection(planet):
	if active_fields.has(planet):
		active_fields[planet].collect()
