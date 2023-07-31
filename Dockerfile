# Utiliza a imagem base do Ubuntu 20.04
FROM ubuntu:20.04

# Define a variável de ambiente para evitar interações durante a instalação
ENV DEBIAN_FRONTEND=noninteractive

# Atualiza os pacotes do sistema e instala os requisitos para adicionar o PPA do PHP
RUN apt-get update && apt-get install -y software-properties-common

# Adiciona o PPA do PHP 7.4
RUN add-apt-repository ppa:ondrej/php

# Atualiza novamente os pacotes após adicionar o PPA
RUN apt-get update

# Instala o Apache2
RUN apt-get install -y apache2

# Instala o PHP 7.4 e extensões necessárias
RUN apt-get install -y php7.4 libapache2-mod-php7.4 php7.4-cli php7.4-mysql php7.4-gd php7.4-imagick php7.4-tidy php7.4-xmlrpc php7.4-common php7.4-curl php7.4-mbstring php7.4-xml php7.4-bcmath php7.4-bz2 php7.4-intl php7.4-readline php7.4-zip php7.4-redis php7.4-ldap php7.4-msgpack php7.4-igbinary php7.4-uuid php7.4-memcached php7.4-mongodb php7.4-sqlite3 php7.4-dev

# Instala as dependências do SQL Server
RUN apt-get install -y curl gnupg2 apt-transport-https && curl -s https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
RUN bash -c "curl -s https://packages.microsoft.com/config/ubuntu/20.04/prod.list > /etc/apt/sources.list.d/mssql-release.list"
RUN apt-get update && ACCEPT_EULA=Y apt-get -y install msodbcsql17 mssql-tools

# Instala o driver sqlsrv e pdo_sqlsrv para o PHP 7.4
RUN apt-get install -y php-pear php7.4-dev unixodbc-dev && pecl channel-update pecl.php.net && pecl install sqlsrv-5.9.0 pdo_sqlsrv-5.9.0

# Habilita os módulos do Apache2 com PHP 7.4
RUN a2enmod php7.4
RUN a2enmod rewrite

# Copia o arquivo de configuração do Apache2
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf
RUN echo "LoadModule mpm_prefork_module /usr/lib/apache2/modules/mod_mpm_prefork.so" >> /etc/apache2/apache2.conf

# Comenta a linha que contém a diretiva 'Require'
RUN sed -i 's/Require/#Require/' /etc/apache2/apache2.conf

# Copia o código para o diretório do Apache2
COPY locus-cd/ /var/www/html/locus-cd
COPY locus-lojas/ /var/www/html/locus-lojas

# Define o diretório de trabalho
WORKDIR /var/www/html

RUN rm /var/www/html/index.html

# Dá permissão ao diretório /var/www/html/locus_lojas para o Apache
RUN chown -R www-data:www-data /var/www/html/locus-cd
RUN chown -R www-data:www-data /var/www/html/locus-lojas

# Configura o driver do SQL Server e cria os links simbólicos com PHP 7.4
RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository ppa:ondrej/php && \
    apt-get update && \
    apt-get install -y php7.4 php7.4-dev php-pear && \
    echo "extension=sqlsrv.so" > /etc/php/7.4/mods-available/sqlsrv.ini && \
    echo "sqlsrv.ClientBufferMaxKBSize = 500000" >> /etc/php/7.4/mods-available/sqlsrv.ini && \
    echo "extension=pdo_sqlsrv.so" > /etc/php/7.4/mods-available/pdo_sqlsrv.ini && \
    ln -s /etc/php/7.4/mods-available/sqlsrv.ini /etc/php/7.4/cli/conf.d/20-sqlsrv.ini && \
    ln -s /etc/php/7.4/mods-available/pdo_sqlsrv.ini /etc/php/7.4/cli/conf.d/20-pdo_sqlsrv.ini && \
    ln -s /etc/php/7.4/mods-available/sqlsrv.ini /etc/php/7.4/apache2/conf.d/20-sqlsrv.ini && \
    ln -s /etc/php/7.4/mods-available/pdo_sqlsrv.ini /etc/php/7.4/apache2/conf.d/20-pdo_sqlsrv.ini

RUN rm /etc/apache2/apache2.conf

COPY apache2.conf /etc/apache2/apache2.conf

# Configura o limite de memória do PHP (opcional)
# RUN echo "memory_limit = 2G" >> /etc/php/7.4/cli/php.ini
RUN rm /etc/php/7.4/apache2/php.ini
COPY phpapache.ini /etc/php/7.4/apache2/php.ini

# Expõe a porta 80 do container
EXPOSE 80

# Inicia o Apache2 em foreground
CMD ["apachectl", "-D", "FOREGROUND"]

