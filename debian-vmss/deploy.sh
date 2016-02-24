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
make install
mkdir /etc/ansible
cp ~/ansible/examples/hosts /etc/ansible/.