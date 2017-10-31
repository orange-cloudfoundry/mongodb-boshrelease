<%

require "json"

def esc(str)
    str.to_json[1..-2]
end

-%>
use admin;

if (db.system.users.find({ user: "<%= esc(p('admin_username')) %>" }).count() == 0) {
    db.createUser({
        user: "<%= esc(p('admin_username')) %>",
        pwd: "<%= esc(p('admin_password')) %>",
        roles: [
            { role: "userAdminAnyDatabase", db: "admin" }
        ]
    });
} else {
    db.changeUserPassword("<%= esc(p('admin_username')) %>", "<%= esc(p('admin_password')) %>");
}
if (db.system.users.find({ user: "<%= esc(p('root_username')) %>" }).count() == 0) {
    db.createUser({
        user: "<%= esc(p('root_username')) %>",
        pwd: "<%= esc(p('root_password')) %>",
        roles: [
            { role: "root", db: "admin" }
        ]
    });
} else {
    db.changeUserPassword("<%= esc(p('root_username')) %>", "<%= esc(p('root_password')) %>");
}