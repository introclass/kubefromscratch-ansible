---
layout: default
title:  README
author: lijiaocn
createdate: 2018/03/15 21:23:00
changedate: 2018/03/21 18:53:52

---

## 可选操作

创建python运行环境：

	virtualenv env

进入virtualenv创建的python运行环境：

	source env/bin/activate

## 证书上传

ssh登陆证书上传：

	ansible-playbook -u vagrant -k -i inventories/staging/hosts remote.yml

之后可以直接使用root用户，免密码：

	ansible all -u root -i inventories/staging/hosts -m command -a "pwd"

## 代码编译

	ansible-playbook -i inventories/staging/hosts build.yml

## 证书生成

	ansible-playbook -i inventories/staging/hosts localhost.yml

## 远程部署

	ansible-playbook -u root -i inventories/staging/hosts site.yml
