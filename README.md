# <p style="text-align:center">Mongodb Bosh Release</p>

## Contents

  * [Purpose](#purpose)
  * [What should the Release do](#what-should-the-release-do)
  * [Packages versions summary](#packages-versions-summary)
  * [Installation](#installation)
    + [Clone the repository](#clone-the-repository)
    + [Deployment manifests](#deployment-manifests)
      - [Variables](#variables)
    + [Operation files](#operation-files)
    + [Deployment](#deployment)
  * [Broker](#broker)
    + [Mongodb Broker](#mongodb-broker-(broker-job))
    + [Mongodb Broker Smoke Tests](#mongodb-broker-smoke-tests-(broker-smoke-tests-job))
  * [Configuring CF to use Mongodb service](#configuring-cf-to-use-mongodb-service)
    + [Available Plans](#available-plans)
    + [Broker registration](#broker-registration)
    + [Service provisioning](#service-provisioning)
    + [Service binding](#service-binding)
    + [Service unbinding](#service-unbinding)
    + [Service deprovisioning](#service-deprovisioning)
  * [Contributing](#contributing)
    + [Ruby Env Setup](#ruby-env-setup)

## Purpose

This project is a [Mongodb](https://www.mongodb.com) [Bosh](http://bosh.io) release.
The blobs are the provided ones from the mongodb community and are not compiled anymore. So the release can now only be deployed on an ubuntu stemcell.

This version exclude the rocksdb engine, which is not supported anymore. 

## What should the Release do

> 
* Configure a standalone or a set of standalone servers
* Configure a replica set 
* Configure a sharded cluster including config server and mongos
* Complete requirements for mongodb servers ([production notes](https://docs.mongodb.org/manual/administration/production-notes/))
* Install mongodb component (shell / tools / mongod)
* Authentification using bosh/credhub generated passwords (could be disable)

## Packages versions summary

* Mongodb database and modules version

| Package         | Version     | Note                  |
| --------------- | ----------- | --------------------- |
| mongodb         | `3.6.12`    |                       |
| ~~mongo-rocks~~ | ~~`3.4.7`~~ | Not supported anymore |
| mongo-tools     | `3.6.12`    |                       |
| ~~rocksdb~~     | ~~`3.4.7`~~ | Not supported anymore |


## Installation

### Clone the repository

```sh
git clone --recursive https://github.com/orange-cloudfoundry/mongodb-boshrelease.git
```

### Deployment manifests

Two different base manifests are provided for single replicaset or sharded deployment and can be found in the `manifests` directory

#### Variables

Release include a `deployment-vars-template.yml` file, which includes all the needed variables for  the deployment. Just copy and fill the variables for your needs.



### Operation files

The release provides a set of operation files to enable or disable features. Operation files are located in the `operations`directory. This folder contains commons opsfiles and two subdirectories for sharding and replicaset  

| Ops file                                      | feature                                                      | needed variable                                              | dependecies                                                  |
| --------------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| **rename-azs.yml**                            | *use specific azs*                                           | azs-list                                                     |                                                              |
| **use-specific-mongodb-release.yml**          | *use a named uploaded mongodb release version instead of the latest one* | mongodb-release-version                                      |                                                              |
| **use_mmapv1.yml**                            | *use mmapv1 engine instead of wiredtiger default*            |                                                              |                                                              |
| **use-trusty.yml**                            | *use an ubuntu trusty stemcell instead of the xenial default* |                                                              |                                                              |
| **use-specific-stemcell.yml**                 | *Use a specifically named stemcell version instead of the latest one* | stemcell-version                                             |                                                              |
| **enable-mongodb-acceptance-test.yml**        | *Deploy the acceptance tests errand*                         | accept_vm_type                                               |                                                              |
| **enable-mongodb-broker.yml**                 |                                                              | broker_vm_type<br />broker_persistent_disk_type<br />broker_catalog_yml |                                                              |
| **enable-mongodb-broker-route-registrar.yml** |                                                              | cf.nats_host<br />cf.nats_password<br />cf.system_domain     | enable-mongodb-broker.yml                                    |
| **enable-mongodb-broker-smoke-tests.yml**     |                                                              |                                                              | enable-mongodb-broker.yml<br />enable-mongodb-broker-route-registrar.yml |
| **rename-broker-network.yml**                 | *use a specific network for the broker instead of the default one* |                                                              | enable-mongodb-broker.yml                                    |
| **enable-prometheus-exporter.yml**            | *deploy the prometheus mongodb exporter from prometheus-addons bosh release* | clustermonitor_username                                      |                                                              |
|                                               |                                                              |                                                              |                                                              |

**Note that operations directory include some others opsfiles like ssl ones that are not fully tested yet and should not be use**

### Deployment

```sh
bosh create-release
bosh upload-release
bosh -d [deployment name] -n deploy manifests/manifest[rs|shard].yml <-o operations/[operation file name] -o ...> -l <deployment-vars-file> <--vars-store=credentials.yml >
```
*--vars-store=credentials.yml is uneeded if you are using credhub*

## Broker

### Mongodb Broker (broker job)

The mongodb broker implements the 5 REST endpoints required by Cloud Foundry to write V2 services : 
* Catalog management in order to register the broker to the platform
* Provisioning in order to create resource in the mongodb server
* Deprovisioning in order to release resource previously allocated
* Binding (credentials type) in order to provide application with a set of information required to use the allocated service
* Unbinding in order to delete credentials resources previously allocated

### Mongodb Broker Smoke Tests (broker-smoke-tests job)

The mongodb broker smoke test acts as an end user developper who wants to host its application in a cloud foundry.

For that, it relies on a sample mongodb application : https://github.com/JCL38-ORANGE/cf-mongodb-example-app

The following steps are performed by the smoke tests job : 
* Authentication on Cloud Foundry by targeting org and space (cf auth and cf target)
* Deployment of the sample mongodb application (cf push)
* Provisioning of the service (cf create-service)
* Binding of the service (cf bind-service)
* Restaging of the sample mongodb application (cf restage)
* Table creation in the mongodb cluster (HTTP POST command to the sample mongodb application)
* Table deletion in the mongodb cluster (HTTP DELETE command to the sample mongodb application)

## Configuring CF to use Mongodb service

### Available Plans

For the moment, only 1 default plan available for shared Mongodb.

### Broker registration

The broker uses HTTP basic authentication to authenticate clients. The `cf create-service-broker` command expects the credentials for the cloud
controller to authenticate itself to the broker. 

```bash
cf create-service-broker p-mongodb-broker <user> <password> <url> 
cf enable-service-access mongodb
```

### Service provisioning

```bash
cf create-service mongodb default mongodb-instance
```

### Service binding

```bash
cf bind-service mongodb-example-app mongodb-instance
```
### Service unbinding

```bash
cf unbind-service mongodb-example-app mongodb-instance
```
### Service deprovisioning

```bash
cf delete-service mongodb-instance
```

## Contributing

### Ruby Env Setup

This my setup:

    brew install ruby-build chruby
    ruby-build 2.4.2 --install-dir ~/.rubies/ruby-2.4.2
    gem update --system
    gem install bundler
    bundle install

