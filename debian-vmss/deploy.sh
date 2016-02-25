#!/bin/bash

# install Ansible (in a loop because a lot of installs happen
# on VM init, so won't be able to grab the dpkg lock immediately)
until apt-get -y update && apt-get -y install python-pip python-dev git 
do
  echo "Try again"
  sleep 2
done

pip install PyYAML jinja2 paramiko
git clone https://github.com/ansible/ansible.git
cd ansible
git submodule update --init --recursive
make install
mkdir /etc/ansible
cp examples/hosts /etc/ansible/.
echo "[localhost]" >> /etc/ansible/hosts
echo "127.0.0.1"   >> /etc/ansible/hosts

# Record private IP
cd /usr/local
touch privateIP.txt

echo $1 >> privateIP.txt
