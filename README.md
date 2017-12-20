# <p style="text-align:center">Mongodb Bosh Release</p>

## Contents

* [What's new](#what's-new)
* [Purpose](#purpose)
* [What should the Release do](#what-should-the-release-do)
* [Prerequisites](#prerequisites)
* [Packages versions summary](#packages-versions-summary)
* [Installation](#installation)
	* [Clone the repository](#clone-the-repository)
	* [Deployment Manifest](#create-the-deployment-manifest)
	* [Deployment](#deployment)
* [Broker](#broker)
* [Configuring CF to use Mongodb service](#configuring)
* [Mongodb-server job variables]()

## What's new
* 2017-12-20:
> 
mongodb compilation has been delayed to it's own [bosh release](https://github.com/orange-cloudfoundry/mongodb-compilation-boshrelease). Now only the compiled blob is provided, which allow to considerably reducing compilation times


## Purpose

This project is a [Mongodb](https://www.mongodb.com) [Bosh](http://bosh.io) release.
It's entirelly compiled from sources code, which allow to include some features like [Rocksdb](http://rocksdb.org/) engine. 

As it is compiled with statics libraries, the release could be implemented on ubuntu or centos Stemcell.

## What should the Release do

> 
* Configure a standalone or a set of standalone servers
* Configure a replica set (Shard and config server are not implemented yet)
* Complete requirements for mongodb servers ([production notes](https://docs.mongodb.org/manual/administration/production-notes/))
* Install mongodb component (shell / tools / mongod)
* Authentification using bosh/credhub generated passwords (could be disable)

## Packages versions summary

* Mongodb database and modules version

Package     | Version  |  Note
------------|----------|-------
mongodb     | `3.4.6`  |
mongo-rocks | `3.4.6`  |
mongo-tools | `3.4.6`  |
rocksdb     | `5.5.5`  |


## Installation

### Clone the repository

```sh
git clone --recursive https://github.com/orange-cloudfoundry/mongodb-compilation-boshrelease.git
```

### Create the deployment manifest

An example is provided, update and complete it with your own configuration

### Deployment

```sh
bosh -d [deployment name] create-release
bosh -d [deployment name] upload-release
bosh -d [deployment name] -n deploy manifest.yml --vars-store=credentials.yml -v appli="mongodb"
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

