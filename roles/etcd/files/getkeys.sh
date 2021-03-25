#! /bin/sh
#
# getkeys.sh
# Copyright (C) 2019 lijiaocn <lijiaocn@foxmail.com>
#
# Distributed under terms of the GPL license.
#

./etcdctl3.sh get / --prefix  --keys-only
