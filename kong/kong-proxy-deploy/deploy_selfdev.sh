#! /bin/sh
#
# deploy_demo.sh
# Copyright (C) 2018 lijiaocn <lijiaocn@foxmail.com>
#
# Distributed under terms of the GPL license.
#
x=`date +"%y-%m-%d-%s"`
ansible-playbook -e "DATE=\'$x\'" -i inventories/development/hosts -u root kong-proxy.yml
