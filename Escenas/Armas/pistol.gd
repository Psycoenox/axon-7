extends Node3D

@export var bullet_scene: PackedScene
@export var fire_rate := 0.2
var fire_timer := 0.0

# Recoil visual
@export var recoil_amount := 5.0
@export var recoil_speed := 10.0
var recoil_target := 0.0
var recoil_current := 0.0

# Referencia al Muzzle
@onready var muzzle = $PistolArmature/Skeleton3D/BoneAttachment3D/Marker3D
@onready var animation_player = $AnimationPlayer

func _process(delta):
	# Suavizado del recoil
	recoil_current = lerp(recoil_current, recoil_target, delta * recoil_speed)
	rotation_degrees.x = -recoil_current
	recoil_target = 0.0

func _physics_process(delta):
	if fire_timer > 0:
		fire_timer -= delta

	if Input.is_action_pressed("shoot") and fire_timer <= 0:
		shoot()
		fire_timer = fire_rate

func shoot():
	animation_player.play("PistolArmature|Fire")
	if not bullet_scene:
		return
	
	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	
	# Posición: desde el muzzle
	bullet.global_position = muzzle.global_position
	
	# Dirección: hacia donde mira la cámara (no el muzzle)
	var camera = get_viewport().get_camera_3d()
	bullet.global_transform.basis = camera.global_transform.basis
	
	recoil_target = recoil_amount
