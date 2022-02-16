vault {
    address = "http://prometheus.pki.vagrant:8200"
}
auto_auth {
    method "approle" {
        config = {
            role_id_file_path = "/vagrant_data/tmp/role_id"
            secret_id_file_path = "/vagrant_data/tmp/secret_id"
            remove_secret_id_file_after_reading = false
        }
    }
}
syslog {
    enabled = true
    facility = "LOCAL5"
}
template {
    contents="{{ with secret \"pki_int/issue/pki-dot-vagrant\" \"ttl=3m\" \"common_name=node.pki.vagrant\" }}{{ .Data.certificate }}{{ end }}"
    destination="/etc/node_exporter/ssl/node.pki.vagrant.cert"
    command = "killall -HUP node_exporter"
}

template {
    contents="{{ with secret \"pki_int/issue/pki-dot-vagrant\" \"ttl=3m\" \"common_name=node.pki.vagrant\" }}{{ .Data.issuing_ca }}{{ end }}"
    destination="/etc/node_exporter/ssl/ca.cert"
    command = "killall -HUP node_exporter"
}

template {
    contents="{{ with secret \"pki_int/issue/pki-dot-vagrant\" \"ttl=3m\" \"common_name=node.pki.vagrant\" }}{{ .Data.private_key }}{{ end }}"
    destination="/etc/node_exporter/ssl/node.pki.vagrant.key"
    command = "killall -HUP node_exporter"
}