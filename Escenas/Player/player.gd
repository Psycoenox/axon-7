extends CharacterBody3D




# NUEVAS VARIABLES
@export var dash_force := 18.0
@export var dash_duration := 0.15
@export var dash_cooldown := 0.8
@export var dash_friction_lock := 0.2   # tiempo sin fricción tras dash

var dash_timer := 0.0
var dash_cd_timer := 0.0
var dash_lock_timer := 0.0
var is_dashing := false
# NUEVAS VARIABLES


@export var mouse_sensitivity := 0.002

@export var ground_speed := 10.0
@export var air_speed := 10.0
@export var acceleration := 14.0
@export var air_acceleration := 2.0
@export var friction := 6.0
@export var jump_force := 6.5
@export var gravity := 20.0
@export var air_control := 0.3


var yaw := 0.0
var pitch := 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		# tu código del ratón aquí
		yaw -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, -1.5, 1.5)
		rotation.y = yaw
		$Camera3D.rotation.x = pitch
		return  # ← falta este return, sin él sigue ejecutando aba
func _physics_process(delta):
# --- DASH TIMERS ---
	if dash_timer > 0:
		dash_timer -= delta
	if dash_timer <= 0:
		is_dashing = false

	if dash_cd_timer > 0:
		dash_cd_timer -= delta

	if dash_lock_timer > 0:
		dash_lock_timer -= delta
	# --- GRAVEDAD ---
	if not is_on_floor():
		velocity.y -= gravity * delta

	# --- INPUT ---
	var input_dir = Input.get_vector("move_left", "move_right",
									 "move_forward", "move_back")

	var forward = transform.basis.z # SE TIENE QUE QUEDAR ASI PORQUE SI NO VA INVERTIDO
	var right = transform.basis.x
	var wish_dir = (forward * input_dir.y + right * input_dir.x).normalized()

	# --- DASH ---
	if Input.is_action_just_pressed("dash") and dash_cd_timer <= 0:
		start_dash(wish_dir)

	# --- MOVIMIENTO ---
	if is_on_floor():
		ground_move(wish_dir, delta)
	else:
		air_move(wish_dir, delta)

	# --- SALTO ---
	if Input.is_action_pressed("jump") and is_on_floor():
		velocity.y = jump_force

	move_and_slide()

		
func start_dash(wish_dir):

	if wish_dir == Vector3.ZERO:
		wish_dir = -transform.basis.z

	var horizontal = Vector3(wish_dir.x, 0, wish_dir.z).normalized()

	var force = dash_force
	
	if not is_on_floor():
		force *= 0.7  # dash aéreo más débil

	# --- CONTROL DE VELOCIDAD (ANTI BHOP BREAK) ---
	var horizontal_velocity = Vector3(velocity.x, 0, velocity.z)
	var dash_projection = horizontal_velocity.dot(horizontal)

	if dash_projection < ground_speed * 1.5:
		velocity += horizontal * force
	else:
		velocity += horizontal * (force * 0.2)

	is_dashing = true
	dash_timer = dash_duration
	dash_cd_timer = dash_cooldown
	dash_lock_timer = dash_friction_lock


# =============================
# GROUND
# =============================

func ground_move(wish_dir, delta):

	apply_friction(delta)
	accelerate(wish_dir, ground_speed, acceleration, delta)

# =============================
# AIR
# =============================

func air_move(wish_dir, delta):

	accelerate(wish_dir, air_speed, air_acceleration, delta)
	air_control_func(wish_dir, delta)

# =============================
# FRICTION SOLO HORIZONTAL
# =============================

func apply_friction(delta):
	if dash_lock_timer > 0:
		return

	var horizontal = Vector3(velocity.x, 0, velocity.z)
	var speed = horizontal.length()

	if speed < 0.1:
		velocity.x = 0.0  # ← corta a cero en vez de return
		velocity.z = 0.0
		return

	var drop = speed * friction * delta
	var new_speed = max(speed - drop, 0)

	if speed > 0:
		horizontal *= new_speed / speed

	velocity.x = horizontal.x
	velocity.z = horizontal.z

# =============================
# ACCELERACIÓN REAL
# =============================

func accelerate(wish_dir, wish_speed, accel, delta):

	if wish_dir == Vector3.ZERO:
		return

	var current_speed = velocity.dot(wish_dir)
	var add_speed = wish_speed - current_speed

	if add_speed <= 0:
		return

	var accel_speed = accel * delta * wish_speed
	accel_speed = min(accel_speed, add_speed)

	velocity += wish_dir * accel_speed

# =============================
# AIR CONTROL (CLAVE)
# =============================

func air_control_func(wish_dir, delta):

	if abs(Input.get_action_strength("move_forward") - 
		   Input.get_action_strength("move_back")) == 0:
		return

	var z_speed = velocity.y
	velocity.y = 0

	var speed = velocity.length()
	velocity = velocity.normalized()

	var dot = velocity.dot(wish_dir)
	var k = air_control * dot * dot * delta

	if dot > 0:
		velocity = (velocity * speed + wish_dir * k).normalized()
		velocity *= speed

	velocity.y = z_speed
