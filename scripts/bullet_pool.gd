class_name BulletPool extends Node2D

const POOL_SIZE := 20
const _SCENE := preload("res://scenes/bullet.tscn")

var _pool: Array = []


func _ready() -> void:
	for i in POOL_SIZE:
		var b = _SCENE.instantiate()
		add_child(b)
		_pool.append(b)


func acquire(spawn_pos: Vector2) -> void:
	for b in _pool:
		if not b.visible:
			b.global_position = spawn_pos
			b.activate()
			return
	# Expand pool if all slots are active
	var b = _SCENE.instantiate()
	add_child(b)
	_pool.append(b)
	b.global_position = spawn_pos
	b.activate()


func deactivate_all() -> void:
	for b in _pool:
		b.deactivate()
