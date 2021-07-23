# <p align="center"> Installing and Making Kubernetes Cluster on Centos 7 with kubeadm </p>

<p align="center"><img  src="https://img.icons8.com/color/48/000000/kubernetes.png" /> <img  src="https://img.icons8.com/color/48/000000/centos.png" />               </p>



## Prepare Kubernetes Servers , the following commands need to be run on all machines.

Become root and update and upgrade the system.

```bash
$ yum -y update && yum upgrade -y
```

Add a local DNS alias for our master server. Edit /etc/hosts file (comment the line that begins with 127.0.1.1 + host name)

```bash
$ echo "
master-ip-address k8s-master-1   # change master-ip-address with your master node ip
worker-ip-address k8s-worker-1   # change worker-ip-address with your worker node ip
           ...
           ...
" >> /etc/hosts
```

Disable SELinux 

```bash
$ setenforce 0
$ sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
```

Turn off swap

```bash
$ sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
$ swapoff -a
```

**Reboot** the system in order to apply the swapoff and SELinux settings , once the system boots up, verify the change with the `sestatus` and `free -h` commands

```bash
$ shutdown -r now

$ free -h
              total        used        free      shared  buff/cache   available
Mem:           4.7G        265M        4.1G        8.6M        312M        4.2G
Swap:            0B          0B          0B
$ sestatus 
SELinux status:                 disabled
```

Install bridge if not exist and enable it

```bash
# install bridge if not exist 
$ yum install bridge-utils.x86_64 -y
# enable bridge-netfilter
```

Letting iptables see bridged traffic , make sure that the `br_netfilter` and `overlay` modules are loaded. This can be done by running :

```bash
$ lsmod | grep overlay 
$ lsmod | grep br_netfilter 
```

To load them explicitly call :

```bash
$ cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

$ modprobe overlay
$ modprobe br_netfilter
```

As a requirement for your Linux Node's iptables to correctly see bridged traffic , you should `ensurenet.ipv4.ip_forward` , `net.bridge.bridge-nf-call-iptables` and `net.bridge.bridge-nf-call-iptables` are set to 1 in your `sysctl` config :

```bash
# Enable IP Forwarding
$ cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
# Reload configs
$ sysctl --system
# to verify
$ cat /proc/sys/net/bridge/bridge-nf-call-ip6tables
1
$ cat /proc/sys/net/bridge/bridge-nf-call-iptables
1
$ sysctl net.ipv4.ip_forward
net.ipv4.ip_forward = 1

```



#### **Installing** Container runtime

Install **[containerd](https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd)** :

```bash
# Install required packages
$ yum install -y yum-utils device-mapper-persistent-data lvm2

# Add docker repository ( it is necessary for the installation of containerd.io )
$ yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Install containerd
$ yum update -y && sudo yum install -y containerd.io

# Configure containerd
$ mkdir -p /etc/containerd
$ containerd config default > /etc/containerd/config.toml

# Restart containerd
$ systemctl restart containerd

# Enable containerd
$ systemctl enable containerd
```

##### to install [crictl](https://github.com/kubernetes-sigs/cri-tools)
Add /etc/crictl.yaml configuration :

```bash
runtime-endpoint: "unix:///run/containerd/containerd.sock"
image-endpoint: "unix:///run/containerd/containerd.sock"
timeout: 10
debug: false
```

#### Install Kubernetes with [Kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)

Add the repository info for yum in /etc/yum.repos.d/kubernetes.repo : 

```bash
$ cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

# Update with the new repo declared, which will download updated repo information.
$ yum update -y
```

Install and enable Kubernetes services

```bash
$ yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
# to install a specific version of kubernetes yum install -y kubelet-<version> kubectl-<version> kubeadm-<version>
# example : yum install  kubelet-1.20.0-0 kubectl-1.20.0-0 kubeadm-1.20.0-0 --disableexcludes=kubernetes
$ systemctl enable --now kubelet
```




#### Setup firewall rules , Check required ports 

Ensure that your hosts and firewalls allow the necessary traffic based on your configuration.

**On Master Nodes** open the following ports and restart the service

```bash
# kubernetes https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#check-required-ports
[lw-k8s-master-1]$ firewall-cmd --permanent --add-port={6443,2379-2380,10250,10251,10252}/tcp 
# calico https://docs.projectcalico.org/getting-started/kubernetes/requirements
[lw-k8s-master-1]$ firewall-cmd --add-port={5473,179}/tcp --permanent
[lw-k8s-master-1]$ firewall-cmd --add-port=4789/udp --permanent
[lw-k8s-master-1]$ firewall-cmd --reload
```

**On Worker Nodes** open the following ports and restart the service

```bash
[lw-k8s-worker-1]$ firewall-cmd --add-port={10250,30000-32767}/tcp --permanent
[lw-k8s-worker-1]$ firewall-cmd --add-port={5473,179}/tcp --permanent
[lw-k8s-worker-1]$ firewall-cmd --add-port=4789/udp --permanent
[lw-k8s-worker-1]$ firewall-cmd --reload
```



​                 

## [Initialize](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/) Kubernetes Master , the following commands need to be run on the master.

Create a configuration file for the cluster. There are many options we could include, but will only set the control plane
endpoint, software version to deploy and podSubnet values. 

```bash
$ vim kubeadm-config.yaml
```

```yaml
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
kubernetesVersion: 1.20.0                        #<-- Use the word stable for newest version
controlPlaneEndpoint: "lw-k8s-master-1:6443"     #<-- Use the node alias not the IP
networking:
  podSubnet: 172.16.0.0/12                       #<-- Match the IP range from the Calico config file
  serviceSubnet: 10.0.0.0/24    
```

​            

Create a configuration file for the cluster .To configure [cgroup driver](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#configure-cgroup-driver-used-by-kubelet-on-control-plane-node)  , to pass your `cgroupDriver` value to `kubeadm init`

```bash
$ vim kubectl-config.yaml
```

```yaml
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
```



This could take a few minutes to complete. Once done, take note of the `token` and `discovery-token`

```bash
[lw-k8s-master-1]$ kubeadm init  --config=kubectl-config.yaml --config=kubeadm-config.yaml
[init] Using Kubernetes version: v1.20.0
...
...
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

You can now join any number of control-plane nodes by copying certificate authorities
and service account keys on each node and then running the following as root:

  kubeadm join lw-k8s-master-1:6443 --token ptpsml.0p5ah2mg9q25yzo8 \
    --discovery-token-ca-cert-hash sha256:555c0a155c9bb50b5dc84e339c8e0b9a0db417ca12b5cc4c9850bdd287992524 \
    --control-plane

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join lw-k8s-master-1:6443 --token ptpsml.0p5ah2mg9q25yzo8 \
    --discovery-token-ca-cert-hash sha256:555c0a155c9bb50b5dc84e339c8e0b9a0db417ca12b5cc4c9850bdd287992524

```

To start using your cluster

```bash
[lw-k8s-master-1]$ mkdir -p $HOME/.kube
[lw-k8s-master-1]$ cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
[lw-k8s-master-1]$ chown $(id -u):$(id -g) $HOME/.kube/config
```

Alternatively, if you are the root user, you can run:

```bash
[lw-k8s-master-1]$ export KUBECONFIG=/etc/kubernetes/admin.conf
```



#### Install network plugin [Calico](https://www.projectcalico.org/)

We need to configure a CNI plugin to enable cluster networking in kubernetes  , first download the yaml and change the CALICO_IPV4POOL_CIDR to the one you specified

```bash
[lw-k8s-master-1]$ yum install -y wget 
[lw-k8s-master-1]$ wget https://docs.projectcalico.org/manifests/calico.yaml
```

The CALICO_IPV4POOL_CIDR must match the value given to kubeadm init in the kubeadm-config.yaml file, whatever the value may be. Avoid conflicts with existing IP ranges of the instance.

```yaml
....
# The default IPv4 pool to create on startup if none exists. Pod IPs will be
# chosen from this range. Changing this value after installation will have
# no effect. This should fall within `--cluster-cidr`.
- name: CALICO_IPV4POOL_CIDR
  value: "172.16.0.0/12"
....
```

Apply the network plugin configuration to your cluster

```bash
[lw-k8s-master-1]$ kubectl apply -f calico.yaml
configmap/calico-config created
customresourcedefinition.apiextensions.k8s.io/felixconfigurations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ipamblocks.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/blockaffinities.crd.projectcalico.org created
...
```

##### To install [calicocli](https://docs.projectcalico.org/getting-started/clis/calicoctl/install)

#### Enable kubectl [auto-completion](https://kubernetes.io/docs/tasks/tools/included/optional-kubectl-configs-bash-linux/)
Install bash-completion
```bash
[lw-k8s-master-1]$ yum install bash-completion
```

Source the completion script in your `~/.bashrc` file:

```bash
[lw-k8s-master-1]$ echo 'source <(kubectl completion bash)' >>~/.bashrc
```

Add the completion script to the `/etc/bash_completion.d` directory:

```bash
[lw-k8s-master-1]$ kubectl completion bash >/etc/bash_completion.d/kubectl
```

you can extend shell completion to work with that alias:

```bash
[lw-k8s-master-1]$ echo 'alias k=kubectl' >>~/.bashrc
[lw-k8s-master-1]$ echo 'complete -F __start_kubectl k' >>~/.bashrc
[lw-k8s-master-1]$ source ~/.bashrc
```

to allow a non-root user admin level access to the cluster

```bash
[lw-k8s-master-1]$ su - user-name
[lw-k8s-master-1]$ mkdir -p $HOME/.kube
[lw-k8s-master-1]$ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
[lw-k8s-master-1]$ sudo chown $(id -u):$(id -g) $HOME/.kube/config
```



## Join the Workers , the following commands need to be run on the worker machines

Since your master plane is configured, you can go ahead and join any  number of worker nodes you need by running the join command 

```bash
[lw-k8s-worker-1]$ kubeadm join lw-k8s-master-1:6443 --token ptpsml.0p5ah2mg9q25yzo8 \
    --discovery-token-ca-cert-hash sha256:555c0a155c9bb50b5dc84e339c8e0b9a0db417ca12b5cc4c9850bdd287992524
```



```bash
# on master to craete a new join token
[lw-k8s-master-1]$ kubeadm token create 
[lw-k8s-master-1]$ kubeadm token list

# on master node to get Discovery Token CA Cert Hash as output
[lw-k8s-master-1]$ openssl x509 -pubkey \
-in /etc/kubernetes/pki/ca.crt | openssl rsa \
-pubin -outform der 2>/dev/null | openssl dgst \
-sha256 -hex | sed 's/ˆ.* //'
```



## Testing Configurations

Once everything is set, On **Master Node**  you have to test your cluster to see if it all  works out as expected. Simply run the following commands and check if it all works out.

```bash
[lw-k8s-master-1]$ kubectl cluster-info
Kubernetes control plane is running at https://lw-k8s-master-1:6443
KubeDNS is running at https://lw-k8s-master-1:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

Run `kubectl get nodes`, you will see all nodes status `READY`

```bash
[lw-k8s-master-1]$ kubectl get nodes -o wide
NAME              STATUS   ROLES                  AGE     VERSION   ...   CONTAINER-RUNTIME         
lw-k8s-master-1   Ready    control-plane,master   1h      v1.20.0   ...   containerd://1.4.3
lw-k8s-worker-1   Ready    <none>                 1h      v1.20.0   ...   containerd://1.4.3

```

Check status of pods

```bash
[lw-k8s-master-1]$ kubectl get pods --all-namespaces
NAMESPACE     NAME                                       READY   STATUS        RESTARTS   AGE
kube-system   calico-kube-controllers-744cfdf676-pp6kj   1/1     Running       0          1h
kube-system   calico-node-896t6                          1/1     Running       1          1h
kube-system   calico-node-lb4j9                          1/1     Running       0          1h
kube-system   coredns-74ff55c5b-7tqwn                    1/1     Running       0          1h
kube-system   coredns-74ff55c5b-flvkg                    1/1     Running       0          1h
kube-system   etcd-lw-k8s-master-1                       1/1     Running       0          1h
kube-system   kube-apiserver-lw-k8s-master-1             1/1     Running       0          1h
kube-system   kube-controller-manager-lw-k8s-master-1    1/1     Running       0          1h
kube-system   kube-proxy-4hpvc                           1/1     Running       1          1h
kube-system   kube-proxy-m5f6t                           1/1     Running       0          1h
kube-system   kube-scheduler-lw-k8s-master-1             1/1     Running       0          1h

```



## Deploy A Simple Application



We need to validate that our cluster is working by deploying a simple application. On **Master Node** create a new deployment

```bash
[lw-k8s-master-1]$ kubectl apply -f https://raw.githubusercontent.com/Ahmed-Amine-Soltani/trabajo/main/Kubernetes/deployment-test.yml
deployment.apps/nginx-deployment created
service/web created
```

Check deployments to verify if it is running

```bash
[lw-k8s-master-1]$ kubectl get deployment nginx-deployment
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   2/2     2            2           4m9s
```
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! old configuration !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
Check services

```bash
[lw-k8s-master-1]$ kubectl get service web 
NAME   TYPE       CLUSTER-IP   EXTERNAL-IP   PORT(S)          AGE
web    NodePort   10.0.0.241   <none>        8080:32144/TCP   22m
```

Check to see if pod started

```bash
[lw-k8s-master-1]$ kubectl get pod -o wide
NAME                   READY   STATUS    RESTARTS   AGE   IP              NODE              NOMINATED NODE   READINESS GATES
web-78449d97f9-xw77c   1/1     Running   0          26m   172.23.51.135   lw-k8s-worker-1   <none>           <none>

```

Test the deployment 

```bash
[lw-k8s-master-1]$ curl lw-k8s-worker-1:32144
Hello Kubernetes bootcamp! | Running on: web-78449d97f9-xw77c | v=1
```
