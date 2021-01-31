### Node-to-node encryption 	

Encrypts traffic between nodes in the Elasticsearch cluster.

Run the toolbox container , mount a volume 'setup-ssl'  , [generate](https://aws.amazon.com/blogs/opensource/add-ssl-certificates-open-distro-for-elasticsearch/) the certificates in this volume , these certificates will be used in odfe docker-compose file

```bash
$ docker run -it -v ~/Documents/LeadWire/leadwire-deploy-k8s/toolbox-for-odfe/setup-ssl:/mnt ahmedaminesoltani/leadwire-tests:toolbox-odfe-v3 /bin/sh
$ pwd
/cert
$ cd /mnt
$ sh /cert/gen-cert.sh 
Generating RSA private key, 2048 bit long modulus (2 primes)
...............+++++
.....+++++
e is 65537 (0x010001)
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [AU]:TN
State or Province Name (full name) [Some-State]:
Locality Name (eg, city) []:Tunisia
Organization Name (eg, company) [Internet Widgits Pty Ltd]:Example Leadwire
Organizational Unit Name (eg, section) []:
Common Name (e.g. server FQDN or YOUR name) []:Example Leadwire CA Root
Email Address []:
Generating RSA private key, 2048 bit long modulus (2 primes)
................+++++
...........................+++++
e is 65537 (0x010001)
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [AU]:TN
State or Province Name (full name) [Some-State]:
Locality Name (eg, city) []:Tunisia
Organization Name (eg, company) [Internet Widgits Pty Ltd]:Example Leadwire 
Organizational Unit Name (eg, section) []:
Common Name (e.g. server FQDN or YOUR name) []:Example Leadwire CA Admin
Email Address []:

Please enter the following 'extra' attributes
to be sent with your certificate request
A challenge password []:
An optional company name []:
Signature ok
subject=C = TN, ST = Some-State, L = Tunisia, O = Example Leadwire, CN = Example Leadwire CA Admin
Getting CA Private Key
Generating RSA private key, 2048 bit long modulus (2 primes)
.........................................................................................................................................................................+++++
...............+++++
e is 65537 (0x010001)
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [AU]:TN
State or Province Name (full name) [Some-State]:
Locality Name (eg, city) []:Tunisia
Organization Name (eg, company) [Internet Widgits Pty Ltd]:Example Leadwire
Organizational Unit Name (eg, section) []:
Common Name (e.g. server FQDN or YOUR name) []:odfe-node.example.com
Email Address []:

Please enter the following 'extra' attributes
to be sent with your certificate request
A challenge password []:
An optional company name []:
Signature ok
subject=C = TN, ST = Some-State, L = Tunisia, O = Example Leadwire, CN = odfe-node.example.com
Getting CA Private Key

$ ls
admin-key.pem    admin.pem        node-key.pem     node.pem         root-ca-key.pem  root-ca.pem      root-ca.srl
```

Edit elasticsearch.yml to Add Your Certificates , This will enable Open Distro for Elasticsearch’s security plugin to  accept SSL requests, as well as enable node-to-node SSL communication.  Create a copy of `elasticsearch.yml` in your `setup-ssl` directory. 

```bash
# Start a cluster
$ docker-compose up -d
# Create a copy of `elasticsearch.yml` in your `setup-ssl` directory
$ docker exec -it odfe-node1 cat /usr/share/elasticsearch/config/elasticsearch.yml > setup-ssl/custom-elasticsearch.yml
$ cat setup-ssl/custom-elasticsearch.yml
cluster.name: "docker-cluster"
network.host: 0.0.0.0

# # minimum_master_nodes need to be explicitly set when bound on a public IP
                                                                 ...
                                                                 ...

```



For container deployments, override the files in the container with the your local files by modifying docker-compose.yml , 

Additionally you can set the Docker environment variable `DISABLE_INSTALL_DEMO_CONFIG` to `true`. This change completely disables the demo installer.

Add `network.host=0.0.0.0` , required if not using the demo security configuration

**docker-compose.yml** :

```dockerfile
															...
  															...
  odfe-node1:
    image: amazon/opendistro-for-elasticsearch:1.12.0
    container_name: odfe-node1
    environment:
      - cluster.name=odfe-cluster
      - node.name=odfe-node1
      - discovery.seed_hosts=odfe-node1,odfe-node2
      - cluster.initial_master_nodes=odfe-node1,odfe-node2
      - bootstrap.memory_lock=true # along with the memlock settings below, disables swapping
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m" # minimum and maximum Java heap size, recommend setting both to 50% of system RAM
      - "DISABLE_INSTALL_DEMO_CONFIG=true"
      - network.host=0.0.0.0 # required if not using the demo security configuration
    ulimits:
      memlock:
        soft: -1
        hard: -1
      nofile:
        soft: 65536 # maximum number of open files for the Elasticsearch user, set to at least 65536 on modern systems
        hard: 65536
    volumes:
      - odfe-data1:/usr/share/elasticsearch/data
      - ./setup-ssl/root-ca.pem:/usr/share/elasticsearch/config/root-ca.pem
      - ./custom-elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml
      - ./setup-ssl/node.pem:/usr/share/elasticsearch/config/node.pem
      - ./setup-ssl/node-key.pem:/usr/share/elasticsearch/config/node-key.pem
      - ./setup-ssl/admin.pem:/usr/share/elasticsearch/config/admin.pem
      - ./setup-ssl/admin-key.pem:/usr/share/elasticsearch/config/admin-key.pem
    ports:
      - 9200:9200
      - 9600:9600 # required for Performance Analyzer
    networks:
      - odfe-net
  odfe-node2:
    image: amazon/opendistro-for-elasticsearch:1.12.0
    container_name: odfe-node2
    environment:
      - cluster.name=odfe-cluster
      - node.name=odfe-node2
      - discovery.seed_hosts=odfe-node1,odfe-node2
      - cluster.initial_master_nodes=odfe-node1,odfe-node2
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
      - network.host=0.0.0.0 # required if not using the demo security configuration
    ulimits:
      memlock:
        soft: -1
        hard: -1
      nofile:
        soft: 65536
        hard: 65536
    volumes:
      - odfe-data1:/usr/share/elasticsearch/data
      - ./setup-ssl/root-ca.pem:/usr/share/elasticsearch/config/root-ca.pem
      - ./setup-ssl/custom-elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml
      - ./setup-ssl/node.pem:/usr/share/elasticsearch/config/node.pem
      - ./setup-ssl/node-key.pem:/usr/share/elasticsearch/config/node-key.pem
      - ./setup-ssl/admin.pem:/usr/share/elasticsearch/config/admin.pem
      - ./setup-ssl/admin-key.pem:/usr/share/elasticsearch/config/admin-key.pem
    networks:
      - odfe-net
      														...
      														...
```

```
./securityadmin.sh -cd ../securityconfig/ -icl -nhnv -cacert ../../../config/root-ca.pem -cert ../../../config/admin.pem -key ../../../config/admin-key.pem
```

Open your local copy of `elasticsearch.yml` ( setup-ssl/custom-elasticsearch.yml )

Make sure to remove the entry  `opendistro_security.allow_unsafe_democertificates: true`   to use your certificates instead of the demo certificates.    

to get [distinguished](https://opendistro.github.io/for-elasticsearch-docs/docs/security/configuration/generate-certificates/#get-distinguished-names) names for `opendistro_security.authcz.admin_dn` and `opendistro_security.nodes_dn`

```bash
$ openssl x509 -subject -nameopt RFC2253 -noout -in admin.pem
subject=CN=Example Leadwire CA Admin,O=Example Leadwire,L=Tunisia,ST=Some-State,C=TN
$ openssl x509 -subject -nameopt RFC2253 -noout -in node.pem
subject=CN=odfe-node.example.com,O=Example Leadwire,L=Tunisia,ST=Some-State,C=TN
```

**custom-elasticsearch.yml** :

```yaml
cluster.name: "docker-cluster"
network.host: 0.0.0.0

# # minimum_master_nodes need to be explicitly set when bound on a public IP
# # set to 1 to allow single node clusters
# # Details: https://github.com/elastic/elasticsearch/pull/17288
# discovery.zen.minimum_master_nodes: 1

# # Breaking change in 7.0
# # https://www.elastic.co/guide/en/elasticsearch/reference/7.0/breaking-changes-7.0.html#breaking_70_discovery_changes
# cluster.initial_master_nodes: 
#    - elasticsearch1
#    - docker-test-node-1 
######## Start OpenDistro for Elasticsearch Security Demo Configuration ########
# WARNING: revise all the lines below before you go into production
opendistro_security.ssl.transport.pemcert_filepath: node.pem
opendistro_security.ssl.transport.pemkey_filepath: node-key.pem
opendistro_security.ssl.transport.pemtrustedcas_filepath: root-ca.pem
opendistro_security.ssl.transport.enforce_hostname_verification: false
opendistro_security.ssl.http.enabled: true
opendistro_security.ssl.http.pemcert_filepath: node.pem
opendistro_security.ssl.http.pemkey_filepath: node-key.pem
opendistro_security.ssl.http.pemtrustedcas_filepath: root-ca.pem
#opendistro_security.allow_unsafe_democertificates: true
opendistro_security.allow_default_init_securityindex: true
opendistro_security.authcz.admin_dn:
  - CN=Example Leadwire CA Admin,O=Example Leadwire,L=Tunisia,ST=Some-State,C=TN
opendistro_security.nodes_dn:
  - 'CN=odfe-node.example.com,O=Example Leadwire,L=Tunisia,ST=Some-State,C=TN'
opendistro_security.audit.type: internal_elasticsearch
opendistro_security.enable_snapshot_restore_privilege: true
opendistro_security.check_snapshot_restore_write_privileges: true
opendistro_security.restapi.roles_enabled: ["all_access", "security_rest_api_access"]
opendistro_security.system_indices.enabled: true
opendistro_security.system_indices.indices: [".opendistro-alerting-config", ".opendistro-alerting-alert*", ".opendistro-anomaly-results*", ".opendistro-anomaly-detector*", ".opendistro-anomaly-checkpoints", ".opendistro-anomaly-detection-state", ".opendistro-reports-*", ".opendistro-notifications-*"]
cluster.routing.allocation.disk.threshold_enabled: false
node.max_local_storage_nodes: 3
######## End OpenDistro for Elasticsearch Security Demo Configuration test ########
```

use `chmod` to set file permissions before running `docker-compose up`

```bash
$ cd setup-ssh
$ chmod 600 -R ./*
```

Run securityadmin.sh , after configuring your certificates and starting Elasticsearch, run securityadmin.sh to initialize the security plugin:

```bash
$ docker exec -it odfe-node1 /bin/sh
$ cd /usr/share/elasticsearch/plugins/opendistro_security/tools/
$ chmod +x securityadmin.sh
$ ./securityadmin.sh -cd ../securityconfig/ -icl -nhnv -cacert ../../../config/root-ca.pem -cert ../../../config/admin.pem -key ../../../config/admin-key.pem

Open Distro Security Admin v7
Will connect to localhost:9300 ... done
Connected as CN=Example Leadwire CA Admin,O=Example Leadwire,L=Tunisia,ST=Some-State,C=TN
Elasticsearch Version: 7.10.0
Open Distro Security Version: 1.12.0.0
Contacting elasticsearch cluster 'elasticsearch' and wait for YELLOW clusterstate ...
Clustername: odfe-cluster
Clusterstate: GREEN
Number of nodes: 2
Number of data nodes: 2
.opendistro_security index already exists, so we do not need to create one.
Populate config from /usr/share/elasticsearch/plugins/opendistro_security/securityconfig
Will update '_doc/config' with ../securityconfig/config.yml 
   SUCC: Configuration for 'config' created or updated
Will update '_doc/roles' with ../securityconfig/roles.yml 
   SUCC: Configuration for 'roles' created or updated
Will update '_doc/rolesmapping' with ../securityconfig/roles_mapping.yml 
   SUCC: Configuration for 'rolesmapping' created or updated
Will update '_doc/internalusers' with ../securityconfig/internal_users.yml 
   SUCC: Configuration for 'internalusers' created or updated
Will update '_doc/actiongroups' with ../securityconfig/action_groups.yml 
   SUCC: Configuration for 'actiongroups' created or updated
Will update '_doc/tenants' with ../securityconfig/tenants.yml 
   SUCC: Configuration for 'tenants' created or updated
Will update '_doc/nodesdn' with ../securityconfig/nodes_dn.yml 
   SUCC: Configuration for 'nodesdn' created or updated
Will update '_doc/whitelist' with ../securityconfig/whitelist.yml 
   SUCC: Configuration for 'whitelist' created or updated
Will update '_doc/audit' with ../securityconfig/audit.yml 
   SUCC: Configuration for 'audit' created or updated
Done with success

```

