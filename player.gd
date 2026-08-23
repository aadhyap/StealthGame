extends CharacterBody3D

@export var speed := 5.0
@export var air_speed := 4.0
@export var turn_speed := 2.5
@export var gravity := 8.0

@export var submerged_y := -0.02

@export var emerge_up_force := 8.0
@export var emerge_forward_force := 3.0

@export var attack_speed := 22.0
@export var lock_on_angle := 65.0
@export var hit_distance := 1.5

@export var rebound_up_force := 8.0
@export var rebound_forward_force := 2.0

@onready var submerged_marker = $SubmergedMarker
var enemy = null

var submerged := true
var attacking := false


func _ready():
	global_position.y = submerged_y
	submerged_marker.visible = true


func _physics_process(delta):
	if submerged:
		handle_submerged(delta)
	else:
		handle_airborne(delta)

	move_and_slide()


func handle_submerged(delta):
	if Input.is_action_pressed("move_left"):
		rotate_y(turn_speed * delta)

	if Input.is_action_pressed("move_right"):
		rotate_y(-turn_speed * delta)

	var input := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_backward"
	)

	var forward = -global_transform.basis.z
	var right = global_transform.basis.x

	var direction = (
		right * input.x +
		forward * -input.y
	).normalized()

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	velocity.y = 0.0

	global_position.y = submerged_y

	if Input.is_action_just_pressed("emerge"):
		emerge()


func emerge():
	submerged = false
	attacking = false
	submerged_marker.visible = false

	global_position.y = 1.0

	var forward = -global_transform.basis.z

	velocity.x = forward.x * emerge_forward_force
	velocity.z = forward.z * emerge_forward_force
	velocity.y = emerge_up_force


func handle_airborne(delta):
	# You can move/aim normally BEFORE committing to an attack
	if not attacking:
		var input := Input.get_vector(
			"move_left",
			"move_right",
			"move_forward",
			"move_backward"
		)

		var forward = -global_transform.basis.z
		var right = global_transform.basis.x

		var direction = (
			right * input.x +
			forward * -input.y
		).normalized()

		velocity.x = direction.x * air_speed
		velocity.z = direction.z * air_speed

		# Aim/rotate
		if Input.is_action_pressed("move_left"):
			rotate_y(turn_speed * delta)

		if Input.is_action_pressed("move_right"):
			rotate_y(-turn_speed * delta)

		# Choose and commit
		if Input.is_action_just_pressed("attack"):
			try_attack()

		# Normal float
		velocity.y -= gravity * delta

	else:
		# ATTACKING:
		# No steering and no second attack.
		# You're committed to the dart.
		check_enemy_hit()

	# Miss = fall/land and reset
	if is_on_floor() and velocity.y <= 0.0:
		submerge()


func try_attack():
	enemy = find_target()

	if enemy == null:
		print("NO TARGET")
		return

	var direction_to_enemy = (
		enemy.global_position - global_position
	).normalized()

	print("TARGET: ", enemy.name)

	start_attack(direction_to_enemy)


func start_attack(direction_to_enemy: Vector3):
	attacking = true

	enemy.velocity = Vector3.ZERO

	velocity = direction_to_enemy * attack_speed

	print("DART")


func check_enemy_hit():
	var distance_to_enemy = global_position.distance_to(
		enemy.global_position
	)

	if distance_to_enemy <= hit_distance:
		hit_enemy()


func hit_enemy():
	print("HIT: ", enemy.name)

	attacking = false

	# Save the enemy we hit
	var defeated_enemy = enemy
	enemy = null

	# Remove it from the level
	defeated_enemy.queue_free()

	# Launch upward again
	var forward = -global_transform.basis.z

	velocity.x = forward.x * rebound_forward_force
	velocity.z = forward.z * rebound_forward_force
	velocity.y = rebound_up_force


func submerge():
	submerged = true
	attacking = false

	velocity = Vector3.ZERO

	global_position.y = submerged_y
	submerged_marker.visible = true

func find_target():
	var enemies = get_tree().get_nodes_in_group("enemies")
	var forward = -global_transform.basis.z

	var best_enemy = null
	var best_angle = lock_on_angle

	for possible_enemy in enemies:
		var direction_to_enemy = (
			possible_enemy.global_position - global_position
		).normalized()

		var dot = clamp(
			forward.dot(direction_to_enemy),
			-1.0,
			1.0
		)

		var angle = rad_to_deg(acos(dot))

		if angle < best_angle:
			best_angle = angle
			best_enemy = possible_enemy

	return best_enemy
