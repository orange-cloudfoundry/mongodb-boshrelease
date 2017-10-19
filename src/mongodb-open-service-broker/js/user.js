if (db.system.users.find({ user: "myUserAdmin" }).count() == 0) {
    db.createUser({
        user: "myUserAdmin",
        pwd: "abc123",
        roles: [
            {role: "userAdminAnyDatabase", db: "admin"}
        ]
    });
}