#!/usr/bin/env bash

CLONE_DIR="/home/pi/odoo"
rm -rf "${CLONE_DIR}"

mkdir -p  "${CLONE_DIR}"
git clone -b 8.0 --no-checkout --depth 1 https://github.com/odoo/odoo.git "${CLONE_DIR}"
cd "${CLONE_DIR}"
git config core.sparsecheckout true
echo "addons/web
addons/web_kanban
addons/hw_*
addons/point_of_sale/tools/posbox/configuration
openerp/
odoo.py" | tee --append .git/info/sparse-checkout > /dev/null
git read-tree -mu HEAD

wget https://github.com/AwesomeFoodCoops/odoo-production/archive/9.0.zip
unzip 9.0.zip
cp -r odoo-production-9.0/extra_addons/hw_* ${CLONE_DIR}/addons
cp -r odoo-production-9.0/OCA_addons/hw_* ${CLONE_DIR}/addons
cp -r odoo-production-9.0/louve_addons/hw_* ${CLONE_DIR}/addons
cp -r odoo-production-9.0/intercoop_addons/hw_* ${CLONE_DIR}/addons
rm -rf 9.0.zip
rm -rf odoo-production-9.0
