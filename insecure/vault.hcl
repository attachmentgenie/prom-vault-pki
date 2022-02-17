ui = true
disable_mlock = true
storage "file" {
  path = "/opt/vault/data"
}
listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = "true"
}
telemetry {
  prometheus_retention_time = "30s"
  disable_hostname = true
}
