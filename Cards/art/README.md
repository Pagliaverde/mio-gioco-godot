# 🎨 Illustrazioni delle carte

**Ogni carta ha già un'illustrazione**, dipinta in pixel art da
[`Cards/ui/card_art_painter.gd`](../ui/card_art_painter.gd) a partire da ciò che la
carta fa: l'elemento sceglie colori e sfondo, il primo effetto il soggetto
(fiamme, lancia di ghiaccio, fulmine, scudo, cuore, calderone...), gli altri
effetti un dettaglio, il costo la dimensione, la rarità raggi e cornici.

I PNG in questa cartella sono **l'esportazione** di quei disegni: puoi ritoccarli
con qualsiasi editor di pixel art, e il gioco userà il file. Per rigenerarli
(ad esempio dopo aver aggiunto una carta):

```bash
godot --headless --path . --script res://Cards/tools/generate_card_art.gd
```

Scrive anche `contact_sheet.png`: tutte le carte in una tavola sola.

Per dare a una carta un soggetto preciso, aggiungi il suo id a
`CardArtPainter.VARIANTS` (es. Fendente di Fiamma = spada infuocata, Vampa =
palla di fuoco, Fenice = uccello di fiamme).

**L'ordine di scelta** (`CardView.resolve_art`): il campo **Art** della carta, poi
il file qui con il suo id, poi il disegno al volo.

---

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

- Una carta **senza** file (e senza **Art**) mostra il disegno di `CardArtPainter`.
- L'illustrazione è salvata dentro il `.tres` della carta come riferimento, quindi
  se sposti il file devi riassegnarla (premi di nuovo "Assegna art").
- Puoi anche assegnarla a mano: seleziona la carta, campo **Art** nell'inspector
  sotto il gruppo *Presentazione*.
