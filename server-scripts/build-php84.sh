#!/usr/bin/env bash
# PHP 8.4 compilat din sursa pe Ubuntu 20.04 (focal), integrat cu HestiaCP.
# Binare in /opt/php/8.4, config in /etc/php/8.4/fpm, serviciu php8.4-fpm.
# Scriptul poate fi rulat din nou: actualizeaza PHP fara sa atinga pool-urile Hestia.
set -euo pipefail

PHP_BRANCH="8.4"
PREFIX="/opt/php/${PHP_BRANCH}"
CONF_DIR="/etc/php/${PHP_BRANCH}/fpm"
SRC_DIR="/usr/local/src"

[ "$(id -u)" -eq 0 ] || { echo "Ruleaza ca root"; exit 1; }

# 1. Ultima versiune 8.4.x de pe php.net (poti forta: PHP_VER=8.4.x ./build-php84.sh)
if [ -z "${PHP_VER:-}" ]; then
  PHP_VER=$(curl -fsSL "https://www.php.net/releases/?json&version=${PHP_BRANCH}" \
            | grep -oP '"version":\s*"\K[0-9.]+' | head -1)
fi
[ -n "$PHP_VER" ] || { echo "Nu am putut determina versiunea. Seteaza PHP_VER manual."; exit 1; }
echo ">> Compilez PHP ${PHP_VER}"

# 2. Dependinte de build
# Pe focal (EOL) unele PPA-uri dau 403 (ex. ondrej/nginx) si apt-get update iese cu eroare;
# nu oprim build-ul din cauza asta, pachetele de mai jos vin din repo-urile care merg.
apt-get update || echo ">> Atentie: apt-get update a avut erori (vezi mai sus), continui"
# (fara libxml2-dev / libargon2-dev / libxslt1-dev: intra in conflict cu PPA-ul ondrej)
apt-get install -y build-essential autoconf bison re2c pkg-config \
  libsqlite3-dev libssl-dev libcurl4-openssl-dev libonig-dev \
  libzip-dev libpng-dev libjpeg-dev libfreetype6-dev libwebp-dev \
  libicu-dev libgmp-dev libsodium-dev \
  libbz2-dev zlib1g-dev libsystemd-dev

# 2b. libxml2 compilat static, doar pentru acest PHP (nu atinge sistemul)
DEPS="${PREFIX}/deps"
LIBXML_VER="2.12.10"
mkdir -p "$SRC_DIR" && cd "$SRC_DIR"
if [ ! -f "$DEPS/lib/libxml2.a" ]; then
  curl -fSL -o "libxml2-${LIBXML_VER}.tar.xz" \
    "https://download.gnome.org/sources/libxml2/${LIBXML_VER%.*}/libxml2-${LIBXML_VER}.tar.xz"
  rm -rf "libxml2-${LIBXML_VER}" && tar xf "libxml2-${LIBXML_VER}.tar.xz"
  ( cd "libxml2-${LIBXML_VER}" && \
    ./configure --prefix="$DEPS" --disable-shared --enable-static --with-pic \
                --without-python --without-lzma --without-icu --with-zlib && \
    nice -n 19 make -j"$(nproc)" && make install )
fi
export PKG_CONFIG_PATH="$DEPS/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
export LIBS="-lz -lm"

# 3. Sursa
cd "$SRC_DIR"
curl -fSL -o "php-${PHP_VER}.tar.xz" "https://www.php.net/distributions/php-${PHP_VER}.tar.xz"
rm -rf "php-${PHP_VER}" && tar xf "php-${PHP_VER}.tar.xz" && cd "php-${PHP_VER}"

# 4. Configure
./configure \
  --prefix="$PREFIX" \
  --with-config-file-path="$CONF_DIR" \
  --with-config-file-scan-dir="$CONF_DIR/conf.d" \
  --enable-fpm --with-fpm-user=www-data --with-fpm-group=www-data --with-fpm-systemd \
  --enable-mbstring --enable-intl --enable-bcmath --enable-calendar --enable-exif \
  --enable-ftp --enable-soap --enable-sockets --enable-pcntl --enable-opcache \
  --enable-gd --with-freetype --with-jpeg --with-webp \
  --with-curl --with-openssl --with-zlib --with-bz2 --with-zip \
  --with-gmp --with-sodium \
  --enable-mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-pdo-sqlite

# 5. Build cu prioritate mica (serverul e in productie)
nice -n 19 make -j"$(nproc)"
make install

# 6. Config (nu suprascrie ce exista deja)
mkdir -p "$CONF_DIR/conf.d" "$CONF_DIR/pool.d" /run/php
[ -f "$CONF_DIR/php.ini" ] || cp php.ini-production "$CONF_DIR/php.ini"
[ -f "$CONF_DIR/conf.d/10-opcache.ini" ] || cat > "$CONF_DIR/conf.d/10-opcache.ini" <<'EOF'
zend_extension=opcache.so
opcache.enable=1
opcache.memory_consumption=128
opcache.max_accelerated_files=20000
EOF

cat > "$CONF_DIR/php-fpm.conf" <<EOF
[global]
pid = /run/php/php${PHP_BRANCH}-fpm.pid
error_log = /var/log/php${PHP_BRANCH}-fpm.log
include = ${CONF_DIR}/pool.d/*.conf
EOF

# Pool implicit, ca FPM sa porneasca si fara domenii pe 8.4
[ -f "$CONF_DIR/pool.d/www.conf" ] || cat > "$CONF_DIR/pool.d/www.conf" <<EOF
[www]
user = www-data
group = www-data
listen = /run/php/php${PHP_BRANCH}-fpm.sock
listen.owner = www-data
listen.group = www-data
pm = ondemand
pm.max_children = 2
EOF

# 7. Serviciu systemd cu numele pe care il asteapta Hestia.
# Pornim prin symlink-ul /usr/sbin/php-fpm8.4 ca procesul sa se numeasca
# php-fpm8.4 (Hestia verifica starea cu pidof dupa numele asta).
ln -sf "${PREFIX}/sbin/php-fpm" "/usr/sbin/php-fpm${PHP_BRANCH}"
cat > "/etc/systemd/system/php${PHP_BRANCH}-fpm.service" <<EOF
[Unit]
Description=PHP ${PHP_BRANCH} FastCGI Process Manager (build din sursa)
After=network.target

[Service]
Type=notify
ExecStartPre=/bin/mkdir -p /run/php
ExecStartPre=${PREFIX}/sbin/php-fpm --test --fpm-config ${CONF_DIR}/php-fpm.conf
ExecStart=/usr/sbin/php-fpm${PHP_BRANCH} --nodaemonize --fpm-config ${CONF_DIR}/php-fpm.conf
ExecReload=/bin/kill -USR2 \$MAINPID
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# 8. Binar CLI ca php8.4 (NU schimba `php` implicit de pe sistem)
ln -sf "$PREFIX/bin/php" "/usr/bin/php${PHP_BRANCH}"

systemctl daemon-reload
systemctl enable "php${PHP_BRANCH}-fpm"
systemctl restart "php${PHP_BRANCH}-fpm"

echo
"/usr/bin/php${PHP_BRANCH}" -v
systemctl --no-pager status "php${PHP_BRANCH}-fpm" | head -5
echo ">> Gata. Verifica template-ul Hestia: ls /usr/local/hestia/data/templates/web/php-fpm/ | grep 8_4"
