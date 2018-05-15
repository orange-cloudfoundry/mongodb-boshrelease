use admin;

// retrieve variables from conf file
// job_dir must be passed when calling mongo shell using the --eval and --shell option

db.system.js.save({_id: "getDeploymentVar",
                   value : function(key)
                   {
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
});

db.loadServerScripts("getDeploymentVar");

if (db.system.users.find({ user: getDeploymentVar("property_admin_username") }).count() == 0) {
    db.createUser({
        user: getDeploymentVar("property_admin_username"),
        pwd: getDeploymentVar("property_admin_password"),
        roles: [
            { role: "userAdminAnyDatabase", db: "admin" }
        ]
    });
} else {
    db.changeUserPassword(getDeploymentVar("property_admin_username"), getDeploymentVar("property_admin_password"));
}
if (db.system.users.find({ user: getDeploymentVar("property_root_username") }).count() == 0) {
    db.createUser({
        user: getDeploymentVar("property_root_username"),
        pwd: getDeploymentVar("property_root_password"),
        roles: [
            { role: "root", db: "admin" }
        ]
    });
} else {
    db.changeUserPassword(getDeploymentVar("property_root_username"), getDeploymentVar("property_root_password"));
}
