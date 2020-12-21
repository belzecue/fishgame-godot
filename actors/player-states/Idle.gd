extends "res://addons/snopek-state-machine/State.gd"

onready var host = $"../.."

func _state_enter(info: Dictionary) -> void:
	host.play_animation("Idle" if host.vector.x == 0.0 else "Walk")

func _get_player_input_vector() -> Vector2:
	return Vector2(host.input_buffer.get_action_strength("right") - host.input_buffer.get_action_strength("left"), 0)

func _check_pickup_or_throw_or_use():
	# Only do this on the client controlling this player, because we have 
	# seperate system for sync'ing pickups and throws that this will conflict
	# with if it runs on a remote player.
	if GameState.online_play and not host.player_controlled:
		return
		
	if host.input_buffer.is_action_just_pressed("grab"):
		host.pickup_or_throw()
	elif host.input_buffer.is_action_just_pressed("use"):
		host.try_use()

func _state_physics_process(delta: float) -> void:
	_check_pickup_or_throw_or_use()
	
	var input_vector = _get_player_input_vector()
	
	if host.input_buffer.is_action_just_pressed("jump"):
		if host.is_on_floor():
			get_parent().change_state("Jump", {
				"input_vector": input_vector,
			})
			return
	elif host.input_buffer.is_action_pressed("down") and host.is_on_floor():
		get_parent().change_state("Duck")
		return
	elif input_vector != Vector2.ZERO:
		get_parent().change_state("Move", {
			"input_vector": input_vector,
		})
		return
	
	# Decelerate to 0.
	if host.vector.x < 0:
		host.vector.x = min(0.0, host.vector.x + (host.friction * delta))
	elif host.vector.x > 0:
		host.vector.x = max(0.0, host.vector.x - (host.friction * delta))
	
	# If we just decelerated to 0, then switch to the idle animation.
	if host.sprite.animation != "Idle" and host.vector.x == 0:
		host.play_animation("Idle")