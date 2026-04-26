extends GPUParticles3D

## Space Dust Emitter for Godot 4.4.1
## Provides subtle 3D depth and parallax movement.

func _ready() -> void:
	# 1. Mesh and Material Setup
	var point_mesh = PointMesh.new()
	var draw_mat = StandardMaterial3D.new()
	
	draw_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	draw_mat.billboard_mode = StandardMaterial3D.BILLBOARD_ENABLED
	draw_mat.albedo_color = Color(0.9, 0.9, 1.0, 0.15) # Very subtle gray-blue
	draw_mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	
	self.draw_pass_1 = point_mesh
	self.material_override = draw_mat

	# 2. Particle Process Material
	var p_mat = ParticleProcessMaterial.new()
	
	# Large volume centered around camera area
	p_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	p_mat.emission_box_extents = Vector3(200, 100, 200)
	
	p_mat.gravity = Vector3.ZERO
	p_mat.initial_velocity_min = 0.05
	p_mat.initial_velocity_max = 0.2
	p_mat.direction = Vector3(1, 0.2, 0.5).normalized()
	p_mat.spread = 45.0
	
	# Scale variation for depth perception
	p_mat.scale_min = 0.1
	p_mat.scale_max = 0.3
	
	# Fade in/out to prevent popping
	p_mat.color_ramp = _create_fade_gradient()
	
	self.process_material = p_mat
	self.amount = 400
	self.lifetime = 30.0
	self.preprocess = 15.0 # Pre-fill the scene

func _create_fade_gradient() -> GradientTexture1D:
	var grad = Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 0))
	grad.set_color(1, Color(1, 1, 1, 0.15))
	grad.add_point(0.2, Color(1, 1, 1, 0.15))
	grad.add_point(0.8, Color(1, 1, 1, 0.15))
	grad.add_point(1.0, Color(1, 1, 1, 0))
	
	var tex = GradientTexture1D.new()
	tex.gradient = grad
	return tex
