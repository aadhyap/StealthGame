extends CharacterBody3D

@export var speed := 2.0
@export var patrol_distance := 6.0

var start_x: float
var direction := 1.0


func _ready():
	start_x = global_position.x


func _physics_process(delta):
	velocity.x = speed * direction

	if global_position.x >= start_x + patrol_distance:
		direction = -1.0

	if global_position.x <= start_x - patrol_distance:
		direction = 1.0

	move_and_slide()
