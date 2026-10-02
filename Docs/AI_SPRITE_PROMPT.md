# 🎨 Il Font per l'IA — Sprite di *Fuori Copione*

> ## ⚠️ I PROMPT DA COPIARE SONO ALTROVE
>
> Questo documento spiega **perché** le cose vanno fatte in un certo modo
> (stile, formato, trappole, importazione).
>
> I **prompt già pronti da copiare**, uno per ogni asset, sono in
> **[`Docs/PROMPT_LIBRERIA.md`](PROMPT_LIBRERIA.md)**. Quello è il file da aprire
> quando devi generare. Questo è il file da leggere quando qualcosa non torna.
>
> Le sezioni su *Cosa hai già* e sul *riferimento immagine* sono state
> **aggiornate**: stai rifacendo tutto, e PixelLab non accetta immagini di
> riferimento. Vedi sotto.
>
> **E c'è un limite di 2000 caratteri** sul campo di PixelLab, che taglia
> dall'inizio se lo superi. I prompt misurati sono nella libreria: non
> allungarli a mano.

Tutto quello che devi dare a un'IA per farti generare gli sprite del gioco.

> **"Font" in questo documento significa due cose**, e sono entrambe qui:
> 1. il **blocco di stile** da incollare *identico* in ogni generazione (il "font", appunto);
> 2. il **formato** in cui farti consegnare gli sprite, cioè il foglio.

---

## Indice

1. [Cosa hai già](#cosa-hai-già)
2. [Come si usa](#come-si-usa)
3. [Il Font Base](#il-font-base)
4. [La tavolozza](#la-tavolozza)
5. [Le specifiche tecniche](#le-specifiche-tecniche)
6. [Le schede personaggio](#le-schede-personaggio)
7. [Gli asset, in ordine di lavoro](#gli-asset-in-ordine-di-lavoro)
8. [Quale IA usare](#quale-ia-usare)
9. [Le trappole](#le-trappole)
10. [Importare in Godot](#importare-in-godot)
11. [Il workflow realistico](#il-workflow-realistico)

---

## Cosa hai già (e cosa stai rifacendo)

Nel progetto c'è già un'identità visiva. **Stai rifacendo tutto**, quindi quei
file **non sono più la destinazione**: sono il tuo metro di paragone.

| Cosa | Dove | A cosa ti serve adesso |
|---|---|---|
| **La palette** | `Palette/MC_Palette.aseprite` | Da qui vengono i colori della tavolozza nella libreria |
| **Il manichino** | `MyCharacter/Manichino/` | Guardalo per le proporzioni del nuovo manichino |
| **Due protagonisti** | `MC/MC1_Real/` e `MC/MC2/` | Guarda le proporzioni: **il nuovo protagonista deve somigliargli** |
| **I fogli di animazione** | `MyCharacter/MC/MC2/` | 9 fogli già fatti: sono il **formato di riferimento**, non il risultato finale |

**Perché rigenerare anche il protagonista:** il blocco di stile traduce a
parole quello che `MC2` fa già a pixel. Se tenessi `MC2` e generassi il resto
nuovo, ti ritroveresti **due stili** che non si parlano. Rigenerando tutto dalla
stessa descrizione, il set nasce già coerente.

> **Tieni `MC2` aperto accanto** mentre generi: è il tuo controllo a occhio.
> Non è un riferimento da caricare (non si può), è un campione da guardare.

### E sappi anche questo

Che i sorgenti siano `.aseprite` significa che **lavori già in Aseprite**: è il
posto giusto. Il flusso con l'IA non lo sostituisce, lo alimenta — vedi
[Il workflow realistico](#il-workflow-realistico).

---

## Come si usa

**Tre blocchi, sempre insieme.** Ogni volta che chiedi qualcosa a un'IA, incolli:

```
[FONT BASE]      ← lo stile: sempre lo stesso, parola per parola
[SCHEDA]         ← chi è il soggetto, se è un personaggio
[RICHIESTA]      ← cosa vuoi in questa generazione specifica
```

Il **Font Base** non si tocca mai. È l'unica cosa che tiene insieme 40 generazioni
diverse: se cambi una parola, il gioco comincia a sembrare fatto da persone diverse.

---

## Il Font Base

**Va in inglese.** I modelli di immagini sono addestrati quasi tutti su prompt
inglesi: la stessa richiesta in italiano esce più povera e più incoerente. Il
documento è in italiano, i prompt no.

```
PIXEL ART SPRITE SHEET for a 2D top-down game. 16-bit era style, strict
pixel grid, 64x64 pixel frames, transparent background.

ART STYLE:
- Hand-placed pixel clusters only. No anti-aliasing, no soft gradients,
  no blur, no dithering except where explicitly stated.
- Every shape outlined in a single 1px dark line of a desaturated purple,
  not black.
- Limited palette: maximum 24 colours per sprite, flat fills with one
  shading step and one highlight step.
- Light comes from the upper left. Shadows fall to the lower right.
- Slight top-down three-quarter perspective, like classic SNES RPGs:
  you see the front of objects and a hint of their top.

SETTING:
The entire game takes place inside a single endless theatre. A fake city
has been built inside it.
- Buildings are flat painted facades held up by wooden easels; you can see
  the void and the scaffolding behind them.
- Trees are papier-mâché: the wire frame shows through the paint.
- Streets are purple wooden planks and worn velvet.
- The sky is a painted canvas backdrop with visible brush strokes.
- The mood is dusty, melancholic and slightly sinister. Beautiful, but
  clearly fake, and nobody in it seems to mind.

COLOUR IDENTITY:
Deep desaturated purple is the signature colour of the whole game. It gets
stronger and darker the closer the player gets to the end of the game.

Do NOT include: text, watermarks, signatures, UI elements, drop shadows
on the image itself, photorealism, 3D rendering, anime, chibi proportions,
gradients, glow effects, or a white background.
```

### Perché ogni riga è lì

| Riga | Cosa impedisce |
|---|---|
`Hand-placed pixel clusters only` | L'IA tende a fare un'illustrazione piccola ma **liscia**, non pixel art. Questa riga la costringe a pensare a pixel veri |
`1px dark line of a desaturated purple, not black` | Il nero puro è l'errore più comune e fa sembrare tutto un fumetto economico |
`maximum 24 colours` | Senza un limite l'IA spara 200 colori e perde l'aria pixel art |
`Light comes from the upper left` | Senza una regola fissa, ogni sprite è illuminato da un lato diverso e il set non sta insieme |
`three-quarter perspective` | Ti serve sapere se un albero si vede di fianco o leggermente dall'alto — e deve essere lo stesso per tutto |
`easels / wire frame shows through` | È il cuore visivo della tua storia. Senza, l'IA fa case normali e perdi il tema |
`purple is the signature` | Impedisce che il primo foglio esca verde e il secondo blu |
`Do NOT include: text...` | Le IA **adorano** mettere scritte e firme. Vanno vietate esplicitamente |

---

## La tavolozza

> ⚠️ **Prima leggi [Cosa hai già](#cosa-hai-già).** Se `MC_Palette.aseprite`
> contiene i tuoi colori, usa quelli. Questa tavolozza è il ripiego.

Dalla scheda di design: sette zone, **la stessa mappa con palette diverse**.
Questa è la nota di produzione più importante che hai, e vale la pena sfruttarla:
chiedi **un solo tileset** e poi lo ricolori, invece di chiedere sette ambienti.

| Zona | Colore guida | Uso |
|---|---|---|
| Il Camerino | `#8a8a92` grigio-polvere | Prologo |
| La Piazza Dipinta | `#7b5ea7` viola tenue | Boss I |
| La Galleria degli Specchi | `#5b6bb5` viola freddo | Boss II |
| Il Palco | `#c9a227` oro + `#8f2f2f` rosso | Boss III |
| I Corridoi | `#7a9a6a` verde malato | Boss IV |
| L'Auditorium | `#4a2f7a` viola pieno | Boss V |
| Il Fondo | quasi nero, con un filo di viola | Finale |

**La firma:** `#5b4a8f`. È il viola del gioco. Nelle richieste scrivi sempre
`signature purple #5b4a8f` e vedrai che il set resta coerente.

**Come si usa.** Nel Font Base la tavolozza è descritta a parole. Quando chiedi
un asset di una zona specifica, aggiungi la riga:

```
ZONE PALETTE: dusty grey #8a8a92 and grey-violet #6b6b8f, muted and cold.
```

---

## Le specifiche tecniche

### Il formato foglio per Godot

Il progetto **ha già una convenzione**, e va rispettata o dovrai rifare i nodi:

```
frame 64x64, striscia orizzontale, 5 frame per animazione
```

Lo vedi in `Scene/Player/Player.tscn`: ogni `AtlasTexture` ha
`region = Rect2(0, 0, 64, 64)`, poi `(64, 0, ...)`, `(128, 0, ...)` e così via
fino a 256. Cinque frame, affiancati, da sinistra a destra.

Quindi in ogni richiesta scrivi:

```
FORMAT: one horizontal strip, 5 frames of 64x64 pixels each, total image
320x64 pixels. The character must be perfectly identical in all 5 frames
except for the animation change. Frame 1 at x=0, frame 2 at x=64, frame 3
at x=128, frame 4 at x=192, frame 5 at x=256. No spaces, no padding, no
borders between frames. Character centred in each 64x64 cell with the feet
touching the bottom edge.
```

> **`feet touching the bottom edge` è la riga più importante di tutte.**
> Il progetto disegna ogni cosa con i piedi sulla cella, non col centro. Se
> l'IA centra il personaggio, nella mappa sembrerà che galleggi.

### Le nove animazioni

`Asset/Script/player.gd` documenta la convenzione:

| Famiglia | Cosa fa |
|---|---|
| `idle` | Fermo |
| `run` | In movimento |
| `pick` | Interagire (una volta sola) |

Per tre direzioni: `front`, `back`, `right`. **`left` non esiste:** il
personaggio che va a sinistra è `right` specchiato.

**Nove animazioni, nove fogli.** Ma vedi [Le trappole](#le-trappole): nove
generazioni separate è il modo peggiore di ottenerle.

### La misura dei personaggi

64×64 è la cella, **non** il personaggio. Se il personaggio riempie tutta la
cella, nella mappa sembrerà un gigante: il tileset è 64×64, quindi occuperebbe
un intero tassello di terreno solo per stare in piedi.

Regola da mettere nella richiesta:

```
The character occupies about 40x52 pixels of the 64x64 cell: a small figure
with empty space above the head and at the sides. Feet on the bottom edge.
```

Questo vale per il protagonista e per i manichini. **I boss no:** i boss sono
combattimenti a carte, quindi ti serve il **ritratto**, non lo sprite che
cammina. Vedi [Gli asset](#gli-asset-in-ordine-di-lavoro).

---

## Le schede personaggio

Il Font Base dice *come* si disegna. La scheda dice *chi* è. Va incollata sotto
il Font Base, **sempre identica** ogni volta che rigeneri lo stesso personaggio:
se cambi una parola, ottieni una persona diversa.

### Il Protagonista

```
CHARACTER: the protagonist. A figure with NO FACE and no identity: an empty
hooded performer's body, like an actor's understudy costume with nobody in it.
- Plain off-white stage costume with violet trim, slightly dusty and worn.
- The head is smooth and featureless, matte, like an unpainted mannequin head.
  NO eyes, NO mouth, NO face details of any kind.
- A small stack of mask shapes hangs at the belt, not worn.
- Slim, medium height, around 40x52 pixels inside the cell.
- Reads as innocent and slightly lost. Not threatening.
```

> **Il volto vuoto è la cosa più difficile da ottenere.** Le IA *vogliono*
> mettere una faccia: se non glielo vieti tre volte, te la mettono. Aggiungi
> in fondo alla richiesta: `The head must stay completely blank. No eyes.`

### I Manichini (il pubblico)

**Questi li stai rifacendo anche tu** (stai rifacendo tutto), ma hai un
vantaggio: `MyCharacter/Manichino/` contiene già `idle_front`, `idle_back` e
`idle_right` con i sorgenti `.aseprite`. **Aprilo accanto** mentre generi il
nuovo: è il metro per le proporzioni e per la posa.

**E ti manca una cosa che il vecchio set non ha:** il manichino **seduto**. Nella
platea un manichino in piedi sembra sbagliato, e l'Auditorium ne è pieno. Il
prompt per quello seduto è nella libreria.

Se vuoi generarli comunque per averne di più vari, la scheda da usare è questa:

```
CHARACTER: a theatre mannequin, one of the audience.
- Wooden artist's mannequin, pale unfinished wood, visible ball joints at
  shoulders, elbows, hips and knees.
- Completely motionless, standing straight, arms hanging.
- NO facial features: just a smooth blank wooden oval head.
- Generic and identical to all the others. There is nothing special about it.
- 64x64 sprite, occupying about 44x58 pixels, feet on the bottom edge.
```

Ti servono **due** sprite: uno di fronte e uno **girato di spalle**. Il momento
in cui si girano tutti insieme è la scena più forte del gioco e ti serve un solo
frame per farla.

### I cinque boss

I boss non camminano: sono **attori che recitano per il pubblico**. Ti serve un
**ritratto** per la schermata di battaglia, non un foglio di animazioni.

```
BOSS PORTRAIT: semi-realistic painted character portrait for a card battle
screen, in the same 16-bit pixel art style and palette as the sprites.
- Square, 256x256 pixels, transparent background.
- Head and shoulders, facing the viewer, framed like a theatre playbill.
- Strong single light from the upper left, deep violet background shadow.
- The mask this character wears is the focal point. It must be readable at
  a glance and clearly NOT removable.
```

Le cinque maschere, che sono **il soggetto vero** del ritratto:

| Boss | La maschera | La nota da scrivere |
|---|---|---|
| **I. La Comparsa** | Nessuna | `Bare face, no mask, tired and blank. The absence of a mask is the point.` |
| **II. Il Sostituto** | Il tuo volto | `Wears the protagonist's featureless white face as a mask. Creepy because it is the player's own.` |
| **III. La Prima Attrice** | L'Essere Amato | `A beautiful gilded mask, covered in tiny hand-written audience signatures.` |
| **IV. Il Carceriere** | Il Dovere | `A heavy iron keyhole-shaped mask, uniform-like, bureaucratic.` |
| **V. L'Ultimo** | Tutte | `Not one mask: a stack of many masks worn one over the other, uneven, impossible to remove.` |

> Ogni boss porta *una maschera che non si è più tolto*. Il ritratto deve farlo
> capire **senza una spiegazione**: la maschera deve sembrare incollata, troppo
> stretta, parte della faccia.

### Le maschere come oggetti

Ti servono anche come **oggetti da inventario**: piccole, leggibili, con una
silhouette riconoscibile a colpo d'occhio.

```
MASK ITEM ICON: a single theatre mask, front view, centred.
- 64x64 pixels, transparent background, no frame, no shadow.
- Fills about 52x40 pixels of the cell.
- Reads clearly as a silhouette even at 32x32: bold shape, simple details.
- Flat pixel art with one shading step, matching the sprite palette.
```

Le quattro base:
**La Tragedia** (fronte corrugata, bocca in giù), **La Commedia** (bocca
aperta in una risata, occhi socchiusi), **L'Inganno** (mezza maschera, l'altra
metà vuota), **Il Presagio** (occhi chiusi, un occhio dipinto sulla fronte).

---

## Gli asset, in ordine di lavoro

**Stai rifacendo tutto, protagonista compreso** (vedi
[Cosa hai già](#cosa-hai-già)). L'ordine qui sotto è quello in cui conviene
generare, non quello in cui il gioco ne ha bisogno.

> ## ⚠️ Questa sezione è cambiata
>
> Diceva: *"usa `MC2` come immagine di riferimento"*. **Non puoi farlo:**
> PixelLab non accetta il caricamento di file, e nella tua prova non ha
> funzionato.
>
> **La conseguenza è importante, quindi vale la pena ripeterla:** senza
> riferimento caricato, **il blocco di stile è l'unico ancoraggio** che hai. Va
> incollato parola per parola in **ogni** generazione, e il **foglio 3×3** non è
> un trucco opzionale: è il modo per far disegnare all'IA tutte le pose
> **dentro una sola generazione**, dove resta coerente da sola.
>
> I prompt già scritti così sono in
> **[`Docs/PROMPT_LIBRERIA.md`](PROMPT_LIBRERIA.md)**. Questa sezione resta per
> spiegare il *motivo*; non contiene prompt da copiare.
>
> **Se un giorno** ti servisse davvero l'ancoraggio allo stile, ti serve un tool
> che accetti immagini — Retro Diffusion lo fa. Ma non è obbligatorio per
> arrivare a un set coerente.

### 🥇 Priorità 1 — La mappa del teatro

**Uno solo, non sette.** Il documento di design lo dice: stessa mappa, palette
diverse. Chiedi un tileset neutro e ricoloralo.

```
TILESET: a 64x64 pixel tile set for a top-down game, on a strict grid.
Include, each as a clean 64x64 tile:
- purple wooden plank floor (2 variants)
- worn velvet floor (2 variants)
- painted canvas wall (2 variants, seamless, for tiling horizontally)
- stone step / kerb edge
- the base of a papier-mâché tree
- plain flat backdrop tile, mid purple (the void behind the facades)
Deliver as a single image, tiles in a regular grid, no gaps, no labels.
Neutral lighting only: no coloured light baked in, so the tiles can be
recoloured later.
```

Il ricolore lo fai poi in Godot con un `CanvasItemMaterial` o un piccolo
shader: **non chiedere sette tileset all'IA**, ti costerebbe sette volte il
lavoro e ti uscirebbero sette stili diversi.

### 🥈 Priorità 2 — Gli altri personaggi

**Tutti, protagonista compreso** (stai rifacendo tutto). Oltre a lui: il
manichino, gli NPC che riempiono il teatro, e i boss — che però non camminano,
quindi per loro vedi [I ritratti dei boss](#4--i-ritratti-dei-boss).

Per gli NPC la cosa che li rende memorabili è che **hanno una parte e la
recitano**: un venditore che è *solo* un venditore, un passante che ripete
sempre la stessa battuta. Nella scheda scrivi qual è la loro parte, e l'IA
tirerà fuori un costume di conseguenza.

### 🥉 Priorità 3 — Gli oggetti della scenografia

| Oggetto | Perché |
|---|---|
| Facciata su cavalletto | È il palazzo del gioco. Ti servono 3 varianti |
| Albero di cartapesta | Con la struttura in filo che si vede |
| Specchio (rotto / intero) | Camerino e Galleria |
| Baule di scena | Il "Bauli di Scena", dove trovi le maschere |
| Porta **EXIT** dipinta | Quella finta. Deve sembrare *vera ma piatta* |
| Poltrona del teatro | L'Auditorium ne è pieno: ne servono centinaia |

### 4 — I ritratti dei boss

Cinque ritratti. Puoi farli **dopo** aver collegato i combattimenti: prima
serve che i boss esistano come partite.

### 5 — Le icone delle maschere

Nove icone. Utili quando il sistema delle maschere sarà implementato.

---

## Quale IA usare

**Ordine di preferenza per il tuo caso**, con il motivo.

### 🥇 PixelLab (`pixellab.ai`)

Nato **solo** per la pixel art. È l'unico che ho in elenco che capisce
davvero la griglia: fa rotazione del personaggio, animazioni a partire da un
frame, e ti esporta i fogli con le celle allineate. Per un progetto come il tuo
— tanti sprite dello stesso personaggio in pose diverse — è quello che ti fa
risparmiare più tempo.

**Limite:** lo stile è più "indie generico" che autoriale. Ti darà un
personaggio pulito ma non necessariamente *il tuo*.

### 🥈 Retro Diffusion

Qualità dell'immagine statica più alta di PixelLab. Ha modelli dedicati alla
pixel art e alle icone di gioco. Ottimo per **ritratti e oggetti**. Più debole
sulle animazioni lunghe.

**Scelta giusta se:** ti importa più della bellezza del singolo disegno che
della comodità di produrne cinquanta.

### 🥉 Scenario (`scenario.com`)

Pensato per **set di asset coerenti**: addestra il modello sul *tuo* stile a
partire da pochi esempi. È la risposta al problema numero uno (la coerenza), ma
richiede che tu abbia già 5-10 sprite tuoi da mostrargli. Quindi: **non è il
primo passo, è il secondo**.

### Stable Diffusion in locale (con ControlNet + LoRA pixel art)

Controllo massimo, gratis, e puoi addestrare un LoRA **sul tuo personaggio** —
che è l'unico modo per avere il protagonista *identico* in novanta frame.
Costo: è una giornata di studio, non un pomeriggio.

**Consiglio onesto:** se il gioco ti prende, questo è dove finirai. Ma non
cominciare da qui.

### ❌ Le IA generiche (Midjourney, DALL·E, Firefly, Gemini)

**Da evitare per gli sprite.** Fanno *finta* di fare pixel art: il risultato è
bello da guardare ma **non è su una griglia**, i pixel non sono quadrati
quando ingrandisci, e le dimensioni non sono quelle che hai chiesto. Un
"64x64" da Midjourney non è 64×64.

**Però sono utili per una cosa:** chiedere loro **concept e direzione**
(`mood board`, palette, come potrebbe essere una maschera). Poi passi il
concept a un'IA specializzata.

> ⚠️ **Sui nomi e sulla loro qualità: le IA cambiano ogni pochi mesi.**
> Quelli sopra sono quelli che conosco e che hanno una specializzazione vera
> nella pixel art. Prima di pagare un abbonamento, prova il piano gratuito e
> guarda se il risultato è sulla griglia. Se non lo è, non è lo strumento
> giusto per te, qualunque cosa dicano le recensioni.

### E ti serve comunque Aseprite

`Aseprite` (o `LibreSprite`, gratis) non è un'IA: è il programma dove **pulisci**
quello che l'IA ha fatto. Non è opzionale — vedi sotto.

---

## Le trappole

Queste sono le cose che vanno **sempre** storte. Leggile prima, non dopo.

### 1. Nessuna IA produce un foglio allineato

Ti consegnerà un'immagine che *sembra* una striscia da 5 frame, ma:

- i frame non sono larghi esattamente 64 pixel;
- il personaggio si sposta di qualche pixel fra un frame e l'altro;
- l'immagine non è 320×64 ma 318×64 o 324×64.

**Non è un tuo errore, è come funzionano.** Il foglio va **sempre** ritagliato e
riallineato a mano in Aseprite. Metti in conto mezz'ora per animazione.

### 2. Il personaggio cambia fra una generazione e l'altra

Se chiedi nove animazioni in nove richieste separate, otterrai **nove
personaggi diversi**. Il colore del costume cambia, la cintura sparisce, la
testa diventa tonda.

**Su PixelLab questo problema non esiste**, ed è la cosa che rende il tool
adatto al tuo caso: dal **Character** descrivi il personaggio **una volta** e il
tool ne genera **tutte le 8 direzioni insieme**. Le pose aggiuntive le aggiungi
dopo, come *animazioni dello stesso personaggio* — non come nuove generazioni.

**Per gli asset che NON sono personaggi** (le nove maschere, per esempio) il
problema invece c'è, e la soluzione è chiedere **un solo foglio** con tutto
dentro:

```
Nine masks in ONE image, arranged in a 3x3 grid. Each cell is 64x64 pixels,
total image 192x192. All nine must share the same style, outline weight and
palette. Only the design of each mask changes.
```

Dentro **una sola** generazione l'IA è molto più coerente. Questo vale per
icone, oggetti e tileset — non per i personaggi, dove ci pensa il tool.

> ⚠️ **E occhio ai 2000 caratteri.** Il campo di PixelLab **taglia dall'inizio**
> se il prompt è troppo lungo, quindi perdi proprio il blocco di stile. Ogni
> prompt in `Docs/PROMPT_LIBRERIA.md` è misurato; non allungarli a mano.

### 3. Il volto vuoto diventa una faccia

Il protagonista non ha volto, ed è il punto della storia. L'IA insisterà per
mettergliene uno. Combattilo così:

- scrivi `NO facial features` **tre volte** in punti diversi della richiesta;
- nel negative prompt: `eyes, mouth, nose, face, facial features, expression`;
- se dopo tre tentativi insiste, **genera con una faccia e cancellala tu** in
  Aseprite. È più veloce che litigarci.

### 4. La prospettiva cambia fra un asset e l'altro

Un albero di fianco e una casa vista dall'alto, nello stesso set, si vedono
subito come sbagliati. Tieni sempre la stessa riga (`three-quarter top-down`) e
**controlla** guardando i due sprite affiancati prima di andare avanti.

### 5. Il fondo non è trasparente

Anche quando lo chiedi, spesso esce **bianco** o a **scacchi** (l'IA disegna
la trasparenza come un motivo). Non importa: in Aseprite si cancella in un
comando. Ma **non** provare a usarlo così com'è in Godot, o avrai un rettangolo
bianco dietro ogni sprite.

### 6. Le dimensioni non sono quelle che hai chiesto

"64x64" per un'IA è un suggerimento, non un vincolo. **Misura sempre** l'immagine
prima di importarla, e ridimensionala in Aseprite con *nearest neighbor* —
**mai** con l'interpolazione normale, che sfuoca tutto e distrugge la pixel art.

---

## Importare in Godot

Dopo aver pulito in Aseprite ed esportato i fogli (uno per animazione,
`320×64`, 5 frame):

**1. Copia i PNG** in `Asset/Sprite/MySprite/MyCharacter/MC/`.

**2. Lascia importare.** Godot li importa da solo.

**3. La nitidezza non si imposta sul file: è già a posto nel progetto.**

Godot importa le texture con un filtro di default, e per la pixel art va messo
su **nearest**, altrimenti tutto esce sfocato appena la telecamera si muove.

Nel tuo `project.godot` c'è già:

```ini
[rendering]

textures/canvas_textures/default_texture_filter=0
```

`0` è **Nearest**. Vale per tutte le texture del gioco, comprese quelle che
aggiungerai: **non devi toccare niente**, né nel `.import` né altrove.

> **Non cercare un parametro `filter` nei file `.import`:** non esiste, e se lo
> aggiungi a mano Godot lo ignora. La nitidezza in questo progetto è una
> impostazione unica e globale, ed è già corretta. Se un domani volessi
> sovrascriverla per una singola texture, in Godot 4 si fa sul **materiale** del
> nodo (`CanvasItemMaterial`), non nell'importazione.

**4. Crea le animazioni.** Apri `Scene/Player/Player.tscn`, seleziona
`AnimatedSprite2D`, e nel `SpriteFrames` aggiungi un'animazione per ogni foglio:

- Nome: `idle_front`, `run_front`, `pick_front`… (le nove di `player.gd`)
- Da foglio: scegli *"Aggiungi da sprite sheet"* e dai **5** come numero di
  frame orizzontali e **64×64** come dimensione. Godot ritaglia da solo.

**5. La velocità.** Un ciclo di camminata a 5 frame vuole circa `0.12` per
frame. Fermo (`idle`) sta bene più lento, `0.25`: è il respiro, non un
movimento.

> **Il nome dell'animazione deve combaciare esattamente.** `player.gd` compone
> il nome unendo famiglia e direzione (`run` + `_` + `front`): se chiami
> un'animazione `Run_Front` o `corsa`, il personaggio non si muove e **non esce
> nessun errore**. Silenzio totale. È il motivo per cui il codice scrive un
> avviso in console quando non trova un'animazione.

---

## Il workflow realistico

La parte che nessuno dice: **l'IA non ti consegna il gioco finito.** Il flusso
vero è questo, e vale la pena accettarlo subito.

```
   1. CONCEPT          →   un'IA generica (o tu) per capire cosa vuoi
        ↓
   2. GENERAZIONE      →   PixelLab / Retro Diffusion, con Font Base + Scheda
        ↓
   3. PULIZIA          →   Aseprite: ritagliare, allineare, cancellare il fondo,
        ↓                  togliere le facce di troppo, correggere le dimensioni
   4. VERIFICA         →   misurare: 320x64? 5 celle da 64? piedi in basso?
        ↓
   5. IMPORTO          →   Godot (nitidezza già impostata), SpriteFrames
        ↓
   6. PROVA            →   F6 e guarda se cammina bene
```

**Il passo 3 è quello che costa.** Metti in conto che per *ogni* foglio che l'IA
ti dà, ci vuole mezz'ora di Aseprite. Nove animazioni: una giornata.

**Non è tempo sprecato.** Un set di nove fogli puliti a mano vale più di
cinquanta fogli generati in fretta e mai allineati: i cinquanta non li userai
mai, perché nessuno cammina bene e ti passa la voglia.

### Da dove cominciare domani

1. Genera **una** cosa: il protagonista `idle_front`. Solo quello.
2. Puliscilo in Aseprite fino a farlo stare in 64×64 coi piedi in basso.
3. Importalo e **guardalo camminare in `Scene/Main.tscn`**.
4. Solo se il passo 3 ti convince, fai gli altri otto.

Fare un'animazione per intero, bene, ti dice più di venti generazioni a caso —
e ti fa scoprire *adesso* quali righe del Font Base vanno corrette, invece che
dopo averne prodotte quaranta.
