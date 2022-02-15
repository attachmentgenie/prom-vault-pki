provider "vault" {}

resource "vault_mount" "pki" {
  path        = "pki"
  type        = "pki"
  description = "KV mount for pki"
}