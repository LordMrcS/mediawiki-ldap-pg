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
RUN latest_tag=$(curl -s https://api.github.com/repos/wikimedia/mediawiki-extensions-PluggableAuth/tags | jq -r '.[0].name') && \
    wget -qO- https://github.com/wikimedia/mediawiki-extensions-PluggableAuth/archive/refs/tags/${latest_tag}.zip | tar -xz -C $MW_EXT_DIR

# Download and install LDAPProvider extension
RUN latest_tag=$(curl -s https://api.github.com/repos/wikimedia/mediawiki-extensions-LDAPProvider/tags | jq -r '.[0].name') && \
    wget -qO- https://github.com/wikimedia/mediawiki-extensions-LDAPProvider/archive/refs/tags/${latest_tag}.zip | tar -xz -C $MW_EXT_DIR

# Download and install LDAPAuthentication2 extension
RUN latest_tag=$(curl -s https://api.github.com/repos/wikimedia/mediawiki-extensions-LDAPAuthentication2/tags | jq -r '.[0].name') && \
    wget -qO- https://github.com/wikimedia/mediawiki-extensions-LDAPAuthentication2/archive/refs/tags/${latest_tag}.zip | tar -xz -C $MW_EXT_DIR

# Ensure ownership and permissions are correct
RUN chown -R www-data:www-data $MW_EXT_DIR

# Expose the HTTP port
EXPOSE 80

# Command to run Apache
CMD ["apache2-foreground"]
