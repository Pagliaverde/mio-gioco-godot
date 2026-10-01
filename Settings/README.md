# Impostazioni

`Settings` è un autoload: gestisce audio, video, gioco, comandi, accessibilità
e tema. Salva tutto da solo in `user://settings.cfg` e applica i cambiamenti
subito, a tutto il gioco.

## Usarle nel gioco

```gdscript
Settings.get_value("audio", "music")          # leggere un valore
Settings.set_value("game", "difficulty", "hard")
Settings.changed.connect(func(section, key, value): ...)
Settings.theme_changed.connect(_ricolora)     # colori / font cambiati
Settings.open_menu()                          # es. dal menu di pausa
```

Scorciatoie: `Settings.color("accent")`, `Settings.palette_color(i)`,
`Settings.motion_scale()` (moltiplica le durate delle animazioni),
`Settings.screen_shake()`, `Settings.text_speed()`, `Settings.difficulty()`.

## Cose che funzionano già da sole

- **Audio**: metti i suoni sul bus giusto (`Music`, `SFX`, `UI`, `Voice`).
- **Stile**: tutti i Control del gioco (anche dentro un CanvasLayer) usano il
  tema scelto, perché è il tema di progetto (`Settings/game_theme.tres`).
  Varianti pronte: `TitleLabel`, `SectionLabel`, `DimLabel`, `CardPanel`.
- **Comandi**: ogni azione della Mappa di input (tranne `ui_*`) si può rimappare.
- **Dialoghi**: la velocità del testo è già collegata al balloon.

## Aggiungere un'impostazione

1. `Settings.register("gameplay", "camera_zoom", 1.0)` nello script che la usa.
2. Per vederla nella schermata, aggiungi una riga in `settings_schema.gd`.

Nuovi temi pronti: `theme_presets.gd`.
