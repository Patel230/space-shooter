# Space Shooter

A vibrant, cross-platform space shooter built with **Godot 4.7**. Responsive on macOS, Linux, Android, iOS, and Web.

## Play Online (GitHub Pages)

The game is automatically built and hosted via GitHub Actions:

**`https://<your-github-username>.github.io/<repo-name>/`**

### Setup (one-time)

1. Push this repo to GitHub.
2. In the repo, go to **Settings -> Pages**.
3. Under **Source**, choose **GitHub Actions**.
4. The `.github/workflows/deploy-web.yml` workflow runs on every push to `main`:
   - Downloads Godot 4.7 headless
   - Installs the Web export templates
   - Builds the web export into `build/web/`
   - Deploys to GitHub Pages.
5. After the workflow completes, visit the URL shown in the Pages settings.

The first build takes ~2-3 minutes. Subsequent builds are faster.

## Play Locally

### Desktop (macOS / Linux / Windows)

```bash
# Clone, then open in Godot 4.7
godot --path .
```

Or just double-click `project.godot` in the Godot editor.

### Web (local test)

```bash
godot --path . --export-release "Web" build/web/index.html
# Then serve with any static server:
python3 -m http.server --directory build/web 8000
# Open http://localhost:8000
```

### Android / iOS

Requires Android SDK (Android) or Xcode (iOS). Use **Project -> Export...** in the Godot editor.

## Controls

| Action | Keyboard / Mouse | Touch |
| --- | --- | --- |
| Move | Arrow keys / WASD | Drag |
| Shoot | Space (hold) | Auto-fire |
| Mute | M | Tap mute icon |
| Pause / Menu | Esc | Back gesture |

## Project Structure

```
space-shooter/
├── scripts/        # GDScript game logic (autoloads, entities, UI)
├── scenes/         # .tscn files + theme.tres
├── art/            # Kenney Space Shooter Remastered assets
├── .github/
│   └── workflows/
│       └── deploy-web.yml   # GitHub Pages auto-deploy
├── export_presets.cfg       # 6 platform presets (Win/Mac/Linux/Web/Android/iOS)
└── project.godot            # Godot 4.7 project file
```

## Architecture

- **Autoloads** (singletons): `SignalBus`, `Game`, `Music`
- **OOP base class**: `Projectile` (extended by `Bullet`, `EnemyBullet`)
- **Centralized config**: `constants.gd` (`Cfg`), `palette.gd` (`Palette`)
- **Responsive layout**: `responsive.gd` helpers + percentage anchors on every UI node
- **Procedural everything**: 10 galaxy background types, real-time synthesized music, particle effects

## Tech

- Godot 4.7 stable
- Pure GDScript (no GDExtension dependencies)
- ~20 scripts, ~13 scenes, single shared `theme.tres`
- 60 FPS on a Raspberry Pi 4 (WebGL2 fallback supported)

## Credits

Game art: [Kenney Space Shooter Remastered](https://kenney.nl/assets/space-shooter-remastered) (CC0)
Font: [Kenney Future](https://kenney.nl/assets/kenney-fonts) (CC0)
