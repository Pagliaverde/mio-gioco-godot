# 🎨 Illustrazioni delle carte

Metti qui **una immagine per carta**, chiamata **esattamente come l'id** della carta.

```
Cards/art/
├── fire_inferno.png
├── fire_inferno_guard.png
├── support_bulwark.png
├── poison_toxic_dart.webp
└── ...
```

Poi, nel dock **Carte**, premi **"Assegna art"**: ogni carta che ha un file col
suo nome riceve automaticamente l'illustrazione. Niente trascinamenti a mano.

## Regole

| Cosa | Come |
|---|---|
| Nome file | uguale all'**id** della carta (`fire_inferno.png` → carta `fire_inferno`) |
| Estensioni | `.png`, `.jpg`, `.jpeg`, `.webp`, `.svg` |
| Dove | direttamente in `Cards/art/` (niente sottocartelle) |

## Formato consigliato

- **Rapporto** ~4:3 o 3:2 (l'anteprima ritaglia comunque)
- **Risoluzione** 512×384 circa: abbastanza per l'anteprima e per il gioco, senza pesare
- **Pixel art**: attiva il filtro *Nearest* nell'import (Godot di default ha già
  `default_texture_filter=0` = Nearest in questo progetto)

## Note

- Una carta **senza** file mostra un segnaposto colorato con il colore del suo elemento.
- L'illustrazione è salvata dentro il `.tres` della carta come riferimento, quindi
  se sposti il file devi riassegnarla (premi di nuovo "Assegna art").
- Puoi anche assegnarla a mano: seleziona la carta, campo **Art** nell'inspector
  sotto il gruppo *Presentazione*.
