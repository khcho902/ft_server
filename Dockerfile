FROM debian:buster

# Install required programs
RUN apt-get update && apt-get install -y \
	mariadb-server \
	nginx \
	openssl \
	php-fpm \
	php-mysql \
	wget

# Create a self-signed SSL certificate
RUN openssl req -newkey rsa:4096 -days 365 -nodes -x509 \
		-subj "/C=KR/ST=Seoul/L=Seoul/O=42Seoul/OU=Lee/CN=localhost" \
		-keyout localhost.dev.key -out localhost.dev.crt \
	&& mv localhost.dev.crt /etc/ssl/certs/ \
	&& mv localhost.dev.key /etc/ssl/private/ \
	&& chmod 600 /etc/ssl/certs/localhost.dev.crt /etc/ssl/private/localhost.dev.key

# Set nginx configuration file
COPY ./srcs/default /etc/nginx/sites-available/

# Install phpMyAdmin
RUN wget https://files.phpmyadmin.net/phpMyAdmin/5.0.2/phpMyAdmin-5.0.2-all-languages.tar.gz \
	&& tar -zxvf phpMyAdmin-5.0.2-all-languages.tar.gz \
	&& mv phpMyAdmin-5.0.2-all-languages /var/www/html/phpmyadmin \
	&& rm phpMyAdmin-5.0.2-all-languages.tar.gz
	
# Set phpMyAdmin configuration file
COPY ./srcs/config.inc.php /var/www/html/phpmyadmin/

# Set up the database
RUN service mysql start \
	&& mysql < /var/www/html/phpmyadmin/sql/create_tables.sql -u root --skip-password \
	&& echo "CREATE DATABASE IF NOT EXISTS wordpress;" | mysql -u root --skip-password \
	&& echo "CREATE USER 'kycho'@'%' identified by 'admin1234';" | mysql -u root --skip-password \
	&& echo "GRANT ALL PRIVILEGES ON *.* to 'kycho'@'%' WITH GRANT OPTION;" | mysql -u root --skip-password \
	&& echo "FLUSH PRIVILEGES;" | mysql -u root --skip-password

# Install wordpress
ADD ./srcs/wordpress.tar.gz /var/www/html/
RUN chown -R www-data:www-data /var/www/html/wordpress

# Set wordpress configuration file
COPY ./srcs/wp-config.php /var/www/html/wordpress/

# Remove index file for autoindex
RUN rm /var/www/html/index.nginx-debian.html

EXPOSE 80
EXPOSE 443

CMD service php7.3-fpm start \
	&& service mysql start \
	&& nginx -g "daemon off;"
