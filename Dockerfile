FROM mediawiki:1.44
ENV VERSION=REL1_44

# Install PHP PostgreSQL support and other necessary packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    unzip \
    libpq-dev \
    libzip-dev \
    libonig-dev \
    wget \
    libicu-dev && \
# Instala as extensões PHP que o MediaWiki e os plugins precisam.
    docker-php-ext-install zip mbstring intl pdo_pgsql pgsql && \
#   apt-get purge -y --auto-remove libldap-dev && \
    rm -rf /var/lib/apt/lists/*

# Set MediaWiki extensions directory
ENV MW_EXT_DIR=/var/www/html/extensions

# 3. Define o diretório de trabalho para a pasta de extensões
WORKDIR /var/www/html/extensions

# Download and install PluggableAuth extension
RUN wget -qO /tmp/PluggableAuth.zip https://github.com/wikimedia/mediawiki-extensions-PluggableAuth/archive/refs/heads/${VERSION}.zip && \
    unzip /tmp/PluggableAuth.zip -d $MW_EXT_DIR && \
    mv $MW_EXT_DIR/mediawiki-extensions-PluggableAuth-${VERSION} $MW_EXT_DIR/PluggableAuth && \
    rm -f /tmp/PluggableAuth.zip

RUN wget -qO /tmp/OpenIDConnect.zip https://github.com/wikimedia/mediawiki-extensions-OpenIDConnect/archive/refs/heads/${VERSION}.zip && \
    unzip /tmp/OpenIDConnect.zip -d $MW_EXT_DIR && \
    mv $MW_EXT_DIR/mediawiki-extensions-OpenIDConnect-${VERSION} $MW_EXT_DIR/OpenIDConnect && \
    rm -f /tmp/OpenIDConnect.zip

# Remove a versão do ParserFunctions instalada pelo Composer para evitar conflito
RUN rm -rf ParserFunctions

RUN wget -qO /tmp/ParserFunctions.zip https://github.com/wikimedia/mediawiki-extensions-ParserFunctions/archive/refs/heads/${VERSION}.zip && \
    unzip /tmp/ParserFunctions.zip -d $MW_EXT_DIR && \
    mv $MW_EXT_DIR/mediawiki-extensions-ParserFunctions-${VERSION} $MW_EXT_DIR/ParserFunctions && \
    rm -f /tmp/ParserFunctions.zip

# Volta para o diretório principal
WORKDIR /var/www/html

#Ensure ownership and permissions are correct
RUN chown -R www-data:www-data $MW_EXT_DIR

# Expose the HTTP port
EXPOSE 80

# Command to run Apache
CMD ["apache2-foreground"]
