# Utilizziamo un'immagine ufficiale con Java 11
FROM eclipse-temurin:11-jdk

# Installiamo wget e tar per scaricare WildFly
RUN apt-get update && apt-get install -y wget tar && rm -rf /var/lib/apt/lists/*

# Variabili d'ambiente
ENV WILDFLY_VERSION=23.0.2.Final \
    WILDFLY_HOME=/opt/wildfly \
    JBOSS_HOME=/opt/wildfly

# Scarichiamo e installiamo WildFly 23.0.2
RUN cd /tmp && \
    wget -q https://download.jboss.org/wildfly/23.0.2.Final/wildfly-23.0.2.Final.tar.gz && \
    tar -xzf wildfly-23.0.2.Final.tar.gz -C /opt && \
    mv /opt/wildfly-23.0.2.Final ${WILDFLY_HOME} && \
    rm wildfly-23.0.2.Final.tar.gz

# Creiamo le directory necessarie
RUN mkdir -p ${WILDFLY_HOME}/standalone/deployments && \
    mkdir -p ${WILDFLY_HOME}/modules/IscrizioneAziendaPubblicaWeb && \
    mkdir -p ${WILDFLY_HOME}/modules/inps/passi/main && \
    mkdir -p ${WILDFLY_HOME}/truststore

# Copiamo il file di configurazione
COPY ./config/config.properties ${WILDFLY_HOME}/modules/IscrizioneAziendaPubblicaWeb/

# Copiamo lo standalone.xml custom
COPY ./config/standalone.xml ${WILDFLY_HOME}/standalone/configuration/

# Copiamo il modulo custom inps.passi
COPY ./custom-libs/passi.jar ${WILDFLY_HOME}/modules/inps/passi/main/
COPY ./custom-libs/module.xml ${WILDFLY_HOME}/modules/inps/passi/main/

# Copiamo il truststore
COPY ./truststore/truststore.jks ${WILDFLY_HOME}/truststore/

# Copiamo il file EAR per il deploy automatico
COPY ./ear/IscrizioneAziendaPubblicaWeb.ear ${WILDFLY_HOME}/standalone/deployments/

# Esponiamo le porte
# 8080: applicazione
# 9990: console di amministrazione
EXPOSE 8080 9990

# Avviamo WildFly
CMD ["/opt/wildfly/bin/standalone.sh", "-b", "0.0.0.0", "-bmanagement", "0.0.0.0"]
