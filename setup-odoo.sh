sudo su

apt-get update -y && apt-get upgrade -y

apt install posgresql -y
systemctl enable postgresql

wget -O - https://nightly.odoo.com/odoo.key | apt-key add -
echo "deb http://nightly.odoo.com/14.0/nightly/deb/ ./" >> /etc/apt/sources.list.d/odoo.list
apt-get update && apt-get install odoo

systemctl enable odoo

apt install nginx
