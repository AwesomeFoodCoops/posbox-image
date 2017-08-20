#!/usr/bin/env bash

PI_DIR="/home/pi"
CLONE_DIR="$PI_DIR/odoo"
rm -rf "${CLONE_DIR}"

mkdir -p  "${CLONE_DIR}"

wget https://github.com/AwesomeFoodCoops/odoo-production/archive/9.0.zip
unzip 9.0.zip

cp -r odoo-production-9.0/odoo/addons/web ${CLONE_DIR}/addons/
cp -r odoo-production-9.0/odoo/addons/web_kanban ${CLONE_DIR}/addons/
cp -r odoo-production-9.0/odoo/addons/hw_* ${CLONE_DIR}/addons/
cp -r odoo-production-9.0/odoo/addons/point_of_sale/tools/posbox/configuration ${CLONE_DIR}/addons/
cp -r odoo-production-9.0/odoo/openerp ${CLONE_DIR}/
cp -r odoo-production-9.0/odoo/odoo.py ${CLONE_DIR}/

cp -r odoo-production-9.0/extra_addons/hw_* ${CLONE_DIR}/addons/
cp -r odoo-production-9.0/OCA_addons/hw_* ${CLONE_DIR}/addons/
cp -r odoo-production-9.0/louve_addons/hw_* ${CLONE_DIR}/addons/
cp -r odoo-production-9.0/intercoop_addons/hw_* ${CLONE_DIR}/addons/
rm -rf 9.0.zip
rm -rf odoo-production-9.0

cd ${PI_DIR}
rm -rf update_posbox.sh
wget https://raw.githubusercontent.com/AwesomeFoodCoops/posbox-image/master/overwrite_before_init/home/pi/update_posbox.sh

sudo reboot
