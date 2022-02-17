# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "bento/centos-7.9"
  config.vm.synced_folder ".", "/vagrant_data"
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"
  end

  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true
  config.hostmanager.manage_guest = true
  config.hostmanager.ignore_private_ip = false
  config.hostmanager.include_offline = true

  config.vm.define :prometheus do |node|
    node.vm.hostname = "prometheus.pki.vagrant"
    node.vm.network "private_network", ip: "192.168.56.10"
    node.vm.provision :shell, inline: <<-SHELL
    sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
    sudo yum install -y epel-release yum-utils wget
    if [ ! $(systemctl is-active vault) = "active" ]; then
      sudo yum -y install jq vault
      sudo cp /vagrant_data/insecure/vault.hcl /etc/vault.d/vault.hcl
      sudo systemctl enable vault
      sudo systemctl restart vault
      export VAULT_ADDR=http://localhost:8200
      /usr/bin/vault operator init -key-shares=1 -key-threshold=1 | tee vault.keys
      VAULT_TOKEN=$(grep '^Initial' vault.keys | awk '{print $4}')
      VAULT_KEY=$(grep '^Unseal Key 1:' vault.keys | awk '{print $4}')
      export VAULT_TOKEN
      /usr/bin/vault operator unseal "$VAULT_KEY"
      echo $VAULT_TOKEN > /etc/vault_token.txt
      echo $VAULT_KEY > /etc/vault_key.txt
      vault secrets enable pki
      vault secrets tune -max-lease-ttl=87600h pki
      vault write -field=certificate pki/root/generate/internal \
        common_name="pki.vagrant" \
        ttl=87600h > CA_cert.crt
      vault write pki/config/urls \
        issuing_certificates="$VAULT_ADDR/v1/pki/ca" \
        crl_distribution_points="$VAULT_ADDR/v1/pki/crl"
      vault secrets enable -path=pki_int pki
      vault secrets tune -max-lease-ttl=43800h pki_int
      vault write -format=json pki_int/intermediate/generate/internal \
        common_name="pki.vagrant Intermediate Authority" \
        | jq -r '.data.csr' > pki_intermediate.csr
      vault write -format=json pki/root/sign-intermediate csr=@pki_intermediate.csr \
        format=pem_bundle ttl="43800h" \
        | jq -r '.data.certificate' > intermediate.cert.pem
      vault write pki_int/intermediate/set-signed certificate=@intermediate.cert.pem
      vault write pki_int/roles/pki-dot-vagrant \
        allowed_domains="pki.vagrant" \
        allow_subdomains=true \
        max_ttl="720h"
      vault auth enable approle
      vault policy write pki_policy /vagrant_data/tls/pki_policy.hcl
      vault write auth/approle/role/pki-role secret_id_ttl=8760h token_num_uses=0 token_ttl=20m token_max_ttl=30m secret_id_num_uses=0 policies=pki_policy
      vault read -format=json auth/approle/role/pki-role/role-id | jq -r '.data.role_id' > /vagrant_data/tmp/role_id
      vault write -f -format=json auth/approle/role/pki-role/secret-id | jq -r '.data.secret_id' > /vagrant_data/tmp/secret_id
    fi
    if [ ! $(systemctl is-active vault-agent) = "active" ]; then
      sudo cp /vagrant_data/common/vault-agent.service /etc/systemd/system
      sudo cp /vagrant_data/tls/prometheus.hcl /etc/vault.d/certs.hcl
      sudo systemctl enable vault-agent
      sudo systemctl restart vault-agent
    fi
    if [ ! $(systemctl is-active prometheus) = "active" ]; then
      wget https://github.com/prometheus/prometheus/releases/download/v2.33.3/prometheus-2.33.3.linux-amd64.tar.gz
      tar xvf prometheus-2.33.3.linux-amd64.tar.gz
      sudo cp prometheus-2.33.3.linux-amd64/prometheus /usr/local/bin/prometheus
      sudo cp /vagrant_data/common/prometheus.service /etc/systemd/system
      sudo mkdir -p /etc/prometheus/
      sudo cp /vagrant_data/common/prometheus.yml /etc/prometheus/prometheus.yml
      sudo mkdir -p /etc/prometheus/ssl
      sudo systemctl enable prometheus
      sudo systemctl restart prometheus
    fi
  SHELL
  end

  config.vm.define :insecure do |node|
    node.vm.hostname = "insecure.pki.vagrant"
    node.vm.network "private_network", ip: "192.168.56.11"
    node.vm.provision :shell, inline: <<-SHELL
    sudo yum install -y epel-release yum-utils wget
    if [ ! $(systemctl is-active node_exporter) = "active" ]; then
      wget https://github.com/prometheus/node_exporter/releases/download/v1.3.1/node_exporter-1.3.1.linux-amd64.tar.gz
      tar xvf node_exporter-1.3.1.linux-amd64.tar.gz
      sudo cp node_exporter-1.3.1.linux-amd64/node_exporter /usr/local/bin/node_exporter
      sudo cp /vagrant_data/common/node_exporter.service /etc/systemd/system
      sudo mkdir -p /etc/node_exporter/
      sudo mkdir -p /etc/node_exporter/ssl
      sudo cp /vagrant_data/insecure/node_exporter.yml /etc/node_exporter/node_exporter.yml
      sudo systemctl enable node_exporter
      sudo systemctl restart node_exporter
    fi
  SHELL
  end

  config.vm.define :tls do |node|
    node.vm.hostname = "tls.pki.vagrant"
    node.vm.network "private_network", ip: "192.168.56.12"
    node.vm.provision :shell, inline: <<-SHELL
    sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
    sudo yum install -y epel-release yum-utils wget
    if [ ! $(systemctl is-active vault-agent) = "active" ]; then
      sudo yum -y install vault
      sudo systemctl disable vault
      sudo cp /vagrant_data/common/vault-agent.service /etc/systemd/system
      sudo cp /vagrant_data/tls/node-exporter.hcl /etc/vault.d/certs.hcl
      sudo systemctl enable vault-agent
      sudo systemctl restart vault-agent
    fi
    if [ ! $(systemctl is-active node_exporter) = "active" ]; then
      wget https://github.com/prometheus/node_exporter/releases/download/v1.3.1/node_exporter-1.3.1.linux-amd64.tar.gz
      tar xvf node_exporter-1.3.1.linux-amd64.tar.gz
      sudo cp node_exporter-1.3.1.linux-amd64/node_exporter /usr/local/bin/node_exporter
      sudo cp /vagrant_data/common/node_exporter.service /etc/systemd/system
      sudo mkdir -p /etc/node_exporter/
      sudo mkdir -p /etc/node_exporter/ssl
      sudo cp /vagrant_data/tls/node_exporter.yml /etc/node_exporter/node_exporter.yml
      sudo systemctl enable node_exporter
      sudo systemctl restart node_exporter
    fi
  SHELL
  end
end
