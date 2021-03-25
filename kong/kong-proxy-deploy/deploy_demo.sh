#! /bin/sh
#
# deploy_demo.sh
# Copyright (C) 2018 lijiaocn <lijiaocn@foxmail.com>
#
# Distributed under terms of the GPL license.
#

ansible-playbook -i inventories/demo/hosts -u root kong-proxy.yml
