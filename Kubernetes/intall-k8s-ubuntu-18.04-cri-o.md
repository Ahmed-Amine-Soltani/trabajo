Commands used in the Video:
=========================
1.Update the package repository (All hosts)
sudo apt-get update

2. Install Docker (All hosts)
sudo apt-get install docker.io -y

3. Access Repos via HTTPS (All hosts)
sudo apt-get install apt-transport-https curl -y

4. Add K8S key and Repo (All hosts)
curl -s https://packages.cloud.google.com/apt... | sudo apt-key add -
cat (ADD 2 "LESS THAN" SIGNS HERE WITHOUT BRACKETS)EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

5. Update the package repository and Install K8S components (All hosts):
sudo apt-get update
sudo apt-get install -y kubelet=1.18.1-00 
sudo apt-get install -y kubeadm=1.18.1-00 
sudo apt-get install -y kubectl=1.18.1-00
sudo apt-mark hold kubelet kubeadm kubectl

6. Add the hosts entry (All hosts)
edit the file "/etc/hosts"

7. Disable SWAP (All hosts)
sudo swapoff -a
edit /etc/fstab to remove the swap entry

8. Initiate the Cluster(Only on Master node)
sudo kubeadm init --control-plane-endpoint kube-master:6443 --pod-network-cidr 10.10.0.0/16

9. Set the kubectl context auth to connect to the cluster(Only on Master node)
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

10. Pod Network Addon(Calico) (Only on Master node)
Ref: https://docs.projectcalico.org/gettin...
curl https://docs.projectcalico.org/manife... -O
vi calico.yaml

11. Generate Token to add worker Node(Only on Master node)
#Create a new Token
sudo kubeadm token create
#List Tokens created
sudo kubeadm token list
#Find Certificate Hash on Master
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | 
   openssl rsa -pubin -outform der 2(GREATER THAN SYMBOL)/dev/null | 
   openssl dgst -sha256 -hex | sed 's/^.* //'

12. Join Nodes (Only on Worker nodes)
sudo kubeadm join --token TOKEN_ID CONTROL_PLANE_HOSTNAME:CONTROL_PLANE_PORT --discovery-token-ca-cert-hash sha256:HASH
(Formed using outputs from step 10, treat CAPS as variables to be replaced)

13. Want to run workloads on Master?(Only on Master Node)
kubectl taint nodes --all node-role.kubernetes.io/master-

14. Sample Deployment file:
=========================
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
=========================

15. Apply the deployment:
kubectl apply -f FILE_NAME
