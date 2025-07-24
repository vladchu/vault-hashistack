#!/bin/bash
#
# user-data script for deploying Nomad on Amazon Linux 2
#
# Using the user-data / cloud init ensures we don't run twice
#

# Update system and install dependencies
sudo apt-get update -y
sudo apt-get install unzip curl vim jq -y
# make an archive folder to move old binaries into
if [ ! -d /tmp/archive ]; then
  sudo mkdir /tmp/archive/
fi

# Install docker
sudo apt  install docker.io -y
sudo systemctl restart docker

# Set up volumes
sudo mkdir /data /data/mysql /data/certs /data/prometheus /data/templates
sudo chown root -R /data

# Install Nomad
NOMAD_VERSION=1.3.3
sudo curl -sSL https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip -o nomad.zip
if [ ! -d nomad ]; then
  sudo unzip nomad.zip
fi
if [ ! -f /usr/bin/nomad ]; then
  sudo install nomad /usr/bin/nomad
fi
if [ -f /tmp/archive/nomad ]; then
  sudo rm /tmp/archive/nomad
fi
sudo mv /tmp/nomad /tmp/archive/nomad
sudo mkdir -p /etc/nomad.d
sudo chmod a+w /etc/nomad.d

# Nomad config file copy
sudo mkdir -p /tmp/nomad
sudo curl https://raw.githubusercontent.com/devops-kyrrex-com/vault-hashistack/main/conf/nomad/server.hcl -o /tmp/nomad/server.hcl
sudo cp /tmp/nomad/server.hcl /etc/nomad.d/server.hcl

# Install Consul
CONSUL_VERSION=1.13.1
sudo curl -sSL https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip > consul.zip
if [ ! -d consul ]; then
  sudo unzip consul.zip
fi
if [ ! -f /usr/bin/consul ]; then
  sudo install consul /usr/bin/consul
fi
if [ -f /tmp/archive/consul ]; then
  sudo rm /tmp/archive/consul
fi
sudo mv /tmp/consul /tmp/archive/consul
sudo mkdir -p /etc/consul.d
sudo chmod a+w /etc/consul.d

# Consul config file copy
sudo mkdir -p /tmp/consul
sudo curl https://raw.githubusercontent.com/devops-kyrrex-com/vault-hashistack/main/conf/consul/server.hcl -o /tmp/consul/server.hcl
sudo cp /tmp/consul/server.hcl /etc/consul.d/server.hcl

for bin in cfssl cfssl-certinfo cfssljson
do
  echo "$bin Install Beginning..."
  if [ ! -f /tmp/${bin} ]; then
    curl -sSL https://pkg.cfssl.org/R1.2/${bin}_linux-amd64 > /tmp/${bin}
  fi
  if [ ! -f /usr/local/bin/${bin} ]; then
    sudo install /tmp/${bin} /usr/local/bin/${bin}
  fi
done
cat /root/.bashrc | grep  "complete -C /usr/bin/nomad nomad"
retval=$?
if [ $retval -eq 1 ]; then
  nomad -autocomplete-install
fi

# Install Ansible for config management
sudo amazon-linux-extras install ansible2 -y

# Form Consul Cluster
ps -C consul
retval=$?
if [ $retval -eq 0 ]; then
  sudo killall consul
fi
sudo nohup consul agent --config-file /etc/consul.d/server.hcl >$HOME/consul.log &

# Form Nomad Cluster
ps -C nomad
retval=$?
if [ $retval -eq 0 ]; then
  sudo killall nomad
fi
sudo nohup nomad agent -config /etc/nomad.d/server.hcl >$HOME/nomad.log &

# Bootstrap Nomad and Consul ACL environment

# Write anonymous policy file

sudo tee -a /tmp/anonymous.policy <<EOF
namespace "*" {
  policy       = "write"
  capabilities = ["alloc-node-exec"]
}

agent {
  policy = "write"
}

operator {
  policy = "write"
}

quota {
  policy = "write"
}

node {
  policy = "write"
}

host_volume "*" {
  policy = "write"
}
EOF

# Install Vault
VAULT_VERSION=1.11.3
sudo curl -sSL https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip -o vault.zip
if [ ! -d vault ]; then
  sudo unzip vault.zip
fi
if [ ! -f /usr/bin/vault ]; then
  sudo install vault /usr/bin/vault
fi
if [ -f /tmp/archive/vault ]; then
  sudo rm /tmp/archive/vault
fi
sudo mv /tmp/vault /tmp/archive/vault
sudo mkdir -p /etc/vault.d
sudo chmod a+w /etc/vault.d

# Vault config file copy
sudo mkdir -p /tmp/vault
sudo curl https://raw.githubusercontent.com/devops-kyrrex-com/vault-hashistack/main/conf/vault/server.hcl -o /tmp/vault/server.hcl
sudo cp /tmp/vault/server.hcl /etc/vault.d/server.hcl

# Form Vault Cluster
vault server -config=/etc/vault.d/server.hcl
# ps -C vault
# retval=$?
# if [ $retval -eq 0 ]; then
#   sudo killall vault
# fi
# sudo nohup vault agent -config /etc/vault.d/server.hcl >$HOME/vault.log &
