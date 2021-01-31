## docker image toolbox-odfe

Dockerfile :

```dockerfile
FROM alpine:edge

# Configure Go
ENV GOROOT /usr/lib/go
ENV GOPATH /go
ENV PATH /go/bin:$PATH

# Configure opendistro
ENV ODFE_ENDPOINT https://localhost:9200
ENV ODFE_USER admin
ENV ODFE_PASSWORD admin

RUN apk add --no-cache --update npm musl-dev go openssl npm git curl jq
# Download and Build ODFE Command Line Interface
WORKDIR /go/src
RUN git clone https://github.com/opendistro-for-elasticsearch/odfe-cli
WORKDIR /go/src/odfe-cli
RUN go build .
RUN chmod +x ./odfe-cli
RUN ln -s /go/src/odfe-cli/odfe-cli /usr/local/bin/odfe-cli
# Install Performance Analyzer
RUN npm install -g @aws/opendistro-for-elasticsearch-perftop
# Generate node and client certificates script
WORKDIR /cert
RUN wget https://raw.githubusercontent.com/Ahmed-Amine-Soltani/trabajo/main/toolbox-for-odfe/gen-cert.sh
RUN chmod +x ./gen-cert.sh
```

Docker image :

```bash
$ docker image pull ahmedaminesoltani/leadwire-tests:toolbox-odfe-v3
```



Run your image as a container and attach it to the network of our odfe master containersetup

```bash
$ docker run -it --network container:odfe-node1 ahmedaminesoltani/leadwire-tests:toolbox-odfe-v3 /bin/sh
```

#### odfe-cli

odfe-cli officiel github repository [link](https://github.com/opendistro-for-elasticsearch/odfe-cli)

to test the integration of odfe-cli with odfe cluster  :

```bash
# environment variables must match your cluster configuration
$ echo $ODFE_ENDPOINT $ODFE_USER $ODFE_PASSWORD
https://localhost:9200 admin admin
$ cd /go/src/odfe-cli
/go/src/odfe-cli $ go test -tags=integration ./it/...
# expected output
go: downloading github.com/stretchr/testify v1.6.1
go: downloading github.com/pmezard/go-difflib v1.0.0
go: downloading github.com/davecgh/go-spew v1.1.1
ok      odfe-cli/it     9.872s
```

Create default profile

```bash
$ odfe-cli profile create
Enter profile\'s name: default
Elasticsearch Endpoint: https://localhost:9200  
User Name: admin
Password: admin
# to list existing profile
$ odfe-cli profile list -l
Name         UserName            Endpoint-url             
----         --------            ------------              
default      admin               https://localhost:9200  
```

usage

<p align="center"> <img  src="../images/test-ad-detectors.png" /> </p>

```bash
$ odfe-cli ad get test-ad-detectors --profile default > test.json
100.00% [=================================================] 1 / 1
$ cat test.json 
{
  "ID": "dg3qEXcBnlGgsewOh2Aj",
  "name": "test-ad-detectors",
  "description": "test anomaly detection odfe-cli",
  "time_field": "order_date",
  "indices": [
    "integration-test-ecommerce"
  ],
  "features": [
    {
      "feature_name": "test",
      "feature_enabled": true,
      "aggregation_query": {
        "test": {
          "sum": {
            "field": "total_quantity"
          }
        }
      }
    }
  ],
  "filter_query": {
    "match_all": {
      "boost": 1.0
    }
  },
  "detection_interval": "10m",
  "window_delay": "5m",
  "last_update_time": 1610914790942,
  "schema_version": 0
}
```

<p align="center"> <img  src="../images/test-ad-detectors-list.png" /> </p>

```bash
$ odfe-cli ad stop test-ad-detectors --profile default
1 detectors matched by name test-ad-detectors
test-ad-detectors
odfe will stop above matched detector(s). Do you want to proceed? Y/N Y
100.00% [=================================================] 1 / 1
$ odfe-cli ad delete test-ad-detectors --profile default
1 detectors matched by name test-ad-detectors
test-ad-detectors
odfe will delete above matched detector(s). Do you want to proceed? Y/N Y
100.00% [=================================================] 1 / 1
```

<p align="center"> <img  src="../images/test-ad-detectors-deleted.png" /> </p>



#### Performance Analyzer

Performance Analyzer officiel github repository [link](https://github.com/opendistro-for-elasticsearch/performance-analyzer) 

verify that performance-analyzer is actually enabled on your cluster. 

```bash
$ curl  https://localhost:9200/_opendistro/_performanceanalyzer/config -u admin:admin --insecure | jq
{
  "performanceAnalyzerEnabled": true,
  "rcaEnabled": false,
  "loggingEnabled": false,
  "shardsPerCollection": 0,
  "batchMetricsEnabled": false,
  "batchMetricsRetentionPeriodMinutes": 7
}
```

if the option is not activated , you can do this by issuing the following curl commands

```bash
$ curl  https://localhost:9200/_opendistro/_performanceanalyzer/config -u admin:admin --insecure | jq
{
  "performanceAnalyzerEnabled": false,
  "rcaEnabled": false,
  "loggingEnabled": false,
  "shardsPerCollection": 0,
  "batchMetricsEnabled": false,
  "batchMetricsRetentionPeriodMinutes": 7
}
# to enable the performance analyzer
$ curl https://localhost:9200/_opendistro/_performanceanalyzer/cluster/config -H 'Content-Type: application/json' -d '{"enabled": true}' -u admin:admin --insecure
$ curl  https://localhost:9200/_opendistro/_performanceanalyzer/config -u admin:admin --insecure | jq
{
  "performanceAnalyzerEnabled": true,
  "rcaEnabled": false,
  "loggingEnabled": false,
  "shardsPerCollection": 0,
  "batchMetricsEnabled": false,
  "batchMetricsRetentionPeriodMinutes": 7
}
```

verify that you get response of the selected metrics in the records / [Metrics reference](https://opendistro.github.io/for-elasticsearch-docs/docs/pa/reference/)

```bash
curl -XGET "http://localhost:9600/_opendistro/_performanceanalyzer/metrics?metrics=Latency,CPU_Utilization&agg=avg,max&nodes=all" | jq 
{                         
  "-_7gQpzIRGyezAn4YpARfQ": {
    "timestamp": 1610908315000,
    "data": {     
      "fields": [
        {                  
          "name": "Latency",  
          "type": "DOUBLE"
        },
        {
          "name": "CPU_Utilization",
          "type": "DOUBLE"
        }                                        
      ],                                                
      "records": [
        [
          190,
          0.007461569579288026
        ]
      ]
    }
  }
```

**PrefTop**

PrefTop officiel github repository [link](https://github.com/opendistro-for-elasticsearch/perftop)

the syntax is similar:

```bash
$ perf-top --dashboard <dashboard> --endpoint <endpoint>
$ perf-top --dashboard ClusterOverview  --endpoint http://localhost:9600 --logfile perftop.log
```


<p align="center"> <img  src="../images/preftop-dashboard-example.png" /> </p>

**Preset [Dashboards](https://github.com/opendistro-for-elasticsearch/perftop#preset-dashboards)** **:**

- ClusterOverview
- ClusterNetworkMemoryAnalysis
- ClusterThreadAnalysis
- NodeAnalysis

you can create your own dashboard [link](https://opendistro.github.io/for-elasticsearch-docs/docs/pa/dashboards/)



#### Security configuration [link](https://opendistro.github.io/for-elasticsearch-docs/docs/security/configuration/)

[Generate](https://opendistro.github.io/for-elasticsearch-docs/docs/security/configuration/generate-certificates/) node and client certificates

Run the toolbox container , mount a volume 'setup-ssl'  , [generate](https://aws.amazon.com/blogs/opensource/add-ssl-certificates-open-distro-for-elasticsearch/) the certificates in this volume, these certificates will be used in odfe docker-compose file

```bash
$ docker run -it -v ~/Documents/LeadWire/leadwire-deploy-k8s/toolbox-for-odfe/setup-ssl:/mnt ahmedaminesoltani/leadwire-tests:toolbox-odfe-v3 /bin/sh
$ pwd
/cert
$ cd /mnt
$ sh /cert/gen-cert.sh 
Generating RSA private key, 2048 bit long modulus (2 primes)
......................+++++
.......+++++
e is 65537 (0x010001)
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [AU]:
                                                         ...
                                                         ...
$ ls
admin-key.pem    admin.pem        node-key.pem     node.pem         root-ca-key.pem  root-ca.pem      root-ca.srl


```

