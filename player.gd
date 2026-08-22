extends CharacterBody3D

@export var speed := 5.0
@export var turn_speed := 2.50
@export var gravity := 20.0


func _physics_process(delta):
	var input := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_backward"
	)

	velocity.x = input.x * speed
	velocity.z = input.y * speed

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
		
	if Input.is_action_just_pressed("emerge") and is_on_floor():
		var forward = -global_transform.basis.z

		velocity.x = forward.x * 12.0
		velocity.z = forward.z * 12.0
		velocity.y = 10.0
	if Input.is_action_pressed("move_left"):
		rotate_y(turn_speed * delta)

	if Input.is_action_pressed("move_right"):
		rotate_y(-turn_speed * delta)

	move_and_slide()
