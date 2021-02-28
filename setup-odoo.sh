#!/bin/sh

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
