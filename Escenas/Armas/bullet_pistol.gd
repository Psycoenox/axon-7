extends RigidBody3D

@export var speed := 50.0
@export var lifetime := 2.0

var time_alive := 0.0
var is_dead := false

func _ready():
	gravity_scale = 0
	contact_monitor = true
	max_contacts_reported = 1
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _physics_process(delta):
	if is_dead:
		return
	linear_velocity = -transform.basis.z * speed
	time_alive += delta
	if time_alive > lifetime:
		queue_free()

func _on_body_entered(_body):
	if is_dead:
		return
	is_dead = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	freeze = true
	queue_free()
