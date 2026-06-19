extends Node2D


func _ready() -> void:
	$AnimationPlayer.play("loop")
	global.state_changed.connect(_on_state_changed)
	set_process(false)


func _on_state_changed(new_state: int) -> void:
	match new_state:
		global.GameState.GAME_OVER:
			$AnimationPlayer.pause()
		global.GameState.PLAYING:
			$AnimationPlayer.play("loop")
