# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "bento/centos-7.9"
  config.vm.hostname = "node.pki.vagrant"

  config.vm.network "private_network", ip: "192.168.56.10"

  config.vm.synced_folder ".", "/vagrant_data"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"
  end

  config.vm.provision "insecure", type: "shell", inline: <<-SHELL
    sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
    sudo yum install -y epel-release yum-utils wget

    if [ ! $(systemctl is-active vault) = "active" ]; then
      sudo yum -y install vault
      sudo cp /vagrant_data/common/vault.hcl /etc/vault.d/vault.hcl
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
    fi

    if [ ! $(systemctl is-active node_exporter) = "active" ]; then
      wget https://github.com/prometheus/node_exporter/releases/download/v1.3.1/node_exporter-1.3.1.linux-amd64.tar.gz
      tar xvf node_exporter-1.3.1.linux-amd64.tar.gz
      sudo cp node_exporter-1.3.1.linux-amd64/node_exporter /usr/local/bin/node_exporter
      sudo cp /vagrant_data/common/node_exporter.service /etc/systemd/system/node_exporter.service
      sudo mkdir -p /etc/node_exporter/
      sudo cp /vagrant_data/insecure/node_exporter.yml /etc/node_exporter/node_exporter.yml
      sudo systemctl enable node_exporter
      sudo systemctl restart node_exporter
    fi
    
    if [ ! $(systemctl is-active prometheus) = "active" ]; then
      wget https://github.com/prometheus/prometheus/releases/download/v2.33.3/prometheus-2.33.3.linux-amd64.tar.gz
      tar xvf prometheus-2.33.3.linux-amd64.tar.gz
      sudo cp prometheus-2.33.3.linux-amd64/prometheus /usr/local/bin/prometheus
      sudo cp /vagrant_data/common/prometheus.service /etc/systemd/system/prometheus.service
      sudo mkdir -p /etc/prometheus/
      sudo cp /vagrant_data/insecure/prometheus.yml /etc/prometheus/prometheus.yml
      sudo systemctl enable prometheus
      sudo systemctl restart prometheus
    fi
  SHELL
  config.vm.provision "secure", type: "shell", run: "never", inline: <<-SHELL
    sudo yum install jq unzip -y
    export VAULT_ADDR=http://localhost:8200
    export VAULT_TOKEN=$(cat /etc/vault_token.txt)
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
    # vault write pki_int/issue/pki-dot-vagrant common_name="node.pki.vagrant" ttl="24h"
    sudo mkdir -p /etc/prometheus/ssl
    sudo cp /home/vagrant/intermediate.cert.pem /etc/prometheus/ssl
    sudo mkdir -p /etc/node_exporter/ssl
    sudo cp /vagrant_data/tls/node_exporter.yml /etc/node_exporter/node_exporter.yml
    sudo systemctl restart node_exporter
    sudo cp /vagrant_data/tls/prometheus.yml /etc/prometheus/prometheus.yml
    sudo systemctl restart prometheus
    if [ ! $(systemctl is-active consul-template) = "active" ]; then
      wget https://releases.hashicorp.com/consul-template/0.27.2/consul-template_0.27.2_linux_amd64.zip
      unzip -o consul-template_0.27.2_linux_amd64.zip
      sudo cp consul-template /usr/local/bin/consul-template
      sudo cp /vagrant_data/common/consul-template.service /etc/systemd/system/consul-template.service
      sudo mkdir -p /etc/consul-template
      sudo cp /vagrant_data/common/node-exporter.hcl /etc/consul-template
      sudo systemctl enable consul-template
      sudo systemctl restart consul-template
    fi
  SHELL
end
