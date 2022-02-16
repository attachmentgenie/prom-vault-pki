vault {
    address = "http://localhost:8200"
    token="s.i3RhQhzOKf7LlXme8xCulmZz"
    unwrap_token = false
    renew_token = false
}
syslog {
    enabled = true
    facility = "LOCAL5"
}
template {
    contents="{{ with secret \"pki_int/issue/pki-dot-vagrant\" \"common_name=node.pki.vagrant\" }}{{ .Data.certificate }}{{ end }}"
    destination="/etc/node_exporter/ssl/node.pki.vagrant.cert"
}

template {
    contents="{{ with secret \"pki_int/issue/pki-dot-vagrant\" \"common_name=node.pki.vagrant\" }}{{ .Data.private_key }}{{ end }}"
    destination="/etc/node_exporter/ssl/node.pki.vagrant.key"
}