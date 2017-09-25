# <p style="text-align:center">Mongodb Bosh Release</p>

> > ** THIS RELEASE IS STILL WIP AND SHOULD NOT BE USE IN PRODUCTION **

## Table of contents

* [Purpose](#L18)
* [Prerequisites](#L27)
* [Installation](#L148)
  * [Add needed blobs](#L150)
  * [Deployment Manifest](#L181)
* [Mongodb-server job variables]

## Purpose

This project is a [Mongodb](https://www.mongodb.com) [Bosh](http://bosh.io) release.
It's entirelly compiled from sources code, which allow to include some features like ssl authent and [Rocksdb](http://rocksdb.org/) engine.  
It also allow to use more recents libraries than the ones provided by bosh.io stemcells

Because of this choice it could be implemented on ubuntu or centos Stemcell.

## What should do the Release

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
go        | `1.8.3`  | need to compile go 1.4 as bootstrap
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
```sh
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
│   ├── golang
│   │   ├── packaging
│   │   └── spec
│   ├── golang14
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


## Installation

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
bosh -e [director name] cr
bosh -e [director name] ur
bosh -e [director name] -d [deployment name] -n deploy manifest.yml --vars-store=credentials.yml -v appli="mongodb"
```

> >
