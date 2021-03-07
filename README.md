# [Odoo](https://www.odoo.com "Odoo's Homepage") Setup Script
A simple install script to get Odoo up and running with certbot and nginx

## Usage Instructions

##### 1. Download the script
```sh
wget https://raw.githubusercontent.com/c-eg/OdooSetup/main/odoo-setup.sh
```

##### 2. Modify the configuration parameters
```sh
nano odoo-setup.sh
```
- ```WEBSITE_NAME```: This should be set to the domain name you will be using e.g. example.com
- ```ADMIN_EMAIL```: This should be set to an email you want for certbot (SSL)

##### 3. Make the script executable
```sh
sudo chmod +x odoo-setup.sh
```

##### 4. Run the script as super user
```
sudo su
./odoo-setup.sh
```
