FROM mediawiki:latest

# Install PHP PostgreSQL support and other necessary packages
RUN apt-get update && \
    apt-get install -y \
    libpq-dev \
    wget \
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
RUN wget -qO- https://extdist.wmflabs.org/dist/extensions/PluggableAuth-REL1_42-f0a83a8.tar.gz | tar -xz -C $MW_EXT_DIR

# Download and install LDAPProvider extension
RUN wget -qO- https://extdist.wmflabs.org/dist/extensions/LDAPProvider-REL1_42-e669d24.tar.gz | tar -xz -C $MW_EXT_DIR

# Download and install LDAPAuthentication2 extension
RUN wget -qO- https://extdist.wmflabs.org/dist/extensions/LDAPAuthentication2-REL1_42-dbd16a5.tar.gz | tar -xz -C $MW_EXT_DIR

# Adding LocalSettings.php
ADD LocalSettings.php /data

# Symbolic link /data/LocalSettings.php to /var/www/html
RUN ln -s /data/LocalSettings.php /var/www/html

# Ensure ownership and permissions are correct
RUN chown -R www-data:www-data $MW_EXT_DIR

# Expose the HTTP port
EXPOSE 80

# Command to run Apache
CMD ["apache2-foreground"]
