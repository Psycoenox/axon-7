extends Node3D

@onready var animation_player = $AnimationPlayer
@onready var ray = $RayCast3D

var fire_rate := 0.25  # Tiempo mínimo entre disparos en segundos
var last_shot_time := 0.0

func _physics_process(delta):
	if Input.is_action_just_pressed("shoot"):
		var time_now = Time.get_ticks_msec() / 1000.0
		if time_now - last_shot_time >= fire_rate:
			shoot()
			last_shot_time = time_now

func shoot():
	animation_player.play("PistolArmature|Fire")

	if not ray.is_colliding():
		return

	var hit = ray.get_collider()
	if hit.has_method("take_damage"):
		hit.take_damage(10)
