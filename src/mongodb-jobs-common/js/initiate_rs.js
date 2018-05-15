use admin;

// retrieve variables from conf file
// job_dir must be passed when calling mongo shell using the --eval and --shell option

function getDeploymentVar(key){
  var file=cat(job_dir+"/bin/mdb-variables.sh");
  var objectId = file.split('\n');
  value=null;
  for (var i =0; i<objectId.length-1; i++){
    var keyval = objectId[i].split("=");
    if (keyval[0] == key)
    {
    value=keyval[1];
    }
  }
  return value;
}

rs.initiate({
    _id : getDeploymentVar("property_replica_set_name"),
    members: [
        {
            _id: 0,
            host: getDeploymentVar("deployment_current_ip")+":"+getDeploymentVar("property_mongod_listen_port")
        }
    ]
});