vault {
    address = "http://localhost:8200"
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
    contents="{{ with secret \"pki_int/issue/pki-dot-vagrant\" \"ttl=3m\" \"common_name=prometheus.pki.vagrant\" }}{{ .Data.certificate }}{{ end }}"
    destination="/etc/prometheus/ssl/node.pki.vagrant.cert"
    command = "killall -HUP prometheus"
}

template {
    contents="{{ with secret \"pki_int/issue/pki-dot-vagrant\" \"ttl=3m\" \"common_name=prometheus.pki.vagrant\" }}{{ .Data.issuing_ca }}{{ end }}"
    destination="/etc/prometheus/ssl/ca.cert"
    command = "killall -HUP prometheus"
}

template {
    contents="{{ with secret \"pki_int/issue/pki-dot-vagrant\" \"ttl=3m\" \"common_name=prometheus.pki.vagrant\" }}{{ .Data.private_key }}{{ end }}"
    destination="/etc/prometheus/ssl/node.pki.vagrant.key"
    command = "killall -HUP prometheus"
}
