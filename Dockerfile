FROM mediawiki:latest

# Install PHP PostgreSQL support and other necessary packages
RUN apt-get update && \
    apt-get install -y \
    libpq-dev \
    wget \
    curl \
    jq \
    unzip \
    libldap-dev && \
    docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ && \
    docker-php-ext-install \
    pdo_pgsql pgsql ldap && \
    apt-get purge -y --auto-remove libldap-dev && \
    rm -rf /var/lib/apt/lists/*

# Set MediaWiki extensions directory
ENV MW_EXT_DIR=/var/www/html/extensions

# Download and install PluggableAuth extension
RUN PluggableAuth=$(curl -s https://api.github.com/repos/wikimedia/mediawiki-extensions-PluggableAuth/tags | jq -r '.[0].name') && \
    wget -qO /tmp/PluggableAuth.zip https://github.com/wikimedia/mediawiki-extensions-PluggableAuth/archive/refs/tags/${PluggableAuth}.zip && \
    unzip /tmp/PluggableAuth.zip -d $MW_EXT_DIR && \
    rm -f /tmp/PluggableAuth.zip

# Download and install LDAPProvider extension
RUN LDAPProvider=$(curl -s https://api.github.com/repos/wikimedia/mediawiki-extensions-LDAPProvider/tags | jq -r '.[0].name') && \
    wget -qO /tmp/LDAPProvider.zip https://github.com/wikimedia/mediawiki-extensions-LDAPProvider/archive/refs/tags/${LDAPProvider}.zip && \
    unzip /tmp/LDAPProvider.zip -d $MW_EXT_DIR && \
    rm -f /tmp/LDAPProvider.zip

# Download and install LDAPAuthentication2 extension
RUN LDAPAuthentication2=$(curl -s https://api.github.com/repos/wikimedia/mediawiki-extensions-LDAPAuthentication2/tags | jq -r '.[0].name') && \
    wget -qO /tmp/LDAPAuthentication2.zip https://github.com/wikimedia/mediawiki-extensions-LDAPAuthentication2/archive/refs/tags/${LDAPAuthentication2}.zip && \
    unzip /tmp/LDAPAuthentication2.zip -d $MW_EXT_DIR && \
    rm -f /tmp/LDAPAuthentication2.zip

# Ensure ownership and permissions are correct
RUN chown -R www-data:www-data $MW_EXT_DIR

# Expose the HTTP port
EXPOSE 80

# Command to run Apache
CMD ["apache2-foreground"]
