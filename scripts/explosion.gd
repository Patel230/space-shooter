extends AnimatedSprite2D

static var _cached_frames: SpriteFrames = null


func _ready() -> void:
	if not _cached_frames:
		_cached_frames = SpriteFrames.new()
		for i in range(20):
			_cached_frames.add_frame("default", load("res://art/kenney_space-shooter-remastered/PNG/Effects/fire%02d.png" % i))
	sprite_frames = _cached_frames
	play()
	animation_finished.connect(queue_free)
