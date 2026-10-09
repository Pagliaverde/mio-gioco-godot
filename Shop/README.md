# 🛒 Il Negozio

Comprare carte con le monete. Si apre **dal menu principale** e **dalla mappa**
(premi `E` davanti al banco).

---

## 📑 Indice

1. [Come si apre](#-come-si-apre)
2. [Il banco sulla mappa](#-il-banco-sulla-mappa)
3. [Le monete](#-le-monete)
4. [I prezzi](#-i-prezzi)
5. [I file](#-i-file)
6. [Cosa manca](#-cosa-manca)

---

## 🚪 Come si apre

**Due modi, lo stesso negozio:**

| Da dove | Come | Come si chiude |
|---|---|---|
| **Menu principale** | la carta "Negozio" | "Torna al menu" |
| **Mappa** | premi `E` davanti al banco | "Chiudi", e riprendi a camminare |

Premi **Esc** per chiudere: prima i dettagli di una carta, se sono aperti, poi
il negozio.

Nel secondo caso il gioco **si ferma** mentre il negozio è aperto: il
personaggio non cammina, gli NPC non si muovono. Funziona come il menu di pausa.

> **Esc è disattivato** finché il negozio è aperto: altrimenti aprirebbe il menu
> di pausa *sopra* al negozio, e ti ritroveresti due menu sovrapposti.

---

## 🔍 Leggere una carta

Le carte in vetrina sono larghe 190 pixel, quindi il loro testo è di 13: basta
per **riconoscerle**, non per **decidere** se comprarle. Per quello si clicca:

**Clic sulla carta** → si apre una scheda con

- la carta **grande**, con il testo ingrandito di 1,5 volte;
- **Elemento**, **Costo** e **Rarità** in chiaro;
- la **descrizione per esteso**, senza tagli;
- il **prezzo** e il pulsante per comprare, così non devi chiudere per comprare.

Si chiude con **Chiudi**, cliccando fuori dalla scheda, o con **Esc**.

---

## 🧍 Il banco sulla mappa

Il banco è `Shop/shop_stall.tscn`: **una zona invisibile** con il riquadro `E`
sopra. Non ha uno sprite, perché va appoggiata sopra alla bottega che hai già
disegnato nella mappa.

**Dov'è adesso:** in `Scene/Main.tscn`, vicino al punto di partenza
(`position = Vector2(238, 850)`), così puoi provarlo subito.

**Per spostarlo:** apri `Scene/Main.tscn`, seleziona `ShopBooth` nel pannello
Scena e trascinalo sopra la tua bottega. Oppure cambia a mano la `position`.
Funziona come un NPC: dove lo metti, lì appare il riquadro `E`.

**Quanto è grande la zona:** il rettangolo è `160x120`. Il personaggio è alto
256 (sprite da 64 con scala 4), quindi la zona copre il passo davanti alla
porta. Se ti sembra troppo stretta o troppo larga, cambia
`CollisionShape2D > shape > size` nel pannello Scena.

### Serve altro per farlo funzionare?

**No.** Il banco usa lo stesso sistema degli NPC, che è già in piedi:

```
Player (InteractionArea, mask 2)
    ↓  cerca aree nel gruppo "interactable"
ShopBooth (InteractionArea, layer 2, gruppo "interactable")
    ↓  il player chiama interact()
ShopScreen.open_over()   ← il negozio
```

Quindi non devi toccare né il player né la mappa: **è già collegato**.

---

## 💰 Le monete

Stanno in `user://wallet.cfg`, gestite da `Shop/shop_wallet.gd`.

| Cosa | Quanto | Dove |
|---|---|---|
| **Monete di partenza** | 300, **una volta sola** | `ShopCatalog.STARTING_COINS` |
| **Guadagno per una vittoria** | 90 (non ancora collegato) | `ShopCatalog.WIN_PAYOUT` |

### Come si guadagnano adesso

**Non si guadagnano.** La prima volta che apri il negozio ricevi 300 monete e
basta: servono a provarlo. La mappa non ha ancora un modo per vincere qualcosa,
quindi non c'è niente che paghi.

### Come collegarle a una vittoria

Quando avrai un punto dove si vince (un boss, un combattimento, un obiettivo),
aggiungi **una riga** lì:

```gdscript
ShopWallet.add_coins(ShopCatalog.WIN_PAYOUT)
```

Per pagare diversamente a seconda di quanto è difficile:

```gdscript
ShopWallet.add_coins(ShopCatalog.WIN_PAYOUT * difficolta)
```

E per dare monete all'inizio di una partita nuova:

```gdscript
ShopWallet.add_coins(200)
```

### Cosa NON fare

**Non chiamare `ensure_started()` per regalare monete.** Quella serve solo a
creare il portafoglio la prima volta: se chiamata quando il file esiste già non
fa niente, quindi come "bonus" non funziona. Per regalare monete usa
`add_coins()`.

### Ripartire da zero (per i test)

```gdscript
ShopWallet.reset()   # azzera monete e carte comprate
```

Oppure cancella il file `user://wallet.cfg` a mano.

---

## 💵 I prezzi

Il prezzo lo decide **la rarità**, non la singola carta. Così i numeri stanno in
una tabella sola e non c'è niente da aggiornare quando aggiungi una carta.

| Rarità | Base | Esempio |
|---|---|---|
| Base | 60 | Braci (18 mana) → **96** |
| Rara | 120 | Tormenta → **164** |
| Epica | 220 | Inferno → **256** |
| Leggendaria | 380 | Conflagrazione → **408** |
| Unica | 600 | — |

Al totale si aggiunge `2 × costo in mana`: una carta da più mana è più forte, e
pagarla quanto una da poco non avrebbe senso.

**Non è una scala inventata:** la rarità *è già* il modello di potenza del gioco
(vedi `Cards/data/rarity_profile.gd`). Una leggendaria rende di più e costa meno
mana, quindi vale di più. Il negozio usa la scala che c'è già.

**Per ribilanciare il negozio** cambia solo `BASE_PRICE` in `Shop/shop_catalog.gd`.

### Cosa finisce in vendita

**Tutte le carte di `CardDatabase`.** Se aggiungi una carta al gioco, compare in
negozio da sola: non c'è una lista da tenere aggiornata.

Le carte che possiedi restano in vetrina, col pulsante "Acquistata" spento.
Vederle è mezza la soddisfazione di comprarle, e così il negozio non cambia
forma sotto gli occhi del giocatore.

---

## 🗂 I file

```
Shop/
├── shop.tscn          # la schermata (solo lo script: tutto in codice)
├── shop.gd            # ShopScreen — la vetrina, i prezzi, l'acquisto
├── shop_art.gd        # ShopArt — la moneta e il festone, disegnati a pixel
├── shop_catalog.gd    # ShopCatalog — prezzi, monete, cosa è in vendita
├── shop_wallet.gd     # ShopWallet — monete e carte comprate (user://wallet.cfg)
├── shop_stall.tscn    # il banco da mettere sulla mappa
└── shop_stall.gd      # ShopBooth — la zona interattiva
```

**Chi fa cosa:** `ShopWallet` ricorda, `ShopCatalog` decide i numeri,
`ShopArt` disegna, `ShopScreen` mostra. Nessuno dei quattro conosce gli altri
più di tanto, e nessuno sa niente delle regole delle carte.

### Perché i disegni sono in codice

`ShopArt` disegna la moneta e il festone **a pixel**, non da PNG. È quello che
fa già il resto del gioco (`MenuCardArt` per le carte del menu,
`CardArtPainter` per le illustrazioni). Il vantaggio concreto: l'icona **segue i
colori del tema**, quindi se il giocatore cambia tavolozza nelle impostazioni
cambia anche lei. Un PNG resterebbe del colore sbagliato.

La moneta è una **matrice di caratteri** di 12×12, come gli emblemi del menu:
si legge a colpo d'occhio e si corregge in un secondo. Se vuoi cambiarne il
disegno, modifica `ShopArt.COIN`: `o` è il contorno, `#` l'oro scuro, `g` l'oro,
`l` la luce.

### `CardView.font_scale`

Per la scheda grande c'è un problema: in `CardView` le misure del testo sono
**fisse** (13, 17, 18), quindi ingrandire la carta ingrandirebbe solo la
cornice, lasciando il testo minuscolo.

La soluzione è `font_scale`: un moltiplicatore **spento di default** (`1.0`).
Dove la carta è già della misura giusta — la battaglia, a 240 pixel — non cambia
niente. La scheda dei dettagli lo porta a `1.5` e il testo cresce con la carta.

### L'aspetto della schermata

| Elemento | Da dove viene |
|---|---|
| Velo scuro e pannello bordato | lo stesso schema delle **Impostazioni** |
| Titolo | variante di tema `TitleLabel` |
| Borsa col saldo | variante `CardPanel` + la moneta disegnata |
| Festone della bancarella | `ShopArt.valance()` |
| Intestazioni dei gruppi | variante `SectionLabel` + la barretta del colore della rarità |
| Le carte | `CardView`, **le stesse della battaglia** |

Quindi il negozio **non ha uno stile suo**: usa il tema del gioco. Se cambi
tema o font nelle impostazioni, il negozio segue senza toccare niente.

---

## 🗺 Cosa manca

| Cosa | Dove |
|---|---|
| **Monete dai combattimenti** | una riga `ShopWallet.add_coins(...)` dove si vince |
| **Pacchetti** | le rarità e i pesi (`drop_weight`) esistono già in `RarityTable` |
| **Filtri e ricerca** | `CardDatabase.search()` e `by_element()` sono pronti |
| **"Possedute" nel mazzo** | oggi `ShopWallet` registra l'acquisto, ma `DeckData` non lo legge ancora |
| **Saldo anche in partita** | le monete stanno fuori da `SaveGame`: sono permanenti, non si azzerano ricaricando |
