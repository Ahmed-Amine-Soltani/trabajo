# Selected technologies to prepare the infrastructure

in order to prepare the infrastructure we decided to choose the following technologies



### Operating System 

Operating System to use for clusters hosting : CentOS 7 (CentOS 7 End Of Life is scheduled for 2024)



### Orchestration

For the orchestration of containers :  we decided to use Kubernetes ,  [version 1.20](https://kubernetes.io/blog/2020/12/08/kubernetes-1-20-release-announcement/) : In [Kubernetes-Doc.md](https://github.com/leadwire-apm/leadwire-deploy-k8s/blob/main/kubernetes-doc.md) we used **kubeadm**  the community-suggested tool from  the Kubernetes project, that makes installing Kubernetes easy and avoids vendor-specific installers. Getting a cluster running involves two  commands: **kubeadm init**, that you run on one Master node, and then, **kubeadm join**, . The flexibility of these tools allows Kubernetes to  be deployed in a number of place



### Container runtime solution

For the container runtime solution - CRI  :  Docker as an underlying runtime is being [deprecated](https://kubernetes.io/blog/2020/12/02/dont-panic-kubernetes-and-docker/) as a container runtime after Kubernetes v1.20 ( to read more on this subject [link](https://dev.to/inductor/wait-docker-is-deprecated-in-kubernetes-now-what-do-i-do-e4m) ). So we decided to use **Containerd** , the commands to use containerd are very similar to those of docker , we just have to use [cri-tools](https://github.com/kubernetes-sigs/cri-tools)



### Cgroup driver

For the cgroup driver we choosed [systemd](https://stupefied-goodall-e282f7.netlify.app/contributors/design-proposals/node/kubelet-systemd/) : when systemd is chosen as the init system for a linux distribution. The init process generates and consumes a root cgroup and acts as a cgroup manager. Systemd has a tight integration with cgroups and will allocate cgroups per process. While it's possible to configure containerd and kubelet to use cgroupfs this means that there will then be two different cgroup managers. At the end of the day, cgroups are used to allocate and constrain resources that are allocated to processes. A single cgroup manager will simplify the view of what resources are being allocated and will by default have a more consistent view of the resources available / in use. When we have two managers we end up with two views of those available resources. We have seen cases in the field where nodes that are configured to use cgroupfs for kubelet and docker and systemd for the rest can become unstable under resource pressure. Changing the settings such that docker and kubelet use systems as a cgroup-driver stabilized the systems.



### Package manager

To install and manage applications on Kubernetes clusters , we have chosen helm [version 3](https://www.linode.com/docs/guides/how-to-install-apps-on-kubernetes-with-helm-3/)  , the most notable change in Helm 3 was the removal of Tiller . To install and test helm  : [Helm3-Doc.md](https://github.com/leadwire-apm/leadwire-deploy-k8s/blob/main/helm-doc.md)



### Network Plugin 

For the [Pod Networking Choices](https://kubernetes.io/docs/concepts/cluster-administration/networking/)  we decided to use **Calico**  : Calico is flat Layer 3 network which communicates without IP encapsulation, used in production with software such as Kubernetes, OpenShift, Docker, Mesos and OpenStack. Viewed as a simple and flexible networking model,  it scales well for large environments. Another network option, Canal,  also part of this project, allows for integration with [Flannel](https://coreos.com/flannel/docs/latest/). Allows  for implementation of network policies. For more details, check out the [Project Calico web page](https://www.projectcalico.org//).



<p align="center"> <img src="https://i.ibb.co/NYbgMw9/Screenshot-from-2021-01-04-19-12-07.png" alt="Screenshot-from-2021-01-04-19-12-07" border="0"> </p>











<p align="center"><img src="https://img.icons8.com/fluent/48/000000/high-priority.png"/> <img src="https://img.icons8.com/fluent/48/000000/high-priority.png"/>  <img src="https://img.icons8.com/fluent/48/000000/high-priority.png"/>  </p>

These need to be decided prior to initializing components and objects inside of your Kubernetes cluster . While you can change it after the fact , it's an awful lot of effort.