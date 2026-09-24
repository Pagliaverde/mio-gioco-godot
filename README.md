# Imposta il tuo nome utente
git config --global user.name "IlTuoNome"

# Imposta la tua email (usare la stessa di GitHub)
git config --global user.email "la_tua_email@esempio.com"

# Opzione A: Crea un nuovo repository Git nella cartella corrente
git init

# Opzione B: Scarica un progetto già esistente da GitHub sul tuo PC
git clone https://github.com/Pagliaverde/mio-gioco-godot.git

# Collega la cartella locale al repository di GitHub
git remote add origin https://github.com/Pagliaverde/mio-gioco-godot.git

# Rinomina il ramo principale in "main"
git branch -M main

# Controlla l'URL remoto a cui sei collegato
git remote -v

# 1. Mette in preparazione (stage) TUTTI i file modificati/creati
git add .

# (Alternativa) Mette in preparazione solo un file specifico
git add nome_file.gd

# 2. Crea un punto di salvataggio locale con un messaggio descrittivo
git commit -m "Messaggio che spiega le modifiche"

# 3. Invia i commit locali al server di GitHub
git push

# Nota: Se è la primissima volta che pushi un nuovo ramo:
git push -u origin main

# Scarica ed unisce le ultime modifiche presenti su GitHub nel tuo codice locale
git pull

# Mostra lo stato attuale (file modificati, file non tracciati, commit pronti)
git status

# Mostra la cronologia di tutti i commit effettuati
git log

# Mostra la cronologia sintetica (un solo rigo per commit)
git log --oneline

# Elenca tutti i branch locali
git branch

# Crea un nuovo branch
git branch nome-branch

# Passa a un altro branch
git checkout nome-branch

# Crea e passa a un nuovo branch in un unico comando
git checkout -b nome-branch

# Unisci il lavoro del branch corrente con un altro (es. da main)
git merge nome-branch

# Annulla le modifiche non ancora aggiunte con "git add" su un file specifico
git checkout -- nome_file.gd

# Rimuove un file dall'area di staging (annulla il "git add .") lasciando il file modificato
git reset

# Annulla l'ultimo commit mantenendo però le modifiche ai file nel tuo editor
git reset --soft HEAD~1

# ATTENZIONE: Annulla l'ultimo commit e CANCELLA tutte le modifiche fatte ai file
git reset --hard HEAD~1
