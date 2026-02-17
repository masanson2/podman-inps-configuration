# Guida alla Customizzazione dell'Ambiente Docker/Podman

Questa guida spiega come personalizzare questa configurazione Docker/Podman per altri progetti WildFly/JBoss.

## Indice

1. [Panoramica della Struttura](#panoramica-della-struttura)
2. [Personalizzare per un Nuovo Progetto](#personalizzare-per-un-nuovo-progetto)
3. [Modificare Versioni e Configurazioni](#modificare-versioni-e-configurazioni)
4. [Aggiungere Moduli e Librerie Custom](#aggiungere-moduli-e-librerie-custom)
5. [Configurare Multiple Istanze](#configurare-multiple-istanze)
6. [Best Practices](#best-practices)

---

## Panoramica della Struttura

```
docker-configuration/
├── Dockerfile                      # Definizione immagine Docker
├── docker-compose.yml              # Orchestrazione container
├── README.md                       # Guida utente per sviluppatori
├── CUSTOMIZATION_GUIDE.md         # Questa guida
├── config/
│   ├── standalone.xml             # Configurazione WildFly
│   └── config.properties          # Configurazioni applicazione
├── custom-libs/
│   ├── passi.jar                  # Librerie custom
│   └── module.xml                 # Definizione modulo WildFly
├── truststore/
│   └── truststore.jks             # Certificati SSL
└── ear/
    └── IscrizioneAziendaPubblicaWeb.ear  # Applicazione da deployare
```

### Funzione di ogni componente:

- **Dockerfile**: costruisce l'immagine con WildFly, Java, e tutte le dipendenze
- **docker-compose.yml**: configura network, porte, nomi container
- **config/standalone.xml**: configurazione server WildFly (datasources, porte, security)
- **config/config.properties**: configurazioni specifiche dell'applicazione
- **custom-libs/**: moduli Java custom da caricare in WildFly
- **truststore/**: certificati SSL per connessioni HTTPS
- **ear/**: file EAR dell'applicazione da deployare automaticamente

---

## Personalizzare per un Nuovo Progetto

### Step 1: Copiare la struttura

```bash
# Copia l'intera cartella docker-configuration
cp -r docker-configuration ../MIO_NUOVO_PROGETTO/docker-configuration
cd ../MIO_NUOVO_PROGETTO/docker-configuration
```

### Step 2: Sostituire il file EAR

```bash
# Rimuovi il vecchio EAR
rm ear/IscrizioneAziendaPubblicaWeb.ear

# Copia il tuo EAR
cp /path/to/MioProgetto.ear ear/

# Aggiorna il Dockerfile (riga 39)
# DA:  COPY ./ear/IscrizioneAziendaPubblicaWeb.ear ${WILDFLY_HOME}/standalone/deployments/
# A:   COPY ./ear/MioProgetto.ear ${WILDFLY_HOME}/standalone/deployments/
```

### Step 3: Aggiornare config.properties

Modifica `config/config.properties` con le configurazioni del tuo progetto:

```properties
# Esempio configurazioni
database.url=jdbc:postgresql://db-server:5432/miodb
database.user=mio_user
api.endpoint=https://api.example.com
```

Se il tuo progetto **non usa** config.properties, rimuovi dal Dockerfile:

```dockerfile
# RIMUOVI questa riga (riga 26)
# COPY ./config/config.properties ${WILDFLY_HOME}/modules/IscrizioneAziendaPubblicaWeb/
```

E rimuovi anche la creazione della directory (riga 21):

```dockerfile
# RIMUOVI o modifica con il nome del tuo modulo
# mkdir -p ${WILDFLY_HOME}/modules/IscrizioneAziendaPubblicaWeb
```

### Step 4: Personalizzare nomi container e network

Modifica `docker-compose.yml`:

```yaml
services:
  wildfly:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: mio-progetto-dev  # CAMBIA QUESTO
    ports:
      - "8080:8080"
      - "9990:9990"
    networks:
      - mio-progetto-network  # CAMBIA QUESTO

networks:
  mio-progetto-network:  # CAMBIA QUESTO
    driver: bridge
```

### Step 5: Aggiornare il README.md

Modifica il README.md per riflettere il nome del tuo progetto:

- Sostituisci tutti i riferimenti a `IscrizioneAziendaPubblicaWeb` con il tuo progetto
- Sostituisci `wildfly-dev` con il nome del tuo container
- Aggiorna i path specifici del progetto

---

## Modificare Versioni e Configurazioni

### Cambiare versione di Java

Modifica il `Dockerfile` (riga 2):

```dockerfile
# Per Java 17
FROM eclipse-temurin:17-jdk

# Per Java 11 (default)
FROM eclipse-temurin:11-jdk

# Per Java 8
FROM eclipse-temurin:8-jdk
```

### Cambiare versione di WildFly

Modifica il `Dockerfile` (righe 8-9 e 14):

```dockerfile
# Aggiorna la versione
ENV WILDFLY_VERSION=26.1.3.Final \
    WILDFLY_HOME=/opt/wildfly \
    JBOSS_HOME=/opt/wildfly

# Aggiorna l'URL di download (riga 14)
RUN cd /tmp && \
    wget -q https://download.jboss.org/wildfly/26.1.3.Final/wildfly-26.1.3.Final.tar.gz && \
    tar -xzf wildfly-26.1.3.Final.tar.gz -C /opt && \
    mv /opt/wildfly-26.1.3.Final ${WILDFLY_HOME} && \
    rm wildfly-26.1.3.Final.tar.gz
```

**Trova le versioni disponibili**: https://www.wildfly.org/downloads/

### Modificare le porte

#### Opzione 1: Cambiare porta esterna (consigliato per evitare conflitti)

Modifica solo `docker-compose.yml`:

```yaml
ports:
  - "8081:8080"  # Porta esterna:Porta interna
  - "9991:9990"
```

Accedi con: http://localhost:8081

#### Opzione 2: Cambiare porta interna WildFly

Modifica `config/standalone.xml` (cerca socket-binding-group):

```xml
<socket-binding name="http" port="${jboss.http.port:8090}"/>
```

E aggiorna anche `docker-compose.yml`:

```yaml
ports:
  - "8090:8090"  # Deve corrispondere
```

### Aggiungere variabili d'ambiente

Modifica `docker-compose.yml`:

```yaml
services:
  wildfly:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: wildfly-dev
    environment:
      - JAVA_OPTS=-Xms512m -Xmx2048m
      - DB_HOST=postgres-server
      - DB_PORT=5432
      - ENV=development
    ports:
      - "8080:8080"
      - "9990:9990"
```

---

## Aggiungere Moduli e Librerie Custom

### Aggiungere una nuova libreria JAR

1. **Copia il file JAR** in `custom-libs/`:

```bash
cp /path/to/mia-libreria.jar custom-libs/
```

2. **Crea un file module.xml** in `custom-libs/`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<module xmlns="urn:jboss:module:1.9" name="com.miomodulo.main">
    <resources>
        <resource-root path="mia-libreria.jar"/>
    </resources>
    <dependencies>
        <module name="javax.api"/>
    </dependencies>
</module>
```

3. **Aggiorna il Dockerfile** per copiare i file:

```dockerfile
# Aggiungi dopo le altre COPY
COPY ./custom-libs/mia-libreria.jar ${WILDFLY_HOME}/modules/com/miomodulo/main/
COPY ./custom-libs/module.xml ${WILDFLY_HOME}/modules/com/miomodulo/main/
```

### Aggiungere un driver JDBC

Esempio con PostgreSQL:

1. **Scarica il driver JDBC** e mettilo in `custom-libs/`:

```bash
wget https://jdbc.postgresql.org/download/postgresql-42.5.0.jar -O custom-libs/postgresql.jar
```

2. **Crea module.xml** per il driver:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<module xmlns="urn:jboss:module:1.9" name="org.postgresql">
    <resources>
        <resource-root path="postgresql.jar"/>
    </resources>
    <dependencies>
        <module name="javax.api"/>
        <module name="javax.transaction.api"/>
    </dependencies>
</module>
```

3. **Aggiorna Dockerfile**:

```dockerfile
RUN mkdir -p ${WILDFLY_HOME}/modules/org/postgresql/main
COPY ./custom-libs/postgresql.jar ${WILDFLY_HOME}/modules/org/postgresql/main/
COPY ./custom-libs/postgresql-module.xml ${WILDFLY_HOME}/modules/org/postgresql/main/module.xml
```

4. **Configura datasource in standalone.xml**:

```xml
<datasources>
    <datasource jndi-name="java:/PostgresDS" pool-name="PostgresDS">
        <connection-url>jdbc:postgresql://db-server:5432/mydb</connection-url>
        <driver>postgresql</driver>
        <security>
            <user-name>postgres</user-name>
            <password>password</password>
        </security>
    </datasource>
    <drivers>
        <driver name="postgresql" module="org.postgresql">
            <driver-class>org.postgresql.Driver</driver-class>
        </driver>
    </drivers>
</datasources>
```

---

## Configurare Multiple Istanze

Se devi eseguire più progetti contemporaneamente:

### Opzione 1: Porte diverse

**Progetto 1** - `docker-compose.yml`:
```yaml
services:
  wildfly:
    container_name: progetto1-dev
    ports:
      - "8080:8080"
      - "9990:9990"
    networks:
      - progetto1-network

networks:
  progetto1-network:
    driver: bridge
```

**Progetto 2** - `docker-compose.yml`:
```yaml
services:
  wildfly:
    container_name: progetto2-dev
    ports:
      - "8081:8080"  # Porta diversa
      - "9991:9990"  # Porta diversa
    networks:
      - progetto2-network

networks:
  progetto2-network:
    driver: bridge
```

### Opzione 2: File docker-compose multipli

Crea `docker-compose.progetto1.yml` e `docker-compose.progetto2.yml`:

```bash
# Avvia progetto 1
docker-compose -f docker-compose.progetto1.yml up -d

# Avvia progetto 2
docker-compose -f docker-compose.progetto2.yml up -d

# Stop progetto 1
docker-compose -f docker-compose.progetto1.yml down
```

---

## Best Practices

### 1. Usa .dockerignore

Crea un file `.dockerignore` nella cartella `docker-configuration/`:

```
# .dockerignore
README.md
CUSTOMIZATION_GUIDE.md
.git
.gitignore
*.log
*.tmp
```

### 2. Versionamento delle immagini

Nel `docker-compose.yml`, usa tag specifici:

```yaml
services:
  wildfly:
    build:
      context: .
      dockerfile: Dockerfile
    image: mio-progetto-wildfly:1.0.0  # Aggiungi versione
    container_name: mio-progetto-dev
```

Costruisci con:
```bash
docker-compose build
docker tag mio-progetto-wildfly:latest mio-progetto-wildfly:1.0.0
```

### 3. Usa volumi per sviluppo rapido

Per hot-reload durante sviluppo, aggiungi volumi in `docker-compose.yml`:

```yaml
services:
  wildfly:
    volumes:
      - ./ear:/opt/wildfly/standalone/deployments:ro  # Read-only
      - ./config/config.properties:/opt/wildfly/modules/IscrizioneAziendaPubblicaWeb/config.properties:ro
```

Così puoi aggiornare l'EAR o le configurazioni senza ricostruire l'immagine.

### 4. Separare configurazioni per ambiente

Crea file di properties diversi:

```
config/
├── config.properties.dev
├── config.properties.test
└── config.properties.prod
```

Nel Dockerfile, usa ARG per scegliere:

```dockerfile
ARG ENV=dev
COPY ./config/config.properties.${ENV} ${WILDFLY_HOME}/modules/App/config.properties
```

Build con:
```bash
docker-compose build --build-arg ENV=test
```

### 5. Limita risorse container

In `docker-compose.yml`:

```yaml
services:
  wildfly:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          cpus: '1.0'
          memory: 1G
```

### 6. Logging configurabile

Aggiungi in `docker-compose.yml`:

```yaml
services:
  wildfly:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

### 7. Health checks

Aggiungi in `docker-compose.yml`:

```yaml
services:
  wildfly:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
```

### 8. Script di setup automatico

Crea uno script `setup.sh`:

```bash
#!/bin/bash
set -e

echo "🔧 Setup ambiente Docker per il progetto..."

# Chiedi nome progetto
read -p "Nome progetto: " PROJECT_NAME

# Aggiorna docker-compose.yml
sed -i "s/wildfly-dev/${PROJECT_NAME}-dev/g" docker-compose.yml

# Chiedi file EAR
read -p "Path del file EAR: " EAR_PATH
cp "$EAR_PATH" ear/

# Build e start
echo "🚀 Costruisco l'immagine..."
docker-compose build

echo "✅ Setup completato! Avvia con: docker-compose up -d"
```

Usa con:
```bash
chmod +x setup.sh
./setup.sh
```

---

## Troubleshooting Customizzazioni

### Errore: Module not found

Verifica che il path del modulo in `module.xml` corrisponda alla struttura delle directory:

```
modules/org/postgresql/main/module.xml  → name="org.postgresql"
modules/com/mycompany/main/module.xml   → name="com.mycompany"
```

### Errore: Datasource non disponibile

1. Verifica che il driver sia configurato in `standalone.xml`
2. Controlla i log: `docker-compose logs -f | grep -i datasource`
3. Verifica che il modulo JDBC sia caricato correttamente

### Porta già in uso

```bash
# Trova il processo che usa la porta
sudo netstat -tulpn | grep 8080

# Oppure cambia porta in docker-compose.yml
ports:
  - "8081:8080"
```

### Container non parte dopo modifiche

```bash
# Rebuilda senza cache
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

---

## Checklist per Nuovo Progetto

- [ ] Copiata struttura `docker-configuration/`
- [ ] Sostituito file EAR in `ear/`
- [ ] Aggiornato `Dockerfile` con nome EAR corretto (riga 39)
- [ ] Modificato `config/config.properties` con configurazioni progetto
- [ ] Aggiornato `docker-compose.yml` con nomi container/network univoci
- [ ] Modificato `README.md` con riferimenti al nuovo progetto
- [ ] Verificate porte (8080, 9990) per evitare conflitti
- [ ] Aggiunti moduli custom se necessari
- [ ] Configurati datasources in `standalone.xml` se necessario
- [ ] Testato build: `docker-compose build`
- [ ] Testato avvio: `docker-compose up -d`
- [ ] Verificato accesso: http://localhost:8080
- [ ] Controllati i log: `docker-compose logs -f`

---

## Risorse Utili

- **WildFly Downloads**: https://www.wildfly.org/downloads/
- **WildFly Documentation**: https://docs.wildfly.org/
- **Docker Compose Reference**: https://docs.docker.com/compose/compose-file/
- **Podman Documentation**: https://docs.podman.io/
- **Eclipse Temurin (Java)**: https://adoptium.net/

---

## Supporto

Per domande o problemi con questa configurazione, contatta il team DevOps o consulta il README.md per istruzioni operative.

---

## Comandi per Avviare l'Ambiente

### 1. Navigare alla directory del progetto

```bash
cd /home/masanson/projects/podman-inps-configuration
```

### 2. Costruire l'immagine Docker/Podman

```bash
docker-compose build
```

oppure con Podman:

```bash
podman-compose build
```

### 3. Avviare i container

```bash
docker-compose up -d
```

oppure con Podman:

```bash
podman-compose up -d
```

### 4. Verificare che il container sia attivo

```bash
docker-compose ps
```

oppure:

```bash
podman ps
```

### 5. Visualizzare i log del container

```bash
docker-compose logs -f
```

oppure:

```bash
podman logs -f wildfly-dev
```

### 6. Accedere all'applicazione

- **Applicazione Web**: http://localhost:8080
- **Console Amministrazione WildFly**: http://localhost:9990

### 7. Fermare l'ambiente

```bash
docker-compose down
```

oppure:

```bash
podman-compose down
```

### 8. Ricostruire dopo modifiche

```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```
