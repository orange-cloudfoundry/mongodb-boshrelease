use admin;

if (db.system.users.find({ user: "MongoAdmin" }).count() == 0) {
    db.createUser({
        user: "MongoAdmin",
        pwd: "Mongo'Admin\"Password",
        roles: [
            { role: "userAdminAnyDatabase", db: "admin" }
        ]
    });
} else {
    db.changeUserPassword("MongoAdmin", "Mongo'Admin\"Password");
}
if (db.system.users.find({ user: "MongoRoot" }).count() == 0) {
    db.createUser({
        user: "MongoRoot",
        pwd: "Mongo\"Root'Password",
        roles: [
            { role: "root", db: "admin" }
        ]
    });
} else {
    db.changeUserPassword("MongoRoot", "Mongo\"Root'Password");
}
