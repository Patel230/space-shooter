class_name Palette
## Modern, vibrant, unique color palette. Each element has its own distinct color.
## Glassmorphism-style dark UI with vibrant accent glows.

# --- Unique per-element colors ---
# HUD
const SCORE_COLOR := Color(0.25, 0.95, 0.85)             # TEAL
const SCORE_FLASH := Color(0.5, 1.2, 1.1)
const WAVE_COLOR := Color(1.0, 0.75, 0.2)                # WARM GOLD
const WAVE_FLASH := Color(1.3, 1.0, 0.4)
const LIVES_COLOR := Color(1.0, 0.35, 0.4)               # CORAL
const LIVES_DANGER := Color(1.0, 0.1, 0.15)
const BANNER_COLOR := Color(0.65, 0.4, 1.0)              # VIOLET

# Combo - rainbow cycle
const COMBO_COLORS := [
	Color(1.0, 0.75, 0.2),    # gold
	Color(0.25, 0.95, 0.85),  # teal
	Color(1.0, 0.5, 0.25),    # orange
	Color(0.95, 0.3, 0.65),   # pink
	Color(0.5, 1.0, 0.4),     # lime
	Color(0.4, 0.7, 1.0),     # sky
]

# Main menu
const MENU_TITLE := Color(0.25, 0.95, 0.85)              # TEAL
const MENU_TITLE_GLOW := Color(0.6, 1.0, 0.95)

# Game over
const GAMEOVER_RECORD := Color(0.5, 1.0, 0.4)            # LIME
const GAMEOVER_RECORD_GLOW := Color(0.3, 1.0, 0.25)

# Action buttons (game-over / pause) — color signals what the action does.
const ACTION_RESUME := Color(0.5, 1.0, 0.4)              # LIME — go / continue
const ACTION_RESTART := Color(1.0, 0.75, 0.2)            # GOLD — repeat / retry
const ACTION_MENU := Color(0.4, 0.7, 1.0)                # SKY — navigate away

# Main-menu ship stat bars — each stat borrows the color of its HUD counterpart.
const STAT_SPEED := Color(0.4, 0.7, 1.0)                 # SKY
const STAT_FIRE_RATE := Color(1.0, 0.75, 0.2)            # GOLD
const STAT_LIVES := Color(1.0, 0.35, 0.4)                # CORAL (matches LIVES_COLOR)

# --- Gameplay ---
const PLAYER_TRAIL := Color(1.0, 0.8, 0.25, 0.85)
const EXPLOSION_CORE := Color(1.0, 0.95, 0.7)
const EXPLOSION_MID := Color(1.0, 0.6, 0.15)
const EXPLOSION_END := Color(0.8, 0.1, 0.0, 0.0)
const POPUP_COLOR := Color(0.5, 1.0, 0.4)                # LIME

# --- Wave banner palette — each wave gets a distinct color ---
const WAVE_BANNER_COLORS := [
	Color(0.65, 0.4, 1.0),     # violet (default)
	Color(0.25, 0.95, 0.85),   # teal
	Color(1.0, 0.75, 0.2),     # gold
	Color(1.0, 0.4, 0.55),     # rose
	Color(0.5, 1.0, 0.4),      # lime
	Color(0.4, 0.7, 1.0),      # sky
	Color(1.0, 0.5, 0.25),     # orange
	Color(0.9, 0.4, 1.0),      # magenta
	Color(0.3, 1.0, 0.7),      # mint
	Color(1.0, 0.85, 0.4),     # sand
]
const WAVE_CLEARED_COLOR := Color(0.5, 1.0, 0.4)         # LIME — success cue
