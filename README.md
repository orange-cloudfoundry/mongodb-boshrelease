# <p style="text-align:center">Mongodb Bosh Release</p>

> > ** THIS RELEASE IS STILL WIP AND SHOULD NOT BE USE IN PRODUCTION **

## Table of contents

* [Purpose](#purpose)
* [What should the Release do](#what-should-the-release-do)
* [Prerequisites](#prerequisites)
* [Packages versions summary](#packages-versions-summary)
* [Release tree](#release-tree)
* [Broker](#broker)
* [Configuring CF to use Mongodb service](#configuring)
* [Installation](#installation)
  - [Get vendor package](#get-vendor-package)
  * [Add needed blobs](#add-needed-blobs)
  * [Deployment Manifest](#create-the-deployment-manifest)
* [Mongodb-server job variables]()

## Purpose

This project is a [Mongodb](https://www.mongodb.com) [Bosh](http://bosh.io) release.
It's entirelly compiled from sources code, which allow to include some features like ssl authent and [Rocksdb](http://rocksdb.org/) engine.  
It also allow to use more recents libraries than the ones provided by bosh.io stemcells

Because of this choice it could be implemented on ubuntu or centos Stemcell.

## What should the Release do

>* Configure a replica set (Shard and config server are not implemented yet)
* Complete requirements for mongodb servers ([production notes](https://docs.mongodb.org/manual/administration/production-notes/))
* Install mongodb component (shell / tools / mongod)
* Authentification using bosh generated passwords (could be disable)
* Secured inter-node and client/server commnication using TLS/SSL (could be disable)

## Prerequisites

>* 

## Packages versions summary

* Mongodb database and modules version

Package     | Version  |  Note
------------|----------|-------
mongodb     | `3.4.6`  |
mongo-rocks | `3.4.6`  |
mongo-tools | `3.4.6`  |
rocksdb     | `5.5.5`  |

* dependencies

Package   | Version  |  Note
----------|----------|-------
cmake     | `3.8.2`  |
bzip2     | `1.0.6`  |
lz4       | `1.7.5`  |
snappy    | `1.1.4`  |
zlib      | `1.2.11` |
zstd      | `1.3.0`  |
gcc       | `5.4.0`  |
gmp       | `6.1.2`  |
libpcap   | `1.8.1`  |
m4        | `1.4.18` |
mpc       | `1.0.3`  |
mpfr      | `3.1.5`  |
isl       | `0.18`   |
go       | `1.8.3`  | ~~need to compile go 1.4 as bootstrap~~ replaced by vendor package release
Python    | `2.7.13` |
scons     | `2.5.1`  |
openssl   | `1.0.2l` |
lzip      | `1.19`   |
ed        | `1.14.2` |
texinfo   | `6.4`    |
bc        | `1.07.1` |
binutils  | `2.28`   |
coreutils | `8.27`   |


## Release tree
> 
```tree
├── config
│   ├── blobs.yml
│   ├── final.yml
│   └── settings.yml
├── jobs
│   └── mongodb-server
│       ├── monit
│       ├── spec
│       └── templates
│           ├── bin
│           │   ├── generate_ssl_cert.sh.erb
│           │   ├── mongodb-server_ctl
│           │   ├── mongo.sh
│           │   ├── mongo-ssl.sh
│           │   ├── monit_debugger
│           │   ├── pre-start.erb
│           │   └── setenv.erb
│           ├── config
│           │   ├── mongod_bootstrap.conf.erb
│           │   ├── mongod.conf.erb
│           │   └── vcap_limits.conf.erb
│           ├── data
│           │   └── properties.sh.erb
│           ├── helpers
│           │   ├── ctl_setup.sh
│           │   └── ctl_utils.sh
│           ├── js
│           │   ├── create_admin_user.js.erb
│           │   └── initiate_rs.js.erb
│           └── ssl
│               ├── mongodb.ca.erb
│               └── mongodb.pem.erb
├── LICENSE
├── manifest.yml
├── packages
│   ├── binutils
│   │   ├── packaging
│   │   └── spec
│   ├── cmake
│   │   ├── packaging
│   │   └── spec
│   ├── compressors
│   │   ├── packaging
│   │   └── spec
│   ├── coreutils
│   │   ├── packaging
│   │   └── spec
│   ├── gcc
│   │   ├── packaging
│   │   └── spec
│   ├── mongodb
│   │   ├── packaging
│   │   └── spec
│   ├── openssl
│   │   ├── packaging
│   │   └── spec
│   ├── python
│   │   ├── packaging
│   │   └── spec
│   └── scons
│       ├── packaging
│       └── spec
├── README.md
└── src
    └── downloadblob.sh
```

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

## Installation

> 
### Get vendor package
As go is a prerequisite to mongo-tools compilation, you have to get the golang-1.8 vendor package and link it with the release

```sh
cd [work-dir]
git clone https://github.com/bosh-packages/golang-release
cd [mongodb-boshrelease-dir]
bosh vendor-package golang-1.8-linux [work-dir]/golang-release
```

> 
### Add needed blobs

* fill the **config/final.yml** with your appropriate blobstore
here is an example for a local store

> 
```yml
---
final_name: mongodb-service
blobstore:
  provider: local
  options:
    blobstore_path: /blobstore/
```

> > _the directory /blobstore must exists_

* Download blobs

the file **src/downloadblob.sh** perform a curl request to each needed blob

* Add the blob to director

for each downloaded blob perform an add-blob to the director to reference it

> 
```sh
bosh -e [director name] add-blob [archive] [blob_path]/[archive]
```


### Create the deployment manifest

An example is provided, update and complete it with your own configuration


### Deploy

>  
```sh
bosh -d [deployment name] cr
bosh -d [deployment name] ur
bosh -d [deployment name] -n deploy manifest.yml --vars-store=credentials.yml -v appli="mongodb"
```

> >


## Contributing

### Ruby Env Setup

This my setup:

    brew install ruby-build chruby
    ruby-build 2.4.2 --install-dir ~/.rubies/ruby-2.4.2
    gem update --system
    gem install bundler
    bundle install

