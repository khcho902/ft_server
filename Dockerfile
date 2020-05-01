FROM debian:buster

RUN apt-get update && apt-get install -y curl ca-certificates gnupg2 lsb-release

RUN echo "deb http://nginx.org/packages/debian `lsb_release -cs` nginx" | tee /etc/apt/sources.list.d/nginx.list \
	&& curl -fsSL https://nginx.org/keys/nginx_signing.key | apt-key add -

RUN apt-get update && apt-get install -y \
	nginx=1.18.0-1~buster \
	mariadb-server mariadb-client \
	php7.3 php7.3-fpm php7.3-mysql php-common php7.3-cli php7.3-common php7.3-json php7.3-opcache php7.3-readline

COPY srcs/nginx.conf /etc/nginx/nginx.conf
COPY srcs/default.conf /etc/nginx/conf.d/default.conf
COPY srcs/info.php /usr/share/nginx/html/info.php

EXPOSE 80

CMD service php7.3-fpm start \
	&& service mysql start \
	&& nginx -g "daemon off;" \
