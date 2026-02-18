extends CharacterBody3D

@export var mouse_sensitivity := 0.002

@export var ground_speed := 10.0
@export var air_speed := 8.0
@export var acceleration := 20.0
@export var air_acceleration := 6.0
@export var friction := 8.0
@export var jump_force := 6.5
@export var gravity := 20.0

var yaw := 0.0
var pitch := 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, -1.5, 1.5)

		rotation.y = yaw
		$Camera3D.rotation.x = pitch

func _physics_process(delta):

	# --- GRAVEDAD ---
	if not is_on_floor():
		velocity.y -= gravity * delta

	# --- INPUT DIRECCIONAL ---
	var input_dir = Input.get_vector("move_left", "move_right",
									 "move_forward", "move_back")

	var forward = transform.basis.z
	var right = transform.basis.x
	var wish_dir = (forward * input_dir.y + right * input_dir.x).normalized()

	if is_on_floor():
		ground_move(wish_dir, delta)
	else:
		air_move(wish_dir, delta)

	# --- SALTO (BUNNY HOP) ---
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force

	move_and_slide()

# =============================
# MOVIMIENTO TERRESTRE
# =============================

func ground_move(wish_dir, delta):

	# Fricción
	var speed = velocity.length()
	if speed > 0:
		var drop = speed * friction * delta
		velocity *= max(speed - drop, 0) / speed

	accelerate(wish_dir, ground_speed, acceleration, delta)

# =============================
# MOVIMIENTO AÉREO
# =============================

func air_move(wish_dir, delta):
	accelerate(wish_dir, air_speed, air_acceleration, delta)

# =============================
# ACELERACIÓN (QUAKE STYLE)
# =============================

func accelerate(wish_dir, max_speed, accel, delta):

	var current_speed = velocity.dot(wish_dir)
	var add_speed = max_speed - current_speed

	if add_speed <= 0:
		return

	var accel_speed = accel * delta * max_speed
	accel_speed = min(accel_speed, add_speed)

	velocity += wish_dir * accel_speed
