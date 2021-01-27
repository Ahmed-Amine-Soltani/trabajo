# Installing and testing [Helm](https://helm.sh/docs/intro/install/) 3



##### Installing Helm 3

To download helm using shell script (they are [other](https://helm.sh/docs/intro/install/) options that can be used)

```bash
$ curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
$ chmod 700 get_helm.sh
$ ./get_helm.sh
```

##### Testing helm 3

To add the repository leadwire-test 

```bash
$ helm repo add leadwire-test  https://raw.githubusercontent.com/Ahmed-Amine-Soltani/markdown-language-demo/master
$ helm search repo nginx
NAME            CHART VERSION   APP VERSION     DESCRIPTION                                     
leadwire-test/nginx   0.1.0                     Nginx LeadWire helm test
```

To download the chart nginx from leadwire-test repository and untar it

```bash
$ helm fetch --untar nginx leadwire-test/nginx
$ ls
nginx
```

To install a new package, use the helm install command, at its simplest, it takes two arguments: a release name that you pick, and the name of the chart you want to install.

```bash
$ helm install release-name ./nginx
$ helm ls 
NAME         NAMESPACE       REVISION        UPDATED                                   STATUS          CHART           APP VERSION
release-name default         1               2020-12-29 01:19:35.446686171 +0100 CET   deployed        nginx-0.1.0       
```

