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
const MUTED_COLOR := Color(0.95, 0.3, 0.65)              # PINK

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
const MENU_SUB := Color(0.95, 0.3, 0.65)                 # PINK
const MENU_HIGH := Color(1.0, 0.75, 0.2)                 # GOLD
const MENU_VOL_LABEL := Color(0.7, 0.68, 0.65)           # WARM GRAY
const MENU_VOL_PCT := Color(0.25, 0.95, 0.85)            # TEAL
const MENU_HINT := Color(0.5, 0.48, 0.45)                # DIM GRAY

# Game over
const GAMEOVER_TITLE := Color(1.0, 0.35, 0.4)            # CORAL
const GAMEOVER_SCORE := Color(1.0, 0.75, 0.2)            # GOLD
const GAMEOVER_HIGH := Color(0.25, 0.95, 0.85)           # TEAL
const GAMEOVER_RECORD := Color(0.5, 1.0, 0.4)            # LIME
const GAMEOVER_RECORD_GLOW := Color(0.3, 1.0, 0.25)

# Buttons
const BUTTON_TEXT := Color(0.95, 0.92, 0.88)

# --- UI backgrounds (glassmorphism) ---
const PANEL_BG := Color(0.05, 0.04, 0.03, 0.88)
const PANEL_BORDER := Color(0.45, 0.35, 0.15, 0.6)
const PANEL_SHADOW := Color(0.1, 0.06, 0.02, 0.5)

# --- Gameplay ---
const PLAYER_TRAIL := Color(1.0, 0.8, 0.25, 0.85)
const EXPLOSION_CORE := Color(1.0, 0.95, 0.7)
const EXPLOSION_MID := Color(1.0, 0.6, 0.15)
const EXPLOSION_END := Color(0.8, 0.1, 0.0, 0.0)
const POPUP_COLOR := Color(0.5, 1.0, 0.4)                # LIME
