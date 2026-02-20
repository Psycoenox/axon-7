extends Node3D

# --- STATS ---
@export var damage_per_second := 15.0
@export var explosion_damage := 60.0
@export var explosion_radius := 4.0
@export var max_charge_time := 2.0
@export var beam_range := 50.0
@export var max_beam_time := 5.0
@export var beam_min_width := 0.05
@export var beam_max_width := 0.2

# --- ESTADO ---
var is_charging := false
var charge_time := 0.0
var beam_timer := 0.0

# --- NODOS ---
@onready var raycast = $MuzzlePoint/RayCast3D
@onready var muzzle = $MuzzlePoint
@onready var impact_particles = $ImpactParticles
@onready var charge_particles = $ChargeParticles

var beam_mesh: MeshInstance3D
var camera: Camera3D

func _ready():
	beam_mesh = get_node("/root/TestArena/Player/Camera3D/BeamMesh")
	beam_mesh.visible = false
	
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.5
	cyl.bottom_radius = 0.5
	cyl.height = 1.0
	beam_mesh.mesh = cyl
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.0, 0.8, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.0, 0.8, 1.0)
	mat.emission_energy_multiplier = 3.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam_mesh.material_override = mat

func _physics_process(delta):
	# Obtener cámara aquí, no en _ready
	if camera == null:
		camera = get_viewport().get_camera_3d()
		return
	
	if Input.is_action_pressed("shoot"):
		if not is_charging:
			is_charging = true
			charge_particles.emitting = true
			beam_timer = 0.0
		
		beam_timer += delta
		charge_time = min(charge_time + delta, max_charge_time)
		update_beam(delta)
		
		if beam_timer >= max_beam_time:
			explode()
			stop_beam()
	elif is_charging:
		explode()
		stop_beam()

func update_beam(delta):
	beam_mesh.visible = true
	
	var dir = -camera.global_transform.basis.z
	var start = camera.global_position
	
	var distance: float
	if raycast.is_colliding():
		var end_point = raycast.get_collision_point()
		distance = start.distance_to(end_point)
		var hit = raycast.get_collider()
		if hit and hit.has_method("take_damage"):
			hit.take_damage(damage_per_second * delta)
		impact_particles.global_position = end_point
		impact_particles.emitting = true
	else:
		distance = beam_range
		impact_particles.emitting = false
	
	draw_beam(distance)

# Añade esta variable arriba para el efecto visual
var beam_phase := 0.0

func draw_beam(distance: float):
	var charge_ratio = charge_time / max_charge_time
	
	# 1. Grosor dinámico con un pequeño "pulso" (Efecto Marvel Rivals)
	beam_phase += get_process_delta_time() * 20.0
	var pulse = sin(beam_phase) * 0.02 # Pequeña vibración
	var thickness = lerp(beam_min_width, beam_max_width, charge_ratio) + pulse
	
	# 2. Configurar el Mesh (Cilindro)
	if beam_mesh.mesh is CylinderMesh:
		beam_mesh.mesh.height = distance
		beam_mesh.mesh.top_radius = thickness
		beam_mesh.mesh.bottom_radius = thickness

	# 3. POSICIONAMIENTO GLOBAL (Clave para que salga del arma)
	# En lugar de moverlo respecto a la cámara, lo movemos entre el Muzzle y el Objetivo
	var start_pos = muzzle.global_position
	var end_pos = start_pos + (-camera.global_transform.basis.z * distance)
	
	if raycast.is_colliding():
		end_pos = raycast.get_collision_point()

	# Colocamos el mesh en el centro del camino entre inicio y fin
	beam_mesh.global_position = start_pos.lerp(end_pos, 0.5)
	
	# Orientamos el cilindro para que mire al punto de impacto
	beam_mesh.look_at(end_pos, Vector3.UP)
	# Como el cilindro de Godot es vertical (Y), rotamos 90 grados en X para que apunte al frente
	beam_mesh.rotate_object_local(Vector3.RIGHT, PI/2.0)

	# 4. Brillo intenso
	var mat = beam_mesh.material_override as StandardMaterial3D
	if mat:
		mat.emission_energy_multiplier = lerp(5.0, 12.0, charge_ratio)

func explode():
	if not raycast.is_colliding():
		return
	
	var explosion_point = raycast.get_collision_point()
	var charge_ratio = charge_time / max_charge_time
	var final_damage = explosion_damage * charge_ratio
	
	var space = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = max(explosion_radius * charge_ratio, 0.1)
	query.shape = sphere
	query.transform.origin = explosion_point
	
	var hits = space.intersect_shape(query)
	for hit in hits:
		if hit.collider.has_method("take_damage"):
			hit.collider.take_damage(final_damage)

func stop_beam():
	is_charging = false
	charge_time = 0.0
	beam_mesh.visible = false
	impact_particles.emitting = false
	charge_particles.emitting = false
