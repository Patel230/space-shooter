class_name Palette
## Centralized color palette. Each element has its OWN unique color.
## No blue-dominant, no grouped-by-hue. Each UI element is visually distinct.
## Includes teal and cyan accents.

# --- Unique per-element colors (no duplicates, each visually distinct) ---
# HUD
const SCORE_COLOR := Color(0.30, 0.95, 0.85)             # TEAL
const SCORE_FLASH := Color(0.55, 1.20, 1.05)
const WAVE_COLOR := Color(1.0, 0.83, 0.25)               # GOLD
const WAVE_FLASH := Color(1.30, 1.10, 0.45)
const LIVES_COLOR := Color(1.0, 0.30, 0.35)              # CRIMSON
const LIVES_DANGER := Color(1.0, 0.10, 0.15)
const BANNER_COLOR := Color(0.70, 0.35, 1.0)             # VIOLET
const MUTED_COLOR := Color(0.95, 0.28, 0.72)             # MAGENTA

# Combo - rainbow cycle (all different hues)
const COMBO_COLORS := [
	Color(1.0, 0.83, 0.25),    # gold
	Color(0.30, 0.95, 0.85),   # teal
	Color(1.0, 0.55, 0.20),    # orange
	Color(0.95, 0.28, 0.72),   # magenta
	Color(0.55, 1.0, 0.35),    # lime
	Color(0.30, 0.70, 1.0),    # cyan-blue (one cool accent for variety)
]

# Main menu
const MENU_TITLE := Color(0.30, 0.95, 0.85)              # TEAL (matches score for brand)
const MENU_TITLE_GLOW_B := Color(0.65, 1.0, 0.95)
const MENU_SUB := Color(0.95, 0.28, 0.72)                # MAGENTA
const MENU_HIGH := Color(1.0, 0.83, 0.25)                # GOLD
const MENU_VOLUME_LABEL := Color(0.80, 0.78, 0.72)       # warm gray
const MENU_VOLUME_PERCENT := Color(0.30, 0.95, 0.85)     # TEAL
const MENU_HINT := Color(0.55, 0.52, 0.48)               # warm dim

# Game over
const GAMEOVER_TITLE := Color(1.0, 0.30, 0.35)           # CRIMSON
const GAMEOVER_SCORE := Color(1.0, 0.83, 0.25)           # GOLD
const GAMEOVER_HIGH := Color(0.30, 0.95, 0.85)           # TEAL
const GAMEOVER_NEW_RECORD := Color(0.55, 1.0, 0.35)      # LIME
const GAMEOVER_NEW_RECORD_GLOW := Color(0.30, 1.0, 0.20)

# Buttons (warm neutral so they don't clash)
const BUTTON_TEXT := Color(0.98, 0.95, 0.9)
const BUTTON_TEXT_HOVER := Color(1.0, 1.0, 1.0)

# Text
const TEXT_PRIMARY := Color(0.98, 0.95, 0.9)
const TEXT_SECONDARY := Color(0.8, 0.78, 0.72)
const TEXT_DIM := Color(0.55, 0.52, 0.48)

# --- UI backgrounds ---
const PANEL_BG := Color(0.06, 0.05, 0.03, 0.94)
const PANEL_BORDER := Color(0.5, 0.38, 0.15, 0.8)
const PANEL_SHADOW := Color(0.15, 0.08, 0.02, 0.6)
const BUTTON_BG := Color(0.12, 0.09, 0.05, 1)
const BUTTON_HOVER_BG := Color(0.22, 0.15, 0.06, 1)
const BUTTON_PRESSED_BG := Color(0.06, 0.04, 0.02, 1)

# --- Gameplay ---
const PLAYER_TRAIL := Color(1.0, 0.85, 0.3, 0.9)
const EXPLOSION_CORE := Color(1.0, 0.95, 0.7)
const EXPLOSION_MID := Color(1.0, 0.6, 0.15)
const EXPLOSION_END := Color(0.8, 0.1, 0.0, 0.0)
const POPUP_COLOR := Color(0.55, 1.0, 0.35)              # LIME for score popups
