#!/bin/bash
numberOfNodes=$1
vmNamePrefix=$2
location=$3

FACTS=/etc/ansible/facts
sshu=devops

location=`echo $location | tr '[:upper:]' '[:lower:]' | tr -d ' '`



mkdir -p ~/.ssh
 
cat << 'EOF' >> ~/.ssh/config
Host *
    user devops
    StrictHostKeyChecking no
EOF

chmod 700 ~/.ssh

for i in $(seq 1 $numberOfNodes)
do
	su - devops -c "ssh -l ${sshu} ${vmNamePrefix}${i}.${location}.cloudapp.net cat $FACTS/private-ip.fact" >> /tmp/hosts.inv 
done


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
echo " "            >> /etc/ansible/hosts

echo "[cluster]"   >> /etc/ansible/hosts
for i in `cat /tmp/hosts.inv` 
do
  echo "$i"        >> /etc/ansible/hosts
done 


