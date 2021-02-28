#!/bin/sh

echo "======Updating and upgrading OS======"
apt-get update -y && apt-get upgrade -y

echo "======Installing and configuring postgresql to run on startup======"
apt install posgresql -y
systemctl enable postgresql

echo "======Installing and configuring odoo to run on startup======"
wget -O - https://nightly.odoo.com/odoo.key | apt-key add -
echo "deb http://nightly.odoo.com/14.0/nightly/deb/ ./" >> /etc/apt/sources.list.d/odoo.list
apt-get update && apt-get install odoo
systemctl enable odoo

echo "======Installing and configuring Nginx to run on startup======"
apt install nginx
systemctl enable nginx
