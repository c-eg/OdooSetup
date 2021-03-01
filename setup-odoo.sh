#!/bin/sh
# before running script, do: sudo su

#######################################
# CONFIGURATION

WEBSITE_NAME="_"
ADMIN_EMAIL="admin@example.com"

#######################################

# Update system
apt-get update -y && apt-get upgrade -y


# Install PostgreSQL
apt install posgresql -y
systemctl enable postgresql


# Add Odoo repository and install
wget -O - https://nightly.odoo.com/odoo.key | apt-key add -
echo "deb http://nightly.odoo.com/14.0/nightly/deb/ ./" >> /etc/apt/sources.list.d/odoo.list
apt-get update && apt-get install odoo -y
systemctl enable odoo


# Install Nginx
apt install nginx -y
systemctl enable nginx


# Install Certbot
apt install certbot -y


# Generate Diffie-Hellman
openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048


# Make directory to map all HTTP requests and change permissions to allow Nginx access
sudo mkdir -p /var/lib/letsencrypt/.well-known
sudo chgrp www-data /var/lib/letsencrypt
sudo chmod g+s /var/lib/letsencrypt


# Create letsencrypt snippet
echo "location ^~ /.well-known/acme-challenge/ {
  allow all;
  root /var/lib/letsencrypt/;
  default_type \"text/plain\";
  try_files $uri =404;
}" > /etc/nginx/snippets/letsencrypt.conf


# Create ssl snippet
echo "ssl_dhparam /etc/ssl/certs/dhparam.pem;

ssl_session_timeout 1d;
ssl_session_cache shared:SSL:10m;
ssl_session_tickets off;

ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
ssl_prefer_server_ciphers on;

ssl_stapling on;
ssl_stapling_verify on;
resolver 8.8.8.8 8.8.4.4 valid=300s;
resolver_timeout 30s;

add_header Strict-Transport-Security \"max-age=31536000; includeSubDomains\" always;
add_header X-Frame-Options SAMEORIGIN;
add_header X-Content-Type-Options nosniff;" > /etc/nginx/snippets/ssl.conf


# Include snippets in server block
echo "server {
  listen 80;
  server_name $WEBSITE_NAME www.$WEBSITE_NAME;

  include snippets/letsencrypt.conf;
}"


# link available website to enabled
ln -s /etc/nginx/sites-available/$WEBSITE_NAME.conf /etc/nginx/sites-enabled/


# Restart Nginx
systemctl restart nginx


# Get SSL certificates
sudo certbot certonly --agree-tos --email $ADMIN_EMAIL --webroot -w /var/lib/letsencrypt/ -d $WEBSITE_NAME -d www.$WEBSITE_NAME


# Add Odoo configuration to server block
echo "#odoo server
upstream odoo {
 server 127.0.0.1:8069;
}
upstream odoochat {
 server 127.0.0.1:8072;
}

# http -> https
server {
   listen 80;
   server_name $WEBSITE_NAME;
   rewrite ^(.*) https://$host$1 permanent;
}

server {
 listen 443;
 server_name $WEBSITE_NAME;
 proxy_read_timeout 720s;
 proxy_connect_timeout 720s;
 proxy_send_timeout 720s;

 # Add Headers for odoo proxy mode
 proxy_set_header X-Forwarded-Host $host;
 proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
 proxy_set_header X-Forwarded-Proto $scheme;
 proxy_set_header X-Real-IP $remote_addr;

 # SSL parameters
 ssl on;
 ssl_certificate /etc/letsencrypt/live/$WEBSITE_NAME/fullchain.pem;
 ssl_certificate_key /etc/letsencrypt/live/$WEBSITE_NAME/privkey.pem;
 ssl_session_timeout 30m;
 ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
 ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA';
 ssl_prefer_server_ciphers on;

 # log
 access_log /var/log/nginx/odoo.access.log;
 error_log /var/log/nginx/odoo.error.log;

 # Redirect longpoll requests to odoo longpolling port
 location /longpolling {
 proxy_pass http://odoochat;
 }

 # Redirect requests to odoo backend server
 location / {
   proxy_redirect off;
   proxy_pass http://odoo;
 }

 # common gzip
 gzip_types text/css text/scss text/plain text/xml application/xml application/json application/javascript;
 gzip on;
}" > /etc/nginx/sites-available/$WEBSITE_NAME.conf


# Configure odoo to use proxy
echo "proxy_mode = True" >> /etc/odoo/odoo.conf
