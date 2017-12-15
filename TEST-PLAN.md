MongoDB release test plan
=========================

Unit tests
----------

### Templates to tests

Included:

- `mongod.conf`
- `mongod_bootstrap.conf`
- `pre-start`
- `create_admin_users.js`
- `initiate_rs.js`


Excluded:

- `mongoadmin.sh`


Rendering technologies:

1. Test templates rendering with `render.rb` (with `bosh-template` Gem v1.x).
2. Test templates with `bosh-template` 2.0.0 Gem


Run ShellCheck on Bash scripts.


### Configurations

1. Mandatory

    - replication or standalone
    - test various engines: wiredTiger, mmapv1.

2. Optional

    - test various engines: RocksDB
    - with SSL or not
    - config server
    - shard server


Acceptance tests
----------------

Write BOSH errand job.

### Common tests

These test will be run for both Stand Alone and Replica Set setups.

These tests use the `mongo` CLI.

1. Read/Write test

  - Before each:
    - connect as admin
    - create database
    - create user with admin role on the database

  - Test case:
    - connect as user
    - create collection
    - write some data in collection
    - read the data back
    - update the data
    - delete data
    - verify data is absent

  - After each:
    - drop database
    - drop user


2. Dump/Restore

  - Test case:
    - write some data
    - mongo dump
    - drop database
    - mongo restore
    - read the data back


3. Engine

    - Create stand alone node with specific engine
    - Verify the mongo server is using that specific engine


4. Replication modes

    - Verify `mongodb.replication.enable: true` provides a replica set
    - Verify that `mongodb.replication.enable: true` with only one instance keeps the ReplicaSet active
    - Verify `mongodb.replication.enable: false` and `role: sa` creates a standalone node
    - Verify that having both `mongodb.replication.enable: true` and `role: sa` raises an error when deploying


5. Replication

    - Insert some data on master node
    - Toggle slaves to `slaveOK`
    - verify data is present on slaves


6. Soft Failover

    - Build a 3-nodes Replica Set
    - Turn the BOSH resurrector off
    - Find the primary node (using `rs.status().isMaster()` on each node)
    - *Stop* the primary node *gracefully*
    - Verify another node takes the master role over


7. Cluster re-join after graceful stop

    - Same begining as above

    - Start the node back
    - verify it joins the cluster as secondary node
    - verify the data is here


8. Dirty Failover

    - Build a 3-nodes Replica Set
    - Turn the resurrector on
    - Find the primary node (using `rs.status().isMaster()` on each node)
    - *Kill* the primary node (access the IaaS API)
    - Verify another node takes the master role over


9. Cluster recovery

    - Same begining as above

    - Wait for the resurrector to recreate the killed node
    - verify


10. Scale-in (general case)

    - Build a 3-nodes Replica Set
    - Scale in to 1 node
    - Verify that deleted nodes have properly left the cluster


11. Scale-in (involing a master node)

    - Build a 3-nodes Replica Set
    - Have a non-bootstrap node take over the master role
    - Scale in to 1 node
    - Verify that the master role has been transfered to the node that is left
    - Verify that deleted nodes have properly left the cluster


12. Scale-out

    - Build a 1-node Replica Set
    - Scale out to 3 nodes
    - Verify that new nodes join the cluster properly


13. SSL

    - Verify SSL is properly implemented
