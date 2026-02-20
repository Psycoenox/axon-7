extends Node3D

var current_weapon_index := 0
var weapons := []

func _ready():
	weapons = get_children()
	equip(0)

func _input(event):
	if event is InputEventMouseMotion:
		return
	
	if event is InputEventKey and event.pressed:
		if event.is_action("weapon_1"): equip(0)
		if event.is_action("weapon_2"): equip(1)
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			equip(wrapi(current_weapon_index - 1, 0, weapons.size()))
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			equip(wrapi(current_weapon_index + 1, 0, weapons.size()))

func equip(index: int):
	current_weapon_index = index
	for i in weapons.size():
		weapons[i].visible = (i == index)
		weapons[i].set_process(i == index)
		weapons[i].set_physics_process(i == index)
