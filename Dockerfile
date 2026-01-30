FROM debian:bookworm-slim

ARG ASTERISK_VERSION=22.2.0
ARG FREEPBX_VERSION=17.0-latest

ENV DEBIAN_FRONTEND=noninteractive

# 1. Install Dependencies (added libxslt1-dev for XML docs)
RUN apt-get update && apt-get install -y \
    git curl wget vim build-essential pkg-config \
    libnewt-dev libssl-dev libncurses-dev libedit-dev subversion libsqlite3-dev \
    libjansson-dev libxml2-dev libxslt1-dev uuid-dev default-libmysqlclient-dev \
    htop sngrep lame ffmpeg mpg123 sox \
    apache2 mariadb-client \
    php8.2 php8.2-curl php8.2-cli php8.2-common php8.2-mysql \
    php8.2-gd php8.2-mbstring php8.2-intl php8.2-xml php-pear \
    nodejs npm cron logrotate \
    && rm -rf /var/lib/apt/lists/*

# 2. Build Asterisk from Source
WORKDIR /usr/src
RUN wget http://downloads.asterisk.org/pub/telephony/asterisk/releases/asterisk-${ASTERISK_VERSION}.tar.gz \
	&& tar zxf asterisk-${ASTERISK_VERSION}.tar.gz \
    && cd asterisk-${ASTERISK_VERSION} \
    && ./configure --libdir=/usr/lib64 --with-jansson-bundled \
    && make menuselect-tree \
    && make -j$(nproc) \
    && make install \
    && make config \
    && make samples \
    && make install-headers \
    && echo "/usr/lib64" > /etc/ld.so.conf.d/asterisk.conf \
    && ldconfig

# 3. Setup Asterisk user and permissions
RUN mkdir -p /var/lib/asterisk /var/log/asterisk /var/spool/asterisk /etc/asterisk \
    && groupadd -r asterisk \
    && useradd -r -d /var/lib/asterisk -g asterisk asterisk \
    && usermod -aG audio,dialout asterisk \
    && chown -R asterisk:asterisk /etc/asterisk \
    && chown -R asterisk:asterisk /var/lib/asterisk \
    && chown -R asterisk:asterisk /var/log/asterisk \
    && chown -R asterisk:asterisk /var/spool/asterisk \
    && chown -R asterisk:asterisk /usr/lib64/asterisk

# 4. Backup default configs (for volume initialization)
RUN cp -a /etc/asterisk /etc/asterisk.default \
    && cp -a /var/lib/asterisk /var/lib/asterisk.default

# 5. Apache Config for FreePBX
RUN sed -i 's/^\(User\|Group\).*/\1 asterisk/' /etc/apache2/apache2.conf \
    && sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf \
    && a2enmod rewrite

# 6. Download FreePBX
WORKDIR /usr/src
RUN wget http://mirror.freepbx.org/modules/packages/freepbx/freepbx-${FREEPBX_VERSION}.tgz \
    && tar zxf freepbx-${FREEPBX_VERSION}.tgz

# 7. Copy Entrypoint
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# 8. Setup Logrotate
COPY logrotate-asterisk /etc/logrotate.d/asterisk
RUN chmod 644 /etc/logrotate.d/asterisk

WORKDIR /var/www/html
EXPOSE 80 5060/udp 5160/udp 10000-20000/udp

ENTRYPOINT ["/docker-entrypoint.sh"]