# Ambiente di Sviluppo WildFly - Guida per Sviluppatori Frontend

Questo documento contiene tutte le istruzioni necessarie per avviare e gestire l'ambiente di sviluppo con WildFly 23.0.2 e Java 11.

## Requisiti

### Opzione 1: Docker Desktop su Windows (Consigliato)
- **Windows 10 Pro/Enterprise o Windows 11**
- **RAM**: almeno 4GB disponibili
- **Spazio disco**: almeno 5GB

### Opzione 2: WSL2 + Docker su Windows
- **Windows 10 build 19041+ o Windows 11**
- **RAM**: almeno 4GB disponibili
- **Spazio disco**: almeno 10GB (WSL2 + Docker + immagini)

---

## Installazione

### Se hai già Docker Desktop installato

Salta direttamente a [Avviare l'Ambiente](#avviare-lambiente).

### Installazione di WSL2 + Docker

Se non hai Docker Desktop o preferisci usare WSL2, segui questi passi:

#### Step 1: Installare WSL2

1. Apri **PowerShell come Amministratore**
2. Esegui:
   ```powershell
   wsl --install
   ```
   Questo installerà WSL2 e Ubuntu di default.

3. **Riavvia il computer** quando richiesto

4. Dopo il riavvio, apri **Windows Terminal** e seleziona **Ubuntu**

5. Imposta una password per l'utente Ubuntu quando richiesto

#### Step 2: Aggiornare WSL2

Nel terminale Ubuntu, esegui:
```bash
sudo apt update && sudo apt upgrade -y
```

#### Step 3: Installare Docker in WSL2

Nel terminale Ubuntu, esegui:
```bash
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io
```

#### Step 4: Configurare Docker (opzionale, per evitare `sudo`)

```bash
sudo usermod -aG docker $USER
newgrp docker
```

#### Step 5: Installare Docker Compose

```bash
sudo apt install -y docker-compose
```

#### Step 6: Avviare il servizio Docker

```bash
sudo service docker start
```

**Verifica che tutto sia installato:**
```bash
docker --version
docker-compose --version
```

---

## Avviare l'Ambiente

### 1. Navigare alla directory del progetto

**Su Windows (CMD o PowerShell):**
```cmd
wsl
cd /home/masanson/projects/WA03631-IscrizioneAziendaPubblicaWeb/docker-configuration
```

**O direttamente in WSL/Linux:**
```bash
cd /home/masanson/projects/WA03631-IscrizioneAziendaPubblicaWeb/docker-configuration
```

### 2. Avviare i container

```bash
docker-compose up -d
```

Questo comando:
- Costruisce l'immagine Docker (se non esiste)
- Avvia il container in background
- Espone le porte 8080 (applicazione) e 9990 (console admin)

### 3. Verificare che il container sia in esecuzione

```bash
docker-compose ps
```

Dovresti vedere:
```
NAME        COMMAND                 STATUS
wildfly-dev "/__cacert_entrypoin…"  Up X seconds
```

### 4. Visualizzare i log

```bash
docker-compose logs -f
```

Aspetta finché non vedi:
```
WFLYSRV0025: WildFly Full 23.0.2.Final started
```

Premi `Ctrl+C` per uscire dai log.

### 5. Accedere all'applicazione

- **Applicazione**: http://localhost:8080
- **Console Amministrazione WildFly**: http://localhost:9990

---

## Fermare l'Ambiente

### Fermare il container (mantenendo i dati)

```bash
docker-compose stop
```

### Fermare e rimuovere il container

```bash
docker-compose down
```

### Fermare e rimuovere tutto (inclusi volumi)

```bash
docker-compose down -v
```

---

## Aggiornare il File EAR

Se aggiorni il file dell'applicazione (`ear/IscrizioneAziendaPubblicaWeb.ear`):

### Metodo 1: Ricostruire l'immagine (Consigliato)

```bash
# Ferma il container
docker-compose down

# Ricostruisci l'immagine con il nuovo EAR
docker-compose build --no-cache

# Avvia il nuovo container
docker-compose up -d
```

### Metodo 2: Aggiornamento veloce (senza ricostruire)

Se vuoi aggiornare solo l'EAR senza ricostruire l'intera immagine:

```bash
# Copia il nuovo EAR nella cartella deployments del container
docker cp ./ear/IscrizioneAziendaPubblicaWeb.ear wildfly-dev:/opt/wildfly/standalone/deployments/

# WildFly ricaricherà automaticamente l'applicazione (attendi 30 secondi)
```

**Verifica il deploy:**
```bash
docker-compose logs -f | grep -E "(deployment|ERROR)"
```

---

## Aggiornare il File di Configurazione (config.properties)

Se modifichi il file `config/config.properties`:

### Metodo 1: Ricostruire l'immagine (Consigliato)

```bash
# Ferma il container
docker-compose down

# Ricostruisci l'immagine
docker-compose build --no-cache

# Avvia il nuovo container
docker-compose up -d
```

### Metodo 2: Aggiornamento veloce (senza ricostruire)

Se vuoi aggiornare solo il config.properties:

```bash
# Copia il nuovo file nel container
docker cp ./config/config.properties wildfly-dev:/opt/wildfly/modules/IscrizioneAziendaPubblicaWeb/

# Riavvia l'applicazione (facoltativo, a seconda di come l'app carica il file)
docker-compose restart
```

---

## Comandi Utili

### Visualizzare i log in tempo reale
```bash
docker-compose logs -f
```

### Visualizzare i log con filtro
```bash
docker-compose logs -f | grep -E "ERROR|Exception"
```

### Entrare nel container (shell interattiva)
```bash
docker-compose exec wildfly bash
```

### Verificare le cartelle nel container
```bash
docker exec wildfly-dev ls -la /opt/wildfly/modules/IscrizioneAziendaPubblicaWeb/
docker exec wildfly-dev ls -la /opt/wildfly/standalone/deployments/
```

### Visualizzare il file config.properties nel container
```bash
docker exec wildfly-dev cat /opt/wildfly/modules/IscrizioneAziendaPubblicaWeb/config.properties
```

### Copiare un file dal container al computer locale
```bash
docker cp wildfly-dev:/opt/wildfly/standalone/log/server.log ./server.log
```

### Riavviare il container
```bash
docker-compose restart
```

### Rimuovere l'immagine (per liberare spazio)
```bash
docker rmi podman-configuration-wildfly
```

---

## Troubleshooting

### Errore: "Port 8080 is already in use"

La porta 8080 è già occupata da un altro processo.

**Soluzione 1:** Ferma il container precedente
```bash
docker-compose down
```

**Soluzione 2:** Usa una porta diversa modificando `docker-compose.yml`
```yaml
ports:
  - "8081:8080"  # Cambia la porta da 8080 a 8081
  - "9990:9990"
```

Poi accedi con: http://localhost:8081

### Errore: "Docker daemon is not running"

Il servizio Docker non è avviato.

**Soluzione:**
```bash
# Su WSL2/Linux
sudo service docker start

# Su Docker Desktop
Apri Docker Desktop
```

### Container non si avvia

```bash
# Verifica i log di errore
docker-compose logs

# Se l'immagine è corrotta, ricostruiscila
docker-compose build --no-cache
docker-compose up -d
```

### File config.properties non viene caricato

Assicurati che il file esista nel container:
```bash
docker exec wildfly-dev ls -la /opt/wildfly/modules/IscrizioneAziendaPubblicaWeb/
```

Se il file non è presente, ricostruisci l'immagine:
```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

---

## Struttura delle Cartelle nel Container

```
/opt/wildfly/
├── standalone/
│   ├── deployments/           # EAR deployato qui
│   │   └── IscrizioneAziendaPubblicaWeb.ear
│   ├── configuration/         # Configurazioni WildFly
│   │   └── standalone.xml
│   └── log/                   # Log dell'applicazione
├── modules/
│   ├── IscrizioneAziendaPubblicaWeb/  # Configurazioni app
│   │   └── config.properties
│   └── inps/passi/main/               # Modulo custom
│       ├── passi.jar
│       └── module.xml
└── truststore/
    └── truststore.jks         # Certificati SSL
```

---

## Informazioni Utili

- **Java Version**: 11 (OpenJDK)
- **WildFly Version**: 23.0.2.Final
- **Container Name**: wildfly-dev
- **Porta HTTP**: 8080
- **Porta Amministrazione**: 9990
- **Porta HTTPS**: 8443

---

## Supporto

Per problemi o domande, contatta il team di sviluppo backend.
