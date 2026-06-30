class_name Cfg
## Centralized, tunable configuration. Pure constants - no state.
## Accessed as `Cfg.PLAYER_SPEED` from anywhere.

# --- Viewport ---
const BASE_WIDTH := 720.0
const BASE_HEIGHT := 1280.0

# --- Player ---
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
const STAR_COUNT := 90
