FROM mediawiki:latest

# Install PHP PostgreSQL support and other necessary packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
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

# 4. Baixa as extensões corretas
RUN git clone -b REL1_44 https://gerrit.wikimedia.org/r/mediawiki/extensions/PluggableAuth.git && \
    git clone -b REL1_44 https://gerrit.wikimedia.org/r/mediawiki/extensions/OpenIDConnect.git

# 5. Corrige o problema de 'dubious ownership' do git dentro do container
RUN git config --global --add safe.directory /var/www/html/extensions/OpenIDConnect

# 6. Instala o Composer e as dependências da extensão OpenIDConnect
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    composer --working-dir=/var/www/html/extensions/OpenIDConnect install --no-dev --prefer-dist

# Define o diretório de trabalho padrão para os próximos comandos
WORKDIR /var/www/html

# ===================================================================
# INSTALAÇÃO AUTOMATIZADA DAS EXTENSÕES
# ===================================================================

#Instala extensões via Composer
# Copia o nosso arquivo de dependências para a raiz do MediaWiki
COPY ./composer.local.json .

#Roda o Composer para baixar SemanticMediaWiki, PageForms, etc.
RUN composer install --no-dev --no-scripts && \
    composer update --no-dev && \
    rm -rf vendor/composer/cache

# Define o diretório de trabalho para a pasta de extensões
WORKDIR /var/www/html/extensions

# Remove a versão do ParserFunctions instalada pelo Composer para evitar conflito
RUN rm -rf $MW_EXT_DIR/ParserFunctions

# Agora, clona a branch específica do ParserFunctions compatível com MediaWiki 1.44
RUN git clone -b REL1_44 https://gerrit.wikimedia.org/r/mediawiki/extensions/ParserFunctions.git $MW_EXT_DIR/ParserFunctions

# Copia nossa extensão customizada ProcessAutomation para dentro da imagem
COPY ./extensions/ProcessAutomation $MW_EXT_DIR/ProcessAutomation

# Reseolvendo Problemas de Compatibilidade
# Aplica a correção permanente, renomeando os dois arquivos de patch
# que já nos deram problema. Assim garantimos que eles nunca serão executados.
RUN mv /var/www/html/sql/postgres/patch-pagelinks-drop-pl_title.sql /var/www/html/sql/postgres/patch-pagelinks-drop-pl_title.sql.disabled && \
    mv /var/www/html/sql/mysql/patch-pagelinks-drop-pl_title.sql /var/www/html/sql/mysql/patch-pagelinks-drop-pl_title.sql.disabled

#Criando Arquivo Vazio
RUN touch /var/www/html/sql/mysql/patch-pagelinks-drop-pl_title.sql

# Volta para o diretório principal
WORKDIR /var/www/html

#Ensure ownership and permissions are correct
RUN chown -R www-data:www-data $MW_EXT_DIR

# Expose the HTTP port
EXPOSE 80

# Command to run Apache
CMD ["apache2-foreground"]