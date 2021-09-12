FROM debian:bullseye-slim
LABEL name="nintendo-dgamer"
LABEL description="nintendo-dgamer is a replacement DGamer (DS/DSi) server"
LABEL maintainer="hashsploit <hashsploit@protonmail.com>"

#RUN apt-get update \
#	&& apt-get install -y \
#	libssl-dev ssl-cert php7.0 libapache2-mod-php7.0 \
#	wget unzip php7.0-mcrypt libmcrypt-dev bind9 bind9utils dnsutils \
#	&& apt-get clean \
#	&& rm -rf /var/lib/apt/lists/*

# Install dependencies
RUN echo "Updating packages ..." \
	&& apt-get update -y >/dev/null 2>&1 \
	&& echo "Installing dependencies ..." \
	&& apt-get install -y \
	curl \
	build-essential \
	make \
	libz-dev \
	libbz2-dev \
	libreadline-dev \
	libexpat1-dev \
	zlib1g-dev >/dev/null 2>&1

# Remove bloat
RUN rm -rf /var/lib/apt/lists/* /var/cache/apt/* \
	&& apt-get autoremove --purge -y \
	&& apt-get clean -y \
	&& rm -rf /usr/share/man \
	&& rm -rf /usr/share/locale \
	&& rm -rf /usr/share/doc \
	&& mkdir -p /etc/initramfs-tools/conf.d/ \
	&& echo "COMPRESS=xz" | tee /etc/initramfs-tools/conf.d/compress >/dev/null 2>&1

# Compile OpenSSL from source (enable support for SSLv3)
ADD https://openssl.org/source/openssl-1.0.2k.tar.gz /tmp
RUN cd /tmp \
	&& tar -xzf openssl*.tar.gz \
	&& cd openssl*/ \
	&& ./config --prefix=/usr --openssldir=/usr/lib/ssl enable-ssl2 enable-ssl3 no-shared \
	&& make depend \
	&& make \
	&& make install

# Compile PCRE
ADD https://ftp.pcre.org/pub/pcre/pcre-8.45.tar.bz2 /tmp
RUN cd /tmp \
	&& tar -xjf pcre*.tar.bz2 \
	&& rm pcre*.tar.bz2 \
	&& cd pcre*/ \
	&& ./configure --prefix=/usr \
		--docdir=/usr/share/doc/pcre-8.45 \
		--enable-unicode-properties \
		--enable-pcre16 \
		--enable-pcre32 \
		--enable-pcregrep-libz \
		--enable-pcregrep-libbz2 \
		--enable-pcretest-libreadline \
		--disable-static \
	&& make \
	&& make install

# Compile apache2 from source (use custom OpenSSL version)
ADD https://downloads.apache.org/httpd/httpd-2.4.48.tar.gz /tmp
RUN cd /tmp \
	&& tar -xzf httpd*.tar.gz \
	&& rm httpd*.tar.gz \
	&& mv httpd*/ httpd/
ADD https://dlcdn.apache.org/apr/apr-1.7.0.tar.gz /tmp
ADD https://dlcdn.apache.org/apr/apr-util-1.6.1.tar.gz /tmp
RUN cd /tmp \
	&& tar -xzf apr-util*.tar.gz \
	&& rm apr-util*.tar.gz \
	&& mv apr-util*/ /tmp/httpd/srclib/apr-util \
	&& tar -xzf apr*.tar.gz \
	&& rm apr*.tar.gz \
	&& mv apr*/ /tmp/httpd/srclib/apr \
	&& cd /tmp/httpd/ \
	&& ./configure \
		--prefix=/usr/local/apache \
		--with-included-apr \
		--enable-ssl \
		--with-ssl=/usr/lib/ssl \
		--enable-ssl-staticlib-deps \
		--enable-mods-static=ssl \
		--enable-modules=all \
		-enable-so \
	&& make \
	&& make install \
	&& mkdir -p /etc/php/7.0/mods-available/

RUN mkdir -p /usr/local/apache/certs \
	&& echo "Generating keys for default host ..." \
	&& openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
	-subj "/C=US/ST=California/L=San Jose/O=None/CN=localhost" \
	-keyout /usr/local/apache/certs/server.key -out /usr/local/apache/certs/server.crt \
	&& echo "Generating keys for nas.nintendowifi.net ..." \
	&& openssl req -new -newkey rsa:1024 -days 3650 -nodes -x509 \
	-subj "/C=US/ST=California/L=San Jose/O=nintendo-nas/CN=nas.nintendowifi.net" \
	-keyout /usr/local/apache/certs/nas.nintendowifi.net.key -out /usr/local/apache/certs/nas.nintendowifi.net.crt \
	&& echo "Generating keys for home.disney.go.com ..." \
	&& openssl req -new -newkey rsa:1024 -days 3650 -nodes -x509 \
	-subj "/C=US/ST=California/L=San Jose/O=Disney Interactive Studios/CN=home.disney.go.com" \
	-keyout /usr/local/apache/certs/home.disney.go.com.key -out /usr/local/apache/certs/home.disney.go.com.crt

COPY ./sites/ /var/www/
COPY ./certs/ /usr/local/apache/certs/
COPY ./configs/apache/ /usr/local/apache/conf/
COPY ./entrypoint.sh /srv/

RUN chmod +x /srv/entrypoint.sh

# HTTP, HTTPS, DNS, DNS
EXPOSE 80/tcp 443/tcp 53/tcp 53/udp

CMD ["/srv/entrypoint.sh"]
