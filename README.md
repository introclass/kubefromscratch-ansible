---
layout: default
title:  README
author: lijiaocn
createdate: 2018/03/15 21:23:00
changedate: 2018/08/19 11:49:45

---

## 使用

使用ansible部署[kubefromscratch](https://github.com/introclass/kubefromscratch)。

使用yum安装Docker，可能会因为qiang的原因，安装失败，需要提前下载rpm：

	mkdir -p roles/docker/files/
	pushd roles/docker/files/
	wget https://download.docker.com/linux/centos/7/x86_64/stable/Packages/docker-ce-18.03.1.ce-1.el7.centos.x86_64.rpm
	popd

### 安装依赖包

后续的操作会用pip安装依赖的python包，创建独立的python运行环境：

	virtualenv env
	source env/bin/activate
	pip install -r requirements.txt

在virtualenv创建的python运行环境中，执行后续的操作。

### 节点准备

先确保本地有ssh证书：

	$ ssh-keygen
	Generating public/private rsa key pair.
	Enter file in which to save the key (/Users/lijiao/.ssh/id_rsa):
	...

在inventories/staging/hosts中配置使用的机器。

ssh登陆证书上传、依赖软件安装：

	ansible-playbook -u root -k -i inventories/staging/hosts prepare.yml

之后可以直接使用root用户，免密码：

	ansible all -u root -i inventories/staging/hosts -m command -a "pwd"

### 代码编译

代码编译过程会比较慢，本机器上需要安装有`docker`、`git`，并能拉取编译镜像和github代码：

	ansible-playbook -i inventories/staging/hosts build.yml

如果执行出错，可以到`./out/build/build-XXX`中分别对每个组件进行build，例如：

	pushd output/build/; 
	for i in build-cni-plugins build-cni build-etcd build-kube-router build-kubernetes
	do
		pushd $i
		./build.sh
		popd
	done
	popd

### 证书生成

	ansible-playbook -i inventories/staging/hosts gencerts.yml

### 远程部署

	ansible-playbook -u root -i inventories/staging/hosts site.yml

### 本地部署管理员文件

	ansible-playbook -u root -i inventories/staging/hosts cli.yml

### 安装插件

[kubernetes/cluster/addons](https://github.com/kubernetes/kubernetes/tree/master/cluster/addons)中一些可以在Kubernetes中安装的addons。

	$ cd output/build/build-kubernetes/kubernetes/cluster/addons/
	BUILD                     cluster-loadbalancing     dns-horizontal-autoscaler ip-masq-agent             node-problem-detector     registry
	README.md                 cluster-monitoring        etcd-empty-dir-cleanup    kube-proxy                podsecuritypolicies       storage-class
	addon-manager             dashboard                 fluentd-elasticsearch     metadata-proxy            python-image
	calico-policy-controller  dns                       fluentd-gcp               metrics-server            rbac

#### 安装kube-dns

下面演示的是1.8.0版本中的kube-dns的安装，更高版本的目录有所不同。

先创建ServiceAccount和ConfigMap：

	$ ./kubectl.sh create -f ~/kubefromscratch-ansible/output/build/build-kubernetes/kubernetes/cluster/addons/dns/kubedns-sa.yaml
	$ ./kubectl.sh create -f ~/kubefromscratch-ansible/output/build/build-kubernetes/kubernetes/cluster/addons/dns/kubedns-cm.yaml

然后生成`kubedns-controller.yaml`和`kubedns-svc.yaml`：

	//mac上需要安装有gettext
	brew install -y gettext
	echo 'export PATH="/usr/local/opt/gettext/bin:$PATH"' >> ~/.zshrc  #或者~/.bash_profile
	
	export DNS_DOMAIN=cluster.local
	export DNS_SERVER_IP=172.16.0.2
	cat ~/kubefromscratch-ansible/..省略../addons/dns/kubedns-controller.yaml.sed |  envsubst >/tmp/kubedns-controller.yaml
	cat ~/kubefromscratch-ansible/..省略...addons/dns/kubedns-svc.yaml.sed        |  envsubst >/tmp/kubedns-svc.yaml

上面的`DNS_DOMAIN`、`DNS_SERVER_IP`分别与kubelet的`--cluster-domain`、`--cluster-dns`参数配置相同。

分别创建：

	./kubectl.sh create -f /tmp/kubedns-controller.yaml
	./kubectl.sh create -f /tmp/kubedns-svc.yaml

### 管理操作

启动集群:

	ansible-playbook -u root -i inventories/staging/hosts start.yml

关闭集群:

	ansible-playbook -u root -i inventories/staging/hosts stop.yml

查看etcd中的数据：

	cd /opt/app/k8s/etcd
	./etcdctl3.sh get /kubernetes --prefix  --keys-only

这里使用的是etcd v3，在v3中没有了`目录`的概念，可以用下面的方式获取指定前缀的key：

	$ ./etcdctl3.sh get /kubernetes/services --prefix  --keys-only
	/kubernetes/services/endpoints/default/kubernetes
	/kubernetes/services/endpoints/kube-system/kube-controller-manager
	/kubernetes/services/endpoints/kube-system/kube-scheduler
	/kubernetes/services/specs/default/kubernetes

用`get`命令读取key的值，`-w`指定输出格式：

	./etcdctl3.sh get /kubernetes/services/endpoints/kube-system/kube-scheduler -w json
	./etcdctl3.sh get /kubernetes/services/endpoints/kube-system/kube-scheduler -w fields

### 使用Kubernetes

使用集群管理员身份操作：

	$ cd /opt/app/k8s/admin
	$ git clone https://github.com/introclass/kubernetes-yamls
	$ ./kubectl.sh create -f kubernetes-yamls/api-v1-example/namespace.json
	$ ./kubectl.sh get ns
	$ ./kubectl.sh create -f  kubernetes-yamls/api-v1-example/webshell-rc.json
	$ ./kubectl.sh get pod -n demo1

如果有需要，可以将集群管理员的kubeconfig.yml转换成json格式：

	$ yum install -y python2-pip
	$ pip install yq
	$ bash kubeconfig-single.sh
	$ cat kubeconfig-single.yml | yq . >kubeconfig-single.json

然后将配置文件直接复制到~/.kube目录中，用于其它的kuberntes配套工具：

	$ ln -s /opt/app/k8s/admin/kubeconfig-single.yml ~/.kube/config
	$ kubectl config view
	apiVersion: v1
	clusters:
	- cluster:
	    certificate-authority-data: REDACTED
	    server: https://10.39.0.121
	  name: secure
	contexts:
	- context:
	    cluster: secure
	    namespace: default
	    user: admin
	  name: secure.admin.default
	current-context: secure.admin.default
	kind: Config
	preferences:
	  colors: true
	users:
	- name: admin
	  user:
	    client-certificate-data: REDACTED
	    client-key-data: REDACTED

然后可以尝试用[ https://kubernetic.com/ ](https://kubernetic.com/)管理Kubernetes集群。

