#!/usr/bin/env bash

CLONE_DIR="/home/pi/odoo"
rm -rf "${CLONE_DIR}"

mkdir -p  "${CLONE_DIR}"
wget https://github.com/odoo/odoo/archive/9.0.zip
unzip 9.0.zip
cp -r odoo-9.0/addons/web ${CLONE_DIR}/addons
cp -r odoo-9.0/addons/web_kanban ${CLONE_DIR}/addons
cp -r odoo-9.0/addons/hw_* ${CLONE_DIR}/addons
cp -r odoo-9.0/addons/point_of_sale/tools/posbox/configuration ${CLONE_DIR}/addons
cp -r odoo-9.0/openerp/ ${CLONE_DIR}/
cp -r odoo-9.0/odoo.py ${CLONE_DIR}/
rm -rf 9.0.zip
rm -rf odoo-9.0

wget https://github.com/AwesomeFoodCoops/odoo-production/archive/9.0.zip
unzip 9.0.zip
cp -r odoo-production-9.0/extra_addons/hw_* ${CLONE_DIR}/addons
cp -r odoo-production-9.0/OCA_addons/hw_* ${CLONE_DIR}/addons
cp -r odoo-production-9.0/louve_addons/hw_* ${CLONE_DIR}/addons
cp -r odoo-production-9.0/intercoop_addons/hw_* ${CLONE_DIR}/addons
rm -rf 9.0.zip
rm -rf odoo-production-9.0

sudo reboot
