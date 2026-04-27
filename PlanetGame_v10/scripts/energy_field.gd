extends Node3D

## Individual Energy Field Instance
## Handles its own animation, particles, and expiration.

signal collected
signal expired

@export var lifetime: float = 8.0
@onready var aura_mesh = $AuraMesh
@onready var particles = $SparkParticles

var _timer: float = 0.0
var _is_collected: bool = false
var value: int = 1
var color: Color = Color(0.0, 1.0, 0.2)

func _ready() -> void:
	# Small pop-in animation
	scale = Vector3.ZERO
	var tw = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector3.ONE * 1.3, 0.5)

## Configures the field type (called by Manager right after instantiating)
func setup_field(p_value: int, p_color: Color):
	self.value = p_value
	self.color = p_color
	
	# Important: Unique material so we don't change ALL active fields
	var mat = aura_mesh.material_override.duplicate()
	mat.set_shader_parameter("aura_color", p_color)
	aura_mesh.material_override = mat
	
	# Update particles color to match
	if particles and particles.process_material:
		particles.process_material = particles.process_material.duplicate()
		# Scale based on value - Blue fields (2 zaps) are slightly more energetic
		if p_value > 1:
			particles.amount = 40
			particles.process_material.emission_sphere_radius = 6.0
		
		# Set particle color ramp to match field color
		_update_particle_gradient(p_color)

func _update_particle_gradient(p_color: Color):
	var grad = Gradient.new()
	grad.set_color(0, Color.WHITE)
	grad.set_color(1, p_color)
	grad.add_point(0.5, p_color)
	
	var tex = GradientTexture1D.new()
	tex.gradient = grad
	particles.process_material.color_ramp = tex

func _process(delta: float) -> void:
	if _is_collected: return
	
	_timer += delta
	if _timer >= lifetime:
		expire()

func collect():
	if _is_collected: return
	_is_collected = true
	collected.emit()
	
	# "Zap" collection animation
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "scale", Vector3.ONE * 2.5, 0.3)
	tw.tween_property(aura_mesh.material_override, "shader_parameter/aura_color", Color.WHITE, 0.2)
	tw.set_parallel(false)
	tw.tween_property(self, "scale", Vector3.ZERO, 0.2)
	tw.tween_callback(queue_free)

func expire():
	_is_collected = true 
	expired.emit()
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector3.ZERO, 0.5)
	tw.tween_callback(queue_free)
