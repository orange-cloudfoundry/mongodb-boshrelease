<%

require "json"

def esc(x)
    case x
    when String
        x.to_json[1..-2]
    else
        x.to_json
    end
end

tcp_port = case p("node_role")
    when "rs"
        p("rs_port")
    when "sh"
        p("sh_port")
    when "cfg"
        p("cfg_port")
    when "mongos"
        p("mongos_port")
end
-%>
rs.initiate({
    _id : "<%= esc(p('replication.replica_set_name')) %>",
    members: [
        {
            _id: 0,
            host: "<%= esc(spec.ip) %>:<%= esc(tcp_port) %>"
        }
    ]
});