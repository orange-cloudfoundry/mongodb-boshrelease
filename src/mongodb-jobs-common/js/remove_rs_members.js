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

cfg = rs.conf();

id=cfg.members.forEach( function(_rs) { if (_rs.host=="10.244.0.147"+":"+getDeploymentVar("property_mongod_listen_port")) { print(_rs._id);} }).t
printjson(id);
//rs.conf().members.forEach( function(_rs) { if (_rs.host==getDeploymentVar("deployment_current_ip")+":"+getDeploymentVar("property_mongod_listen_port")) { print(_rs._id);} });
//cfg.members = cfg.members[rs.conf().members.forEach( function(_rs) { if (_rs.host==getDeploymentVar("deployment_current_ip")+":"+getDeploymentVar("property_mongod_listen_port")) { print(_rs._id);} })];
//cfg.members=[];
//printjson(cfg);
//rs.reconfig(cfg, {force : true});
