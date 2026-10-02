# 🗂️ Libreria di Prompt — *Fuori Copione*

**Ogni blocco è completo: copi, incolli, generi.** Niente da montare a mano.

> ## 🚨 Il limite di 2000 caratteri
>
> Il campo di PixelLab tiene **2000 caratteri**. Ogni prompt di questa libreria è
> stato scritto e **misurato** per starci dentro.
>
> | | |
> |---|---|
> | **Blocco Base** (lo stile, in ogni prompt) | **647 caratteri** |
| Prompt più corto | 979 |
| Prompt più lungo (le 9 maschere) | **1699** |
| Margine residuo anche nel caso peggiore | **301 caratteri** |
>
> Il Blocco Base è **già dentro ogni prompt** qui sotto, parola per parola. Non
> devi incollarlo a parte e non devi toccarlo.

> ## ⚙️ Quello che NON c'è scritto, perché lo decidi nella UI
>
> Dalla tua schermata: `64x64px`, `8 directions`, `low top-down view` sono
> **impostazioni del tool**, non testo. Quindi nei prompt **non troverai**:
> dimensioni, numero di direzioni, prospettiva, sfondo trasparente.
> Occupavano 300 caratteri a testa e li stavi sprecando.
>
> **Controlla che siano impostati così:**
> `64x64px` · `8 directions` · `low top-down view`

---

## 📑 Indice

1. [Come si usa](#-come-si-usa)
2. [Il Blocco Base](#-il-blocco-base)
3. [La tavolozza](#-la-tavolozza)
4. [Ordine di generazione](#-ordine-di-generazione)
5. [1 · Personaggi](#1--personaggi)
6. [2 · Mappa](#2--mappa)
7. [3 · Scenografia](#3--scenografia)
8. [4 · I cinque boss](#4--i-cinque-boss)
9. [5 · Maschere](#5--maschere)
10. [6 · Carte e ritratto](#6--carte-e-ritratto)
11. [Come usare PixelLab](#-come-usare-pixellab)
12. [Dopo la generazione](#-dopo-la-generazione)
13. [Le trappole](#-le-trappole)

---

## 🚀 Come si usa

1. **Genera prima il protagonista.** È il tuo riferimento visivo.
2. **Tienilo aperto accanto** mentre generi il resto e confronta a occhio.
3. Per ogni asset: **copia il blocco intero**, dalla prima all'ultima riga.
4. Il numero di caratteri è scritto sopra ogni blocco, così sai di essere
   dentro il limite.

**Regola d'oro:** se un risultato è bello ma *fuori stile*, scartalo. Non
"recuperarlo" in Aseprite: ci metti più tempo che rigenerarlo.

> **Questo file serve a *generare*.** Per il *perché* dietro queste scelte
> (confronto fra le IA, importazione in Godot, trappole) vedi
> **[`Docs/AI_SPRITE_PROMPT.md`](AI_SPRITE_PROMPT.md)**.

---

## ⬛ Il Blocco Base

**647 caratteri.** È dentro ogni prompt qui sotto. Lo vedi qui una volta sola
per capire cos'è, ma **non devi incollarlo a parte**.

```
Pixel art 16-bit, strict pixel grid, no antialiasing, no blur. Outline 1px #3a2f52, never black. Flat colours, light from upper left, one shade step, one highlight step, max 20 colours.
Palette, these only: #3a2f52 #2e2350 #5b4a8f #7b5ea7 #e8e2d4 #8a8a92 #c9a06a #8a6440 #c9a227 #8f2f2f #7a9a6a
Setting: one endless theatre; a fake city inside it, painted facades on wooden easels, papier-mache trees with visible wire frames, purple plank streets, worn velvet, painted canvas sky. Dusty, melancholic, sinister, obviously fake.
Never: text, letters, numbers, watermark, signature, UI, frame, border, drop shadow, photorealism, 3D, anime, chibi.
```

### Perché ogni riga è lì

| Riga | Cosa impedisce |
|---|---|
`strict pixel grid` | L'IA fa un disegno *piccolo ma liscio*. Questa riga la costringe a pensare a pixel veri |
`never black` | Il nero puro è l'errore più comune e fa sembrare tutto un fumetto economico |
`max 20 colours` | Senza limite spara 200 colori e perde l'aria pixel art |
`light from upper left` | Senza una regola fissa ogni sprite è illuminato da un lato diverso e il set non sta insieme |
`painted facades on wooden easels` | È il cuore visivo della tua storia. Senza, l'IA fa case normali e perdi il tema |
`purple plank streets` | Impedisce che il primo foglio esca verde e il secondo blu |
`Never: text...` | Le IA **adorano** mettere scritte e firme. Vanno vietate esplicitamente |

---

## 🎨 La tavolozza

Sono **già dentro ogni prompt**, ma tienili qui per controllare a occhio.

| Colore | Hex | Dove si vede |
|---|---|---|
| Contorno | `#3a2f52` | Il contorno di **tutto**. Mai nero |
| Ombra profonda | `#2e2350` | Le zone al buio, i fondi dei ritratti |
| **Viola firma** | `#5b4a8f` | Il colore del gioco. Sale d'intensità verso il fondo |
| Finitura viola | `#7b5ea7` | I bordi dei costumi |
| Bianco di scena | `#e8e2d4` | Il costume del protagonista. **Non bianco puro** |
| Grigio polvere | `#8a8a92` | Il Camerino, il personale |
| Legno chiaro | `#c9a06a` | Manichini, cavalletti, casse |
| Legno scuro | `#8a6440` | Strutture, assi, cornici |
| Oro consumato | `#c9a227` | Il Palco, le maschere dei boss |
| Rosso scena | `#8f2f2f` | Velluto, poltrone, la Prima Attrice |
| Verde malato | `#7a9a6a` | I Corridoi, il cartapesta |

---

## 📋 Ordine di generazione

**L'ordine conta:** il primo che generi diventa il metro per tutti gli altri.

| # | Cosa | Priorità |
|---|---|---|
1 | Il protagonista | 🔴 **Prima di tutto** |
2 | Il manichino (in piedi e seduto) | 🔴 Alta |
3 | Il tileset del teatro | 🔴 Alta |
4 | Gli NPC | 🟠 Media |
5 | Il fondale, la scenografia | 🟠 Media |
6 | Le maschere | 🟡 Bassa |
7 | I ritratti dei boss | 🟡 Bassa |
8 | Le carte | 🟢 Dopo |

---

## 1 · Personaggi

> **Su PixelLab, un personaggio per volta.** Il tool genera lui le 8 direzioni
> da una descrizione sola: non devi chiedere "fronte, retro, lato", non devi
> fare fogli 3×3. Descrivi **chi è**, e basta.

### 1 · IL PROTAGONISTA — `1119 caratteri`

```
Pixel art 16-bit, strict pixel grid, no antialiasing, no blur. Outline 1px #3a2f52, never black. Flat colours, light from upper left, one shade step, one highlight step, max 20 colours.
Palette, these only: #3a2f52 #2e2350 #5b4a8f #7b5ea7 #e8e2d4 #8a8a92 #c9a06a #8a6440 #c9a227 #8f2f2f #7a9a6a
Setting: one endless theatre; a fake city inside it, painted facades on wooden easels, papier-mache trees with visible wire frames, purple plank streets, worn velvet, painted canvas sky. Dusty, melancholic, sinister, obviously fake.
Never: text, letters, numbers, watermark, signature, UI, frame, border, drop shadow, photorealism, 3D, anime, chibi.
The protagonist: a performer with NO FACE, an understudy costume with nobody inside it. Off-white stage costume #e8e2d4 with violet trim #7b5ea7, dusty and worn. The head is a smooth matte blank oval, like an unpainted mannequin head: NO eyes, NO mouth, NO nose, NO facial features. A small stack of mask shapes hangs at the belt, not worn. Slim, medium height, reads as innocent and slightly lost, never threatening. The head stays completely blank: NO facial features.
```

> **Il volto vuoto è la cosa più difficile da ottenere.** Le IA *vogliono*
> mettere una faccia, e nella tua prima prova l'hanno messa. Se dopo tre
> tentativi insiste, generane uno con la faccia e **cancellala tu** in Aseprite:
> è più veloce che litigarci. Nel campo negativo scrivi:
> `eyes, mouth, nose, face, facial features`

### 2 · IL MANICHINO IN PIEDI — `1026 caratteri`

```
Pixel art 16-bit, strict pixel grid, no antialiasing, no blur. Outline 1px #3a2f52, never black. Flat colours, light from upper left, one shade step, one highlight step, max 20 colours.
Palette, these only: #3a2f52 #2e2350 #5b4a8f #7b5ea7 #e8e2d4 #8a8a92 #c9a06a #8a6440 #c9a227 #8f2f2f #7a9a6a
Setting: one endless theatre; a fake city inside it, painted facades on wooden easels, papier-mache trees with visible wire frames, purple plank streets, worn velvet, painted canvas sky. Dusty, melancholic, sinister, obviously fake.
Never: text, letters, numbers, watermark, signature, UI, frame, border, drop shadow, photorealism, 3D, anime, chibi.
A theatre mannequin from the audience: a wooden artist's mannequin in pale unfinished wood #c9a06a, with ball joints visible at shoulders, elbows, hips and knees. Standing perfectly straight, arms hanging, completely motionless. The head is a smooth blank wooden oval with NO facial features, NO eyes. Generic and identical to all the others: there is nothing special about it.
```

### 3 · IL MANICHINO SEDUTO — `1053 caratteri`

Nel vecchio set **non c'era**, e nella platea un manichino in piedi sembra
sbagliato: l'Auditorium ne è pieno.

```
Pixel art 16-bit, strict pixel grid, no antialiasing, no blur. Outline 1px #3a2f52, never black. Flat colours, light from upper left, one shade step, one highlight step, max 20 colours.
Palette, these only: #3a2f52 #2e2350 #5b4a8f #7b5ea7 #e8e2d4 #8a8a92 #c9a06a #8a6440 #c9a227 #8f2f2f #7a9a6a
Setting: one endless theatre; a fake city inside it, painted facades on wooden easels, papier-mache trees with visible wire frames, purple plank streets, worn velvet, painted canvas sky. Dusty, melancholic, sinister, obviously fake.
Never: text, letters, numbers, watermark, signature, UI, frame, border, drop shadow, photorealism, 3D, anime, chibi.
A theatre mannequin SEATED in a worn theatre seat, part of an audience row. A wooden artist's mannequin in pale unfinished wood #c9a06a, ball joints visible. Sitting perfectly still, back straight, hands resting on the knees. The head is a smooth blank wooden oval with NO facial features, NO eyes. The seat is worn dark red velvet #8f2f2f on a dark wooden frame. Generic and identical to all the others.
```

### 4 · NPC — IL PERSONALE — `1071 caratteri`

Uno dei Corridoi. Serve gente che **ha accettato** il sistema.

```
Pixel art 16-bit, strict pixel grid, no antialiasing, no blur. Outline 1px #3a2f52, never black. Flat colours, light from upper left, one shade step, one highlight step, max 20 colours.
Palette, these only: #3a2f52 #2e2350 #5b4a8f #7b5ea7 #e8e2d4 #8a8a92 #c9a06a #8a6440 #c9a227 #8f2f2f #7a9a6a
Setting: one endless theatre; a fake city inside it, painted facades on wooden easels, papier-mache trees with visible wire frames, purple plank streets, worn velvet, painted canvas sky. Dusty, melancholic, sinister, obviously fake.
Never: text, letters, numbers, watermark, signature, UI, frame, border, drop shadow, photorealism, 3D, anime, chibi.
A theatre staff member whose whole part is "staff" and who never steps out of it. A tired stagehand in a grey work coat #8a8a92 over dark trousers, sleeves rolled up, a coil of rope on one shoulder, a clipboard held against the chest. Slightly hunched, functional, expressionless. A plain pale oval head under a single dark cap, no face detail. Perfectly ordinary and unremarkable, as if he has always been standing there.
```

### 5 · NPC — UN ALTRO ATTORE — `1045 caratteri`

Uno che **recita ancora**, di fretta. È ciò che il protagonista potrebbe
diventare.

```
Pixel art 16-bit, strict pixel grid, no antialiasing, no blur. Outline 1px #3a2f52, never black. Flat colours, light from upper left, one shade step, one highlight step, max 20 colours.
Palette, these only: #3a2f52 #2e2350 #5b4a8f #7b5ea7 #e8e2d4 #8a8a92 #c9a06a #8a6440 #c9a227 #8f2f2f #7a9a6a
Setting: one endless theatre; a fake city inside it, painted facades on wooden easels, papier-mache trees with visible wire frames, purple plank streets, worn velvet, painted canvas sky. Dusty, melancholic, sinister, obviously fake.
Never: text, letters, numbers, watermark, signature, UI, frame, border, drop shadow, photorealism, 3D, anime, chibi.
Another performer, always mid-scene and in a hurry. Theatrical costume: a worn gold #c9a227 doublet with stage red #8f2f2f trim, a feathered cap, a blunt wooden prop sword at the hip. Posture exaggerated and theatrical, one hand raised as if delivering a line to nobody. The face is covered by a plain pale mask with no expression. Confident, slightly ridiculous, unaware that nobody is watching.
```

### 6 · NPC — IL VENDITORE DI MASCHERE — `1044 caratteri`

Nella Piazza Dipinta. Vende maschere che **non servono a niente**, ed è
convinto del contrario.

```
Pixel art 16-bit, strict pixel grid, no antialiasing, no blur. Outline 1px #3a2f52, never black. Flat colours, light from upper left, one shade step, one highlight step, max 20 colours.
Palette, these only: #3a2f52 #2e2350 #5b4a8f #7b5ea7 #e8e2d4 #8a8a92 #c9a06a #8a6440 #c9a227 #8f2f2f #7a9a6a
Setting: one endless theatre; a fake city inside it, painted facades on wooden easels, papier-mache trees with visible wire frames, purple plank streets, worn velvet, painted canvas sky. Dusty, melancholic, sinister, obviously fake.
Never: text, letters, numbers, watermark, signature, UI, frame, border, drop shadow, photorealism, 3D, anime, chibi.
A mask seller. Heavy build, a long dusty violet coat #7b5ea7 with a deep hood, and a wide flat vendor's tray strapped across the chest carrying four small blank pale theatre masks. Arms spread slightly, welcoming, presenting a bargain. The face is hidden inside the hood in shadow: NO visible face at all. Enthusiastic and entirely for show. He sells masks that do nothing, and believes in them.
```

---

## 2 · Mappa

### 7 · IL TILESET DEL TEATRO — `1221 caratteri`

**Uno solo, non sette.** Il documento di design lo dice: stessa mappa, palette
diverse. Il ricolore lo fai poi in Godot con uno shader.

> Questo è **l'unico prompt** che sul tool potrebbe essere in una sezione
> diversa da "Character" (un tileset non è un personaggio). Se trovi la
> sezione giusta, meglio; altrimenti va bene anche una generazione singola.

```
Pixel art 16-bit, strict pixel grid, no antialiasing, no blur. Outline 1px #3a2f52, never black. Flat colours, light from upper left, one shade step, one highlight step, max 20 colours.
Palette, these only: #3a2f52 #2e2350 #5b4a8f #7b5ea7 #e8e2d4 #8a8a92 #c9a06a #8a6440 #c9a227 #8f2f2f #7a9a6a
Setting: one endless theatre; a fake city inside it, painted facades on wooden easels, papier-mache trees with visible wire frames, purple plank streets, worn velvet, painted canvas sky. Dusty, melancholic, sinister, obviously fake.
Never: text, letters, numbers, watermark, signature, UI, frame, border, drop shadow, photorealism, 3D, anime, chibi.
A top-down tile set on a strict grid. Every tile fills its cell completely, edge to edge, with no gaps and no borders. Neutral lighting only: no coloured light baked in, so the tiles can be recoloured later. Sixteen tiles: purple wooden plank floor A and B; worn velvet floor A and B; painted canvas wall A and B; a flat mid-purple void tile; a backdrop tile with brush strokes; a wooden kerb edge; a plank wainscot strip; a stage floor with a painted trapdoor outline; a velvet stair edge; a wooden crate; an open wooden crate; a velvet rope barrier; a scaffolding plank.
```

### 8 · IL FONDALE DIPINTO — `1060 caratteri`

Il cielo del gioco **è una tela dipinta**.

```
Pixel art 16-bit, strict pixel grid, no antialiasing, no blur. Outline 1px #3a2f52, never black. Flat colours, light from upper left, one shade step, one highlight step, max 20 colours.
Palette, these only: #3a2f52 #2e2350 #5b4a8f #7b5ea7 #e8e2d4 #8a8a92 #c9a06a #8a6440 #c9a227 #8f2f2f #7a9a6a
Setting: one endless theatre; a fake city inside it, painted facades on wooden easels, papier-mache trees with visible wire frames, purple plank streets, worn velvet, painted canvas sky. Dusty, melancholic, sinister, obviously fake.
Never: text, letters, numbers, watermark, signature, UI, frame, border, drop shadow, photorealism, 3D, anime, chibi.
A huge painted canvas sky backdrop for a stage, hand-painted and slightly sloppy. Deep violet #2e2350 at the top fading to #5b4a8f at the bottom, with long wobbling horizontal brush strokes like cheap scenery paint. A few deliberate paint drips, and a couple of unpainted patches where the raw canvas shows through in #8a8a92. No clouds, no stars, no sun, no birds. This is not a sky: it is a painting of a sky.
```

---

## 3 · Scenografia

### 9 · LA FACCIATA SU CAVALLETTO — `1201 caratteri`

È il palazzo del gioco. Il vuoto dietro è **il punto**.

```
Pixel art 16-bit, strict pixel grid, no antialiasing, no blur. Outline 1px #3a2f52, never black. Flat colours, light from upper left, one shade step, one highlight step, max 20 colours.
Palette, these only: #3a2f52 #2e2350 #5b4a8f #7b5ea7 #e8e2d4 #8a8a92 #c9a06a #8a6440 #c9a227 #8f2f2f #7a9a6a
Setting: one endless theatre; a fake city inside it, painted facades on wooden easels, papier-mache trees with visible wire frames, purple plank streets, worn velvet, painted canvas sky. Dusty, melancholic, sinister, obviously fake.
Never: text, letters, numbers, watermark, signature, UI, frame, border, drop shadow, photorealism, 3D, anime, chibi.
A flat building facade standing on wooden easel supports, front view. It is scenery, not a building. The facade is a painted flat panel; its windows and its door are PAINTED ON, flat, unable to open. It leans slightly, held up by two visible wooden easel legs and a diagonal brace behind it. Around and behind the panel you can see empty scaffolding and the void. There is no depth behind it: it is paper-thin and it shows. Three variants: a shopfront with a painted awning; a tall house front with painted shutters; a cracked panel with peeling paint.
```

### 10 · L'ALBERO DI CARTAPESTA — `1063 caratteri`

Si vede la struttura quando ci passi vicino. Quello è il dettaglio che vende
tutto.

```
Pixel art 16-bit, strict pixel grid, no antialiasing, no blur. Outline 1px #3a2f52, never black. Flat colours, light from upper left, one shade step, one highlight step, max 20 colours.
Palette, these only: #3a2f52 #2e2350 #5b4a8f #7b5ea7 #e8e2d4 #8a8a92 #c9a06a #8a6440 #c9a227 #8f2f2f #7a9a6a
Setting: one endless theatre; a fake city inside it, painted facades on wooden easels, papier-mache trees with visible wire frames, purple plank streets, worn velvet, painted canvas sky. Dusty, melancholic, sinister, obviously fake.
Never: text, letters, numbers, watermark, signature, UI, frame, border, drop shadow, photorealism, 3D, anime, chibi.
A papier-mache tree prop standing in a wooden base, front view. It is cheap scenery: the trunk and canopy are lumpy painted papier-mache with visible seams, and a chicken-wire and stick frame shows through the paint near the trunk. A patch of paint is missing, showing the grey pulp #8a8a92 underneath. The canopy is muted sick green #7a9a6a, dry and dusty, not lush. It must look handmade, cheap and slightly sad.
```

### 11 · LO SPECCHIO — `1061 caratteri`

**Rotto** (il Camerino, il prologo) e **intero** (la Galleria) nello stesso
prompt.

```
Pixel art 16-bit, strict pixel grid, no antialiasing, no blur. Outline 1px #3a2f52, never black. Flat colours, light from upper left, one shade step, one highlight step, max 20 colours.
Palette, these only: #3a2f52 #2e2350 #5b4a8f #7b5ea7 #e8e2d4 #8a8a92 #c9a06a #8a6440 #c9a227 #8f2f2f #7a9a6a
Setting: one endless theatre; a fake city inside it, painted facades on wooden easels, papier-mache trees with visible wire frames, purple plank streets, worn velvet, painted canvas sky. Dusty, melancholic, sinister, obviously fake.
Never: text, letters, numbers, watermark, signature, UI, frame, border, drop shadow, photorealism, 3D, anime, chibi.
A tall standing dressing-room mirror on a dark wooden frame #8a6440 with a small wooden foot. The glass shows only flat violet #5b4a8f with a diagonal light streak: no reflection of anything, no room behind it. Two variants: one intact, whole glass, dust along the frame; and one shattered, with big cracks radiating from a broken corner and a few shards missing entirely, showing the dark empty backing #2e2350.
```

### 12 · IL BAULE DI SCENA — `979 caratteri`

Dove trovi le maschere. Si deve capire a colpo d'occhio che è **aperto**.

```
Pixel art 16-bit, strict pixel grid, no antialiasing, no blur. Outline 1px #3a2f52, never black. Flat colours, light from upper left, one shade step, one highlight step, max 20 colours.
Palette, these only: #3a2f52 #2e2350 #5b4a8f #7b5ea7 #e8e2d4 #8a8a92 #c9a06a #8a6440 #c9a227 #8f2f2f #7a9a6a
Setting: one endless theatre; a fake city inside it, painted facades on wooden easels, papier-mache trees with visible wire frames, purple plank streets, worn velvet, painted canvas sky. Dusty, melancholic, sinister, obviously fake.
Never: text, letters, numbers, watermark, signature, UI, frame, border, drop shadow, photorealism, 3D, anime, chibi.
An old theatre trunk, open, front view. Dark wood with worn brass #c9a227 corners and a heavy open lid leaning back. Inside, packed theatre props: three or four pale blank masks, a folded red velvet cloth #8f2f2f, and a coil of rope. Slightly dusty, standing on the floor. It must read instantly as a container with things inside.
```

### 13 · LA PORTA EXIT — `1191 caratteri`

La porta finta, dipinta sul fondale.

> ⚠️ **Non far scrivere "EXIT" all'IA.** Le IA sbagliano sempre le lettere.
> Genera la porta **senza scritta** e aggiungi tu la parola in Aseprite con un
> font a 1px. Un minuto, e viene giusta.

```
Pixel art 16-bit, strict pixel grid, no antialiasing, no blur. Outline 1px #3a2f52, never black. Flat colours, light from upper left, one shade step, one highlight step, max 20 colours.
Palette, these only: #3a2f52 #2e2350 #5b4a8f #7b5ea7 #e8e2d4 #8a8a92 #c9a06a #8a6440 #c9a227 #8f2f2f #7a9a6a
Setting: one endless theatre; a fake city inside it, painted facades on wooden easels, papier-mache trees with visible wire frames, purple plank streets, worn velvet, painted canvas sky. Dusty, melancholic, sinister, obviously fake.
Never: text, letters, numbers, watermark, signature, UI, frame, border, drop shadow, photorealism, 3D, anime, chibi.
An emergency exit door PAINTED FLAT on a canvas backdrop. It must look like a real door and obviously wrong at the same time: perfectly flat, no thickness, no frame depth, no shadow under it. Painted on slightly wrinkled canvas, with fabric weave and two folds crossing the door. A plain blank sick green #7a9a6a sign panel above it, with no letters on it at all. A painted waist bar across the middle. Its paint is fresh and clean while everything around it is dirty: it was painted recently, on purpose. Front view, flat on, no perspective.
```

### 14 · LA POLTRONA DEL TEATRO — `1084 caratteri`

Ne servono **a centinaia**: la platea ne è piena. Falle semplici.

```
Pixel art 16-bit, strict pixel grid, no antialiasing, no blur. Outline 1px #3a2f52, never black. Flat colours, light from upper left, one shade step, one highlight step, max 20 colours.
Palette, these only: #3a2f52 #2e2350 #5b4a8f #7b5ea7 #e8e2d4 #8a8a92 #c9a06a #8a6440 #c9a227 #8f2f2f #7a9a6a
Setting: one endless theatre; a fake city inside it, painted facades on wooden easels, papier-mache trees with visible wire frames, purple plank streets, worn velvet, painted canvas sky. Dusty, melancholic, sinister, obviously fake.
Never: text, letters, numbers, watermark, signature, UI, frame, border, drop shadow, photorealism, 3D, anime, chibi.
A single empty theatre seat, front view, flat and side-on enough to be tiled in a long row. Worn dark red velvet #8f2f2f cushion and backrest, a dark wooden frame #8a6440, a small brass number plate on the back, dust in the creases. No person, no shadow under it. Simple and readable: it must survive being repeated three hundred times on screen. Two variants: one better kept, and one more worn with a torn corner showing the padding.
```

---

## 4 · I cinque boss

I boss non camminano: sono **attori che recitano per il pubblico**. Ti serve un
**ritratto**, non un personaggio animato.

Ogni prompt dei boss è **Blocco Base + ritratto base + la riga del boss**.
Totale fra **1386 e 1431 caratteri**: comodi.

### Base del ritratto — `316 caratteri`

```
Portrait, head and shoulders, facing the viewer, framed like a theatre playbill. Strong single light from the upper left, deep violet #2e2350 behind. The mask is the focal point of the image: it must be readable at a glance and look like it can no longer be taken off, too tight, stuck to the skin, part of the face.
```

### 15 · BOSS I — LA COMPARSA — `1386 caratteri`

> *"Fuori non c'è niente. Meglio qui. Meglio qui."*

```
Pixel art 16-bit, strict pixel grid, no antialiasing, no blur. Outline 1px #3a2f52, never black. Flat colours, light from upper left, one shade step, one highlight step, max 20 colours.
Palette, these only: #3a2f52 #2e2350 #5b4a8f #7b5ea7 #e8e2d4 #8a8a92 #c9a06a #8a6440 #c9a227 #8f2f2f #7a9a6a
Setting: one endless theatre; a fake city inside it, painted facades on wooden easels, papier-mache trees with visible wire frames, purple plank streets, worn velvet, painted canvas sky. Dusty, melancholic, sinister, obviously fake.
Never: text, letters, numbers, watermark, signature, UI, frame, border, drop shadow, photorealism, 3D, anime, chibi.
Portrait, head and shoulders, facing the viewer, framed like a theatre playbill. Strong single light from the upper left, deep violet #2e2350 behind. The mask is the focal point of the image: it must be readable at a glance and look like it can no longer be taken off, too tight, stuck to the skin, part of the face.
A worn-out actor who never got a part and stopped wanting one. Middle aged, average, tired to the bone, in dusty grey #8a8a92 plain clothes, shoulders slumped. NO MASK AT ALL: his bare face is visible, and its absence is the whole point. Blank, resigned, mildly disappointed, no anger, eyes looking slightly past the viewer. He looks like someone who has stood in the same spot for years and no longer expects anything.
```

### 16 · BOSS II — IL SOSTITUTO — `1419 caratteri`

> *"Ora ci sono tre di me. Nessuno è quello vero."*

```
Pixel art 16-bit, strict pixel grid, no antialiasing, no blur. Outline 1px #3a2f52, never black. Flat colours, light from upper left, one shade step, one highlight step, max 20 colours.
Palette, these only: #3a2f52 #2e2350 #5b4a8f #7b5ea7 #e8e2d4 #8a8a92 #c9a06a #8a6440 #c9a227 #8f2f2f #7a9a6a
Setting: one endless theatre; a fake city inside it, painted facades on wooden easels, papier-mache trees with visible wire frames, purple plank streets, worn velvet, painted canvas sky. Dusty, melancholic, sinister, obviously fake.
Never: text, letters, numbers, watermark, signature, UI, frame, border, drop shadow, photorealism, 3D, anime, chibi.
Portrait, head and shoulders, facing the viewer, framed like a theatre playbill. Strong single light from the upper left, deep violet #2e2350 behind. The mask is the focal point of the image: it must be readable at a glance and look like it can no longer be taken off, too tight, stuck to the skin, part of the face.
A figure exactly like the protagonist, in an off-white stage costume #e8e2d4 with violet trim #7b5ea7, but wearing the protagonist's own featureless white face AS A MASK. The mask is a smooth blank oval, too tight, with visible creases where the skin does not fit, and its edges pressed into the jaw. Uncanny because it is the player's own face. Behind the shoulders, two more identical figures are faintly visible, partially transparent, out of focus.
```

### 17 · BOSS III — LA PRIMA ATTRICE — `1419 caratteri`

> *"Ho visto fuori. Non c'era pubblico. Qui almeno qualcuno guarda."*

```
Pixel art 16-bit, strict pixel grid, no antialiasing, no blur. Outline 1px #3a2f52, never black. Flat colours, light from upper left, one shade step, one highlight step, max 20 colours.
Palette, these only: #3a2f52 #2e2350 #5b4a8f #7b5ea7 #e8e2d4 #8a8a92 #c9a06a #8a6440 #c9a227 #8f2f2f #7a9a6a
Setting: one endless theatre; a fake city inside it, painted facades on wooden easels, papier-mache trees with visible wire frames, purple plank streets, worn velvet, painted canvas sky. Dusty, melancholic, sinister, obviously fake.
Never: text, letters, numbers, watermark, signature, UI, frame, border, drop shadow, photorealism, 3D, anime, chibi.
Portrait, head and shoulders, facing the viewer, framed like a theatre playbill. Strong single light from the upper left, deep violet #2e2350 behind. The mask is the focal point of the image: it must be readable at a glance and look like it can no longer be taken off, too tight, stuck to the skin, part of the face.
A glamorous leading lady, elegant and exhausted. A rich dark velvet gown #8f2f2f with worn gold #c9a227 jewellery and a heavy feathered headdress. Perfect posture, chin raised, the smile of someone who has performed it a thousand times. Her mask is a beautiful gilded mask in worn gold #c9a227, covered in thousands of tiny hand-written signatures scratched into the gold, now illegible. Through the mask's eye holes you can just see that she is tired.
```

### 18 · BOSS IV — IL CARCERIERE — `1431 caratteri`

> *"Se ti lascio uscire, mi tolgono la parte."*

```
Pixel art 16-bit, strict pixel grid, no antialiasing, no blur. Outline 1px #3a2f52, never black. Flat colours, light from upper left, one shade step, one highlight step, max 20 colours.
Palette, these only: #3a2f52 #2e2350 #5b4a8f #7b5ea7 #e8e2d4 #8a8a92 #c9a06a #8a6440 #c9a227 #8f2f2f #7a9a6a
Setting: one endless theatre; a fake city inside it, painted facades on wooden easels, papier-mache trees with visible wire frames, purple plank streets, worn velvet, painted canvas sky. Dusty, melancholic, sinister, obviously fake.
Never: text, letters, numbers, watermark, signature, UI, frame, border, drop shadow, photorealism, 3D, anime, chibi.
Portrait, head and shoulders, facing the viewer, framed like a theatre playbill. Strong single light from the upper left, deep violet #2e2350 behind. The mask is the focal point of the image: it must be readable at a glance and look like it can no longer be taken off, too tight, stuck to the skin, part of the face.
A prison guard who used to be a performer. Institutional and heavy: a buttoned-up dark uniform with sick green #7a9a6a piping and a brass #c9a227 belt buckle, perfectly pressed. Broad and square, hands clasped in front. His mask is shaped like an iron keyhole: a heavy dark metal plate with a keyhole cut through the middle, bolted onto the face. Bureaucratic, uncomfortable, never removed. No cruelty in the posture, only duty. He is not evil: he simply accepted.
```

### 19 · BOSS V — L'ULTIMO — `1406 caratteri`

> *"Non puoi uscire da solo. E io non riesco. Quindi restiamo."*

```
Pixel art 16-bit, strict pixel grid, no antialiasing, no blur. Outline 1px #3a2f52, never black. Flat colours, light from upper left, one shade step, one highlight step, max 20 colours.
Palette, these only: #3a2f52 #2e2350 #5b4a8f #7b5ea7 #e8e2d4 #8a8a92 #c9a06a #8a6440 #c9a227 #8f2f2f #7a9a6a
Setting: one endless theatre; a fake city inside it, painted facades on wooden easels, papier-mache trees with visible wire frames, purple plank streets, worn velvet, painted canvas sky. Dusty, melancholic, sinister, obviously fake.
Never: text, letters, numbers, watermark, signature, UI, frame, border, drop shadow, photorealism, 3D, anime, chibi.
Portrait, head and shoulders, facing the viewer, framed like a theatre playbill. Strong single light from the upper left, deep violet #2e2350 behind. The mask is the focal point of the image: it must be readable at a glance and look like it can no longer be taken off, too tight, stuck to the skin, part of the face.
The last one. He reached the door and stopped there. A performer under a huge impossible STACK of masks worn one over the other: four or five masks of different shapes, sizes and colours (gold, red, pale, green, metal), layered unevenly, one pushed aside, one slipping off, none removable. Under the many masks, a normal tired human jaw and neck. Stooped, patient, not aggressive. Not a monster: lonely, and he does not want to stay alone.
```

---

## 5 · Maschere

### 20 · LE NOVE MASCHERE — `1699 caratteri`

**Il prompt più lungo della libreria**, ma ci sta con 301 caratteri di margine.
Le quattro base e le cinque dei boss in **una sola generazione**: se le chiedi
una per volta ottieni nove stili diversi.

> Questo è un asset da **icone**, non un personaggio: se PixelLab ha una
> sezione per le icone o per gli oggetti, usala. Altrimenti va bene anche qui.

```
Pixel art 16-bit, strict pixel grid, no antialiasing, no blur. Outline 1px #3a2f52, never black. Flat colours, light from upper left, one shade step, one highlight step, max 20 colours.
Palette, these only: #3a2f52 #2e2350 #5b4a8f #7b5ea7 #e8e2d4 #8a8a92 #c9a06a #8a6440 #c9a227 #8f2f2f #7a9a6a
Setting: one endless theatre; a fake city inside it, painted facades on wooden easels, papier-mache trees with visible wire frames, purple plank streets, worn velvet, painted canvas sky. Dusty, melancholic, sinister, obviously fake.
Never: text, letters, numbers, watermark, signature, UI, frame, border, drop shadow, photorealism, 3D, anime, chibi.
Nine separate full-face theatre masks, front view, each centred in its own cell and readable as a silhouette when small. Bold simple shapes, no fine detail, two small string holes at the sides of each. 1 LA TRAGEDIA: frowning brow, mouth corners down, pale ivory. 2 LA COMMEDIA: wide open laughing mouth, eyes crinkled shut. 3 L'INGANNO: right half a smiling ivory mask, left half simply missing, showing empty violet void. 4 IL PRESAGIO: eyes closed, a third painted eye wide open on the forehead in worn gold #c9a227. 5 LA COMPARSA: a completely blank featureless pale mask, no expression, no holes, nothing: the absence is the point. 6 LO SPECCHIO: flat smooth violet glass #5b4a8f, one diagonal light streak, no features. 7 L'ESSERE AMATO: a beautiful gilded mask in worn gold #c9a227, covered in tiny illegible scratched markings like thousands of signatures. 8 IL DOVERE: a heavy dark metal mask shaped like a keyhole plate, with a keyhole cut through the middle. 9 TUTTE: five masks of different colours stacked unevenly on top of one another.
```

---

## 6 · Carte e ritratto

### 21 · IL DORSO DELLE CARTE — `997 caratteri`

Ne esiste **uno solo** nel gioco: la vedrai migliaia di volte.

```
Pixel art 16-bit, strict pixel grid, no antialiasing, no blur. Outline 1px #3a2f52, never black. Flat colours, light from upper left, one shade step, one highlight step, max 20 colours.
Palette, these only: #3a2f52 #2e2350 #5b4a8f #7b5ea7 #e8e2d4 #8a8a92 #c9a06a #8a6440 #c9a227 #8f2f2f #7a9a6a
Setting: one endless theatre; a fake city inside it, painted facades on wooden easels, papier-mache trees with visible wire frames, purple plank streets, worn velvet, painted canvas sky. Dusty, melancholic, sinister, obviously fake.
Never: text, letters, numbers, watermark, signature, UI, frame, border, drop shadow, photorealism, 3D, anime, chibi.
The back design of a playing card, portrait orientation, seen flat. A deep violet #4a2f7a field with a narrow worn gold #c9a227 inner border, and in the centre a single classic theatre mask motif in worn gold, symmetrical and slightly aged. Perfectly symmetrical left to right, and readable when the card is small on screen. Simple, bold, heraldic.
```

### 22 · L'ILLUSTRAZIONE DI UNA CARTA — `823 + oggetto`

Le carte sono tante: questo è un **modello**. Cambia solo la riga finale.

```
Pixel art 16-bit, strict pixel grid, no antialiasing, no blur. Outline 1px #3a2f52, never black. Flat colours, light from upper left, one shade step, one highlight step, max 20 colours.
Palette, these only: #3a2f52 #2e2350 #5b4a8f #7b5ea7 #e8e2d4 #8a8a92 #c9a06a #8a6440 #c9a227 #8f2f2f #7a9a6a
Setting: one endless theatre; a fake city inside it, painted facades on wooden easels, papier-mache trees with visible wire frames, purple plank streets, worn velvet, painted canvas sky. Dusty, melancholic, sinister, obviously fake.
Never: text, letters, numbers, watermark, signature, UI, frame, border, drop shadow, photorealism, 3D, anime, chibi.
A single object, centred and floating, with no scenery and no background of any kind. The object fills most of the frame with margin around it. Subject: QUI SCRIVI L'OGGETTO.
```

Esempi per la riga finale:

| Carta | Riga |
|---|---|
| Carta lanciata | `a single playing card caught mid-air, tumbling, motion implied` |
| Spada di scena | `a wooden stage sword, plain and blunt, resting diagonally` |
| Maschera rotta | `a cracked porcelain mask falling apart into three pieces` |
| Ventaglio | `a folded fan of playing cards, half open` |
| Corda | `a coil of dusty rope with a brass hook` |
| Fiala | `a small vial of violet stage smoke, spilling` |

### 23 · IL RITRATTO DEL PROTAGONISTA — `1103 caratteri`

Per le finestre di dialogo. **Ha il volto vuoto anche qui.**

```
Pixel art 16-bit, strict pixel grid, no antialiasing, no blur. Outline 1px #3a2f52, never black. Flat colours, light from upper left, one shade step, one highlight step, max 20 colours.
Palette, these only: #3a2f52 #2e2350 #5b4a8f #7b5ea7 #e8e2d4 #8a8a92 #c9a06a #8a6440 #c9a227 #8f2f2f #7a9a6a
Setting: one endless theatre; a fake city inside it, painted facades on wooden easels, papier-mache trees with visible wire frames, purple plank streets, worn velvet, painted canvas sky. Dusty, melancholic, sinister, obviously fake.
Never: text, letters, numbers, watermark, signature, UI, frame, border, drop shadow, photorealism, 3D, anime, chibi.
Portrait of the protagonist, head and shoulders, facing the viewer. Off-white stage costume #e8e2d4 with violet trim #7b5ea7 at the collar. The head is a smooth matte featureless oval, exactly like an unpainted mannequin head. NO eyes. NO mouth. NO nose. NO facial features. NO facial features. The blankness must be calm and neutral, never creepy and never hollow-eyed. Soft light from the upper left, with a faint suggestion of a violet curtain behind.
```

---

## 🖥️ Come usare PixelLab

**Onestà:** non posso verificare l'interfaccia, che cambia. Queste sono le voci
che contano e i valori giusti per il tuo progetto:

| Cosa | Valore |
|---|---|
| **Dimensione** | `64x64px`. Mai "auto" |
| **Direzioni** | `8 directions` |
| **Vista** | `low top-down view` |
| **Campo negativo** | Copia la riga `Never` del prompt |

### Come funziona il "Character"

Dalla tua schermata, il flusso è:

```
DESCRIZIONE (i prompt di questa libreria)
    ↓
STATO  "Idle"  ←  il tool genera lui le 8 direzioni
    ↓
ANIMAZIONI     ←  "+ Add Animation"
```

Quindi per un personaggio **non devi chiedere le direzioni**: le fa lui.
Il tuo lavoro è **descrivere bene chi è**, e questo lo fanno i prompt.

### ⚠️ Il passaggio che frega tutti

**Lo stato "Idle" è una posa, non un'animazione.** Le animazioni (camminata,
azione) sono un passo separato, con `+ Add Animation`.

- **Se PixelLab anima da solo:** usagli la sua funzione, partendo dallo stato
  `Idle`. Ti serve solo dire *che* animazione è (camminata, azione).
- **Se non ti convince:** dal `Idle` ricavi le pose a mano in Aseprite,
  spostando gambe e braccia di pochi pixel. Su un personaggio alto ~52 px è
  questione di minuti.

**Non cercare di ottenere 45 pose in una generazione sola:** il personaggio
cambierebbe 45 volte.

### Il problema che avevi con l'import

**Non è un tuo errore.** PixelLab non accetta il caricamento di file, quindi
non puoi dargli `MC2` come riferimento. Le conseguenze, che sono il motivo per
cui questa libreria è scritta così:

1. **Il Blocco Base è l'unico ancoraggio** che hai. Va incollato **identico** in
   ogni prompt. Non riassumerlo, non "sistemarlo".
2. **Genera il protagonista per primo**, poi tienilo aperto accanto agli altri.
   L'occhio nota subito uno stile fuori posto.
3. Se un risultato è **troppo poco dettagliato**, genera al doppio (celle da
   128) e riduci a metà in Aseprite con `nearest neighbor`. Il 2× è sempre
   pulito.

### Se un giorno vuoi l'ancoraggio vero allo stile

Ti serve un tool che **accetti immagini** — Retro Diffusion lo fa. Ma non è
obbligatorio: con questi prompt si arriva a un set coerente anche senza.

---

## 📥 Dopo la generazione

1. **Pulisci in Aseprite.** Allinea, cancella il fondo, togli le facce di
   troppo. Mezz'ora per foglio.
2. **Misura.** `64×64` deve essere `64×64`.
3. **Esporta** un PNG per animazione, `320×64` (5 celle da 64).
4. **Copia in** `Asset/Sprite/MySprite/MyCharacter/`.
5. **Lascia importare Godot.** La nitidezza è **già a posto**: in
   `project.godot` c'è `textures/canvas_textures/default_texture_filter=0`
   (`0` = Nearest). **Non toccare niente.**
6. **Crea le animazioni** in `Scene/Player/Player.tscn`, sul nodo
   `AnimatedSprite2D` → `SpriteFrames` → *"Aggiungi da sprite sheet"*, **5**
   frame orizzontali, `64×64`.

> **Il nome dell'animazione deve combaciare esattamente.** `player.gd` compone
> il nome unendo famiglia e direzione (`run` + `_` + `front`). Se chiami
> un'animazione `Run_Front` o `corsa`, il personaggio non si muove e **non esce
> nessun errore**. Silenzio totale.
>
> Nove nomi: `idle_front`, `idle_back`, `idle_right`, `run_front`, `run_back`,
> `run_right`, `pick_front`, `pick_back`, `pick_right`. **`left` non esiste:**
> è `right` specchiato.

---

## 🪤 Le trappole

### 1. Il campo si tronca a 2000 caratteri

Se il prompt è più lungo, **il tool taglia** — e taglia dall'inizio, quindi
perdi proprio lo stile. È quello che ti è successo. I conteggi sopra sono lì
per questo: se un prompt supera i 2000, non è "quasi giusto", è rotto.

### 2. Il volto vuoto diventa una faccia

Il protagonista non ha volto, ed è il senso della storia. L'IA insisterà:
nella tua prima prova **ha messo una faccia**. Combattilo così:

- nel testo c'è `NO facial features` **ripetuto**: non toglierne nessuna;
- nel campo negativo: `eyes, mouth, nose, face, facial features, expression`;
- se dopo tre tentativi insiste, **genera con la faccia e cancellala tu** in
  Aseprite. È più veloce che litigarci.

### 3. Il personaggio cambia fra una generazione e l'altra

Se generi lo stesso personaggio due volte, ottieni due persone diverse. Per
questo **il Blocco Base è identico in ogni prompt**: è l'unica cosa che li tiene
insieme.

### 4. La prospettiva cambia fra un asset e l'altro

Un albero di fianco e una casa dall'alto, nello stesso set, si vedono subito
come sbagliati. Metti i due sprite **affiancati** e guardali prima di andare
avanti.

### 5. Il fondo non è trasparente

Esce spesso **bianco** o **a scacchi** (l'IA disegna la trasparenza come un
motivo). In Aseprite si cancella in un comando — ma **non** usarlo così com'è in
Godot, o avrai un rettangolo bianco dietro ogni sprite.

### 6. Le dimensioni non sono quelle che hai chiesto

"64x64" per un'IA è un suggerimento, non un vincolo. **Misura sempre** prima di
importare, e ridimensiona in Aseprite con `nearest neighbor` — **mai** con
l'interpolazione normale, che sfuoca e distrugge la pixel art.

### 7. Le lettere vengono sbagliate

Per questo il prompt dice `Never: text` e per questo la **porta EXIT si genera
senza scritta**. Ogni parola che vedi in un'immagine generata è da rifare a
mano.

---

## 🎬 Da dove cominciare

1. Genera **una** cosa: il **protagonista** (prompt 1, 1119 caratteri).
2. Guarda lo stato `Idle`. **Il volto è vuoto?** Se ha una faccia, rigenera.
3. Aggiungi **una** animazione di camminata con `+ Add Animation`.
4. Esporta, pulisci in Aseprite, importa e **guardalo camminare** in
   `Scene/Main.tscn`.
5. Solo se il passo 4 ti convince, prosegui con il resto della libreria.

Un'animazione fatta per intero, bene, ti dice più di venti generazioni a caso —
e ti fa scoprire **adesso** quali righe del Blocco Base vanno corrette, invece
che dopo averne prodotte quaranta.
