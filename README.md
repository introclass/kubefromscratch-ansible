---
layout: default
title:  README
author: lijiaocn
createdate: 2018/03/15 21:23:00
changedate: 2018/08/19 11:49:45

---

## 说明

这套ansible脚本使用[kubefromscratch](https://github.com/introclass/kubefromscratch)项目master分支中选定的代码版本，并用其中的编译脚本完成kubernetes集群各个组件的编译。

如果要更换版本，修改roles/build/tasks/main.yml文件中的version：

	- name: checkout
	  tags: build
	  git:
	      repo: https://github.com/lijiaocn/kubefromscratch.git
	      dest: "{{ build_path }}"
	      version: master
	      force: yes

这套脚本适用的操作系统是CentOS 7。

## 使用前准备

使用yum安装Docker，可能会因为qiang的原因安装失败，因此这套脚本采用提前下载docker的rpm，将docker的rpm上传的方式安装，需要事先将docker的rpm下载到下面的目录中：

	mkdir -p roles/docker/files/
	pushd roles/docker/files/
	wget https://download.docker.com/linux/centos/7/x86_64/stable/Packages/docker-ce-18.03.1.ce-1.el7.centos.x86_64.rpm
	popd

docker的版本没有严格论证，请根据自己的需要选取。

创建独立的python运行环境，在virtualenv创建的python运行环境中，执行后续的操作：

	virtualenv env
	source env/bin/activate
	pip install -r requirements.txt

本地机器上需要安装有`docker`、`git`，并能联网拉取docker镜像和github代码。

### 代码编译

使用下面的命令直接编译所有代码：

	ansible-playbook -i inventories/staging/hosts build.yml

编译过程中拉取指定版本的代码、生成编译镜像，时间会比较长，特别是编译kubernetes的时候。

如果执行出错，可以到`./out/build/build-XXX`中对每个组件进行单独编译，例如：

	pushd output/build/; 
	for i in build-cni-plugins build-cni build-etcd build-kube-router build-kubernetes
	do
		pushd $i
		./build.sh
		popd
	done
	popd

一定要确保所有组件都成功编译。

编译使用的目录`./out/build`中，是[kubefromscratch](https://github.com/introclass/kubefromscratch)项目中的文件。

## 机器初始化

先确保本地有ssh证书，如果没有则生成：

	$ ssh-keygen
	Generating public/private rsa key pair.
	Enter file in which to save the key (/Users/lijiao/.ssh/id_rsa):
	...

在inventories/staging/hosts中，根据自己的情况编排集群。

下面的操作将ssh登陆证书上传到机器、并安装依赖软件、设置时区等：

	ansible-playbook -u root -k -i inventories/staging/hosts prepare.yml

确保可以直接使用root用户免密码登录所有机器：

	ansible all -u root -i inventories/staging/hosts -m command -a "pwd"

## 证书生成

这一步操作会为Kubernetes集群的所有的组件生成需要的证书：

	ansible-playbook -i inventories/staging/hosts gencerts.yml

## 部署系统

这一步操作在目标机器上部署kubernetes集群：

	ansible-playbook -u root -i inventories/staging/hosts site.yml

## 管理员文件

这一步操作在其它机器上部署kubernetes集群的管理员文件：

	ansible-playbook -u root -i inventories/staging/hosts cli.yml

## 安装插件

前面部署的是一个最精简的Kubernetes集群，其它功能用插件的方法部署，管理起来会更方便，现在有很多可以用于Kubernetes的项目也是直接以插件形式发布的。

[kubernetes/cluster/addons](https://github.com/kubernetes/kubernetes/tree/master/cluster/addons)中是一些可以在Kubernetes中安装的addons。

	$ cd output/build/build-kubernetes/kubernetes/cluster/addons/
	BUILD                     cluster-loadbalancing     dns-horizontal-autoscaler ip-masq-agent             node-problem-detector     registry
	README.md                 cluster-monitoring        etcd-empty-dir-cleanup    kube-proxy                podsecuritypolicies       storage-class
	addon-manager             dashboard                 fluentd-elasticsearch     metadata-proxy            python-image
	calico-policy-controller  dns                       fluentd-gcp               metrics-server            rbac

### 安装kube-dns

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

## 管理操作

启动集群:

	ansible-playbook -u root -i inventories/staging/hosts start.yml

关闭集群:

	ansible-playbook -u root -i inventories/staging/hosts stop.yml

查看etcd中的数据，登录到部署了etcd的机器上操作，使用的是etcd v3，在v3中没有了`目录`的概念，可以用下面的方式获取指定前缀的key：

	$ cd /opt/app/k8s/etcd
	$ ./etcdctl3.sh get /kubernetes --prefix  --keys-only
	/kubernetes/services/endpoints/default/kubernetes
	/kubernetes/services/endpoints/kube-system/kube-controller-manager
	/kubernetes/services/endpoints/kube-system/kube-scheduler
	/kubernetes/services/specs/default/kubernetes
	...

用`get`命令读取key的值，`-w`指定输出格式：

	./etcdctl3.sh get /kubernetes/services/endpoints/kube-system/kube-scheduler -w json
	./etcdctl3.sh get /kubernetes/services/endpoints/kube-system/kube-scheduler -w fields

使用集群管理员身份操作集群，登录到安装了管理员文件的机器上操作：

	$ ./kubectl.sh get cs
	NAME                 STATUS    MESSAGE              ERROR
	scheduler            Healthy   ok
	controller-manager   Healthy   ok
	etcd-0               Healthy   {"health": "true"}

[kubernetes-yamls][https://github.com/introclass/kubernetes-yamls]中有几个yaml文件，可以将部署到kubernetes集群中验证一下：

	$ cd /opt/app/k8s/admin
	$ git clone https://github.com/introclass/kubernetes-yamls
	$ ./kubectl.sh create -f kubernetes-yamls/api-v1-example/namespace.json
	$ ./kubectl.sh get ns
	$ ./kubectl.sh create -f  kubernetes-yamls/api-v1-example/webshell-rc.json
	$ ./kubectl.sh get pod -n demo1

可以用下面的方式将集群管理员的kubeconfig.yml以及证书打包到一个文件中，方便提供给其他用户使用：

	$ bash kubeconfig-single.sh

执行后会得到一个`kubeconfig-single.yml`文件，可以用下面的方式将其转换为json格式：

	$ yum install -y python2-pip
	$ pip install yq
	$ bash kubeconfig-single.sh
	$ cat kubeconfig-single.yml | yq . >kubeconfig-single.json

譬如将配置文件直接链接或复制到~/.kube目录中，便可以在任意位置使用kubectl操作：

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

以及供其它kuberntes配套工具使用，譬如[kubernetic](https://kubernetic.com/)。
