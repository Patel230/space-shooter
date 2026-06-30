extends Node
## Centralized event bus. Decouples emitters from listeners so entities
## never hold direct references to each other.
##
## Autoload name: SignalBus

signal score_changed(score: int)
signal lives_changed(lives: int)
signal wave_changed(wave: int)
signal high_score_changed(high_score: int)

signal player_died
signal player_hit
signal enemy_killed(pos: Vector2, score_value: int)
signal powerup_collected(type: int)

signal state_changed(state: int)

signal shake_requested(amount: float, duration: float)
signal banner_requested(text: String, color: Color)
signal mute_changed(muted: bool)
signal volume_changed(volume: float)
signal fx_preset_changed(preset: int)
signal screen_shake_changed(enabled: bool)
