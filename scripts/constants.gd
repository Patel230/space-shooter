class_name Cfg
## Centralized, tunable configuration. Pure constants - no state.
## Accessed as `Cfg.PLAYER_SPEED` from anywhere.

# --- Ship types ---
## Each ship has unique stats: speed, fire rate, starting lives, triple shot.
enum ShipType { SCOUT, FIGHTER, TANK, BOMBER }

const SHIP_DEFS := {
	ShipType.SCOUT: {
		"name": "SCOUT",
		"texture": preload("res://art/kenney_space-shooter-remastered/PNG/playerShip1_blue.png"),
		"speed": 560.0,
		"cooldown": 0.18,
		"lives": 2,
		"triple": false,
		"desc": "Fast & nimble",
		"color": Color(0.3, 0.8, 1.0),
		"shoot_sfx": preload("res://art/kenney_space-shooter-remastered/Bonus/sfx_laser1.ogg"),
	},
	ShipType.FIGHTER: {
		"name": "FIGHTER",
		"texture": preload("res://art/kenney_space-shooter-remastered/PNG/playerShip2_orange.png"),
		"speed": 460.0,
		"cooldown": 0.22,
		"lives": 3,
		"triple": false,
		"desc": "Balanced all-rounder",
		"color": Color(1.0, 0.65, 0.2),
		"shoot_sfx": preload("res://art/kenney_space-shooter-remastered/Bonus/sfx_laser2.ogg"),
	},
	ShipType.TANK: {
		"name": "TANK",
		"texture": preload("res://art/kenney_space-shooter-remastered/PNG/playerShip3_green.png"),
		"speed": 340.0,
		"cooldown": 0.28,
		"lives": 5,
		"triple": true,
		"desc": "Slow but tough",
		"color": Color(0.4, 1.0, 0.35),
		"shoot_sfx": preload("res://art/kenney_space-shooter-remastered/Bonus/sfx_twoTone.ogg"),
	},
	ShipType.BOMBER: {
		"name": "BOMBER",
		"texture": preload("res://art/kenney_space-shooter-remastered/PNG/playerShip1_red.png"),
		"speed": 400.0,
		"cooldown": 0.12,
		"lives": 3,
		"triple": false,
		"desc": "Rapid fire blaster",
		"color": Color(1.0, 0.35, 0.35),
		"shoot_sfx": preload("res://art/kenney_ui-pack/Sounds/tap-a.ogg"),
	},
}
const SHIP_ORDER: Array = [ShipType.SCOUT, ShipType.FIGHTER, ShipType.TANK, ShipType.BOMBER]

# --- Player (defaults, overridden by selected ship) ---
const PLAYER_SPEED := 460.0
const SHOOT_COOLDOWN := 0.22
const RAPID_COOLDOWN := 0.11
const INVULN_TIME := 1.6
const POWERUP_DURATION := 7.0
const PLAYER_START_Y_RATIO := 0.86

# --- Projectiles ---
const BULLET_SPEED := 940.0
const ENEMY_BULLET_SPEED := 380.0

# --- Enemy ---
const ENEMY_SPEED_BASE := 150.0
const ENEMY_SPEED_PER_WAVE := 12.0
const ENEMY_SHOOT_INTERVAL := 3.5
const ENEMY_DRIFT_AMPLITUDE := 28.0
const ENEMY_SCORE := 10

# --- Powerup ---
const POWERUP_SPEED := 140.0
const POWERUP_SPIN := 2.2
const POWERUP_DROP_CHANCE := 0.12

# --- Waves ---
const WAVE_BASE_SIZE := 4
const WAVE_SIZE_PER_WAVE := 2
const WAVE_SPAWN_INTERVAL := 0.85
const WAVE_SPAWN_INTERVAL_DECAY := 0.05
const WAVE_SPAWN_INTERVAL_MIN := 0.25
const WAVE_INTERMISSION := 2.6

# --- FX ---
const SHAKE_HIT_AMOUNT := 8.0
const SHAKE_HIT_DURATION := 0.3
const SHAKE_DEATH_AMOUNT := 16.0
const SHAKE_DEATH_DURATION := 0.5
