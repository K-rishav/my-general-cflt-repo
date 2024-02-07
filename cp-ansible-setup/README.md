# Step-by-Step Setup of Confluent Platform using Ansible and Terraform

## Prerequisites
- Ensure that Terraform is installed on your local system.

## Clone the Repository
```bash
git clone [<repository_url>]
```

## Terraform Setup

### Initialize Terraform
terraform init

### Run the network module
terraform apply -target module.network

### Run the instance module
terraform apply -target module.instances

## Confluent Platform Architecture

1. Bastion host -  used as control node for the ansible.

1. Private instances -  used as target node for the ansible.
- **Kraft:** 3 EC2 instances
- **Kafka:** 3 EC2 instances
- **Schema Registry:** 1 EC2 instance
- **Kafka Connect:** 1 EC2 instance
- **Control Center:** 1 EC2 instance
- **Ksql:** 1 EC2 instance

### SCP public key to Bastion host to be used by ansible in hosts.yml

##  SSH to Bastion Host and run these commands :

```bash 
sudo apt update

sudo apt-get install python3.9

sudo apt install python3-pip
pip install ansible

echo "export PATH=$PATH:/home/ubuntu/.local/bin" >> ~/.bashrc
source ~/.bashrc

sudo apt install openjdk-17-jdk
```
## Certificate Generation on bastion host

To provide custom certs for each host, use the following GitHub repository:

```bash 
# Clone the certificate generation repository and follow the steps mentioned there
git clone https://github.com/sknop/create_certs
```

## Confluent Platform Ansible Collection Installation

```bash
# Install Confluent Platform Ansible collection on the bastion host
ansible-galaxy collection install confluent.platform

cd /home/ubuntu/.ansible/collections/ansible_collections/confluent/platform/playbooks

# Create hosts.yml file in the playbooks directory (Refer to sample hosts.yml in /ansible/)
# Create ansible.cfg in the current directory (Refer to sample ansible.cfg in /ansible/)
```

## Run Ansible Playbook to Install CP Components

```bash
# Run the Ansible playbook to install Confluent Platform components
ansible-playbook -i hosts.yml confluent.platform.all
```

## Check Connectivity
```bash
# Check connectivity to a broker
openssl s_client -connect <broker-dns>:9092
```

If the response is "CONNECTED," the setup is working successfully.

## References

1. https://docs.confluent.io/ansible/current/overview.html
1. https://docs.confluent.io/ansible/current/ansible-encrypt.html#use-custom-certs-for-tls

