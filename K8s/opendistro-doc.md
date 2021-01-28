Install and Configure Opendistro for Elasticsearch using Helm



```bash
$ git clone https://github.com/opendistro-for-elasticsearch/opendistro-build
```

```bash
$ cd opendistro-build/helm
```

```bash
$ helm install release-name ./opendistro-es/
```



```bash
$ helm ls 
NAME                      NAMESPACE   REVISION    UPDATED                                  STATUS       CHART                 APP VERSION
opendistro-es-1609765240  default      2          2021-01-04 14:04:02.933910016 +0100 CET  deployed    opendistro-es-1.12.0   1.12.0 
```





```bash
$ kubectl get pods 
NAME                                               READY   STATUS    RESTARTS   AGE
opendistro-es-1609765240-client-6696d66589-t72ch   1/1     Running   0          6h55m
opendistro-es-1609765240-data-0                    1/1     Running   0          6h58m
opendistro-es-1609765240-kibana-b7bf67fb-jr49w     1/1     Running   0          6h58m
opendistro-es-1609765240-master-0                  1/1     Running   0          6h58m

```

