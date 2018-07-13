---
layout: default
title:  README
author: lijiaocn
createdate: 2018/03/15 21:23:00
changedate: 2018/07/13 15:05:39

---

## 使用

使用ansible部署[kubefromscratch](https://github.com/introclass/kubefromscratch)。

使用yum安装Docker，可能会因为qiang的原因，安装失败，需要提前下载rpm：

	cd roles/docker/files/
	wget https://download.docker.com/linux/centos/7/x86_64/stable/Packages/docker-ce-18.03.1.ce-1.el7.centos.x86_64.rpm

### 安装依赖包

后续的操作会用pip安装依赖的python包，一个创建python运行环境：

	virtualenv env
	source env/bin/activate
	pip install -r requirements.txt

在virtualenv创建的python运行环境中，执行后续的操作。

### 节点准备

ssh登陆证书上传、依赖软件安装：

	ansible-playbook -u root -k -i inventories/staging/hosts prepare.yml

之后可以直接使用root用户，免密码：

	ansible all -u root -i inventories/staging/hosts -m command -a "pwd"

### 代码编译

	ansible-playbook -i inventories/staging/hosts build.yml

### 证书生成

	ansible-playbook -i inventories/staging/hosts gencerts.yml

### 远程部署

	ansible-playbook -u root -i inventories/staging/hosts site.yml

### 管理操作

启动集群:

	ansible-playbook -u root -i inventories/staging/hosts start.yml

关闭集群:

	ansible-playbook -u root -i inventories/staging/hosts stop.yml

### 使用Kubernetes

使用集群管理员身份操作：

	$ cd /opt/app/k8s/admin
	$ git clone https://github.com/introclass/kubernetes-yamls
	$ ./kubectl.sh create -f kubernetes-yamls/api-v1-example/namespace.json
	$ ./kubectl.sh get ns

将集群管理员的kubeconfig.yml转换成json格式：

	$ yum install -y python2-pip
	$ pip install yq
	$ bash kubeconfig-single.sh
	$ cat kubeconfig-single.yml | yq . >kubeconfig-single.json