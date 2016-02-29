#!/bin/bash

function log()
{
	# Consider to log to an log server
    echo "`date` : $1"
}

function usage()
 {
    echo "INFO:"
    echo "Usage: deploy-via-ansible.sh [number of nodes] [prefix des vm] [fqdn of ansible control vm] [ansible user]"
}


numberOfNodes=$1
vmNamePrefix=$2
ansiblefqdn=$3
sshu=$4

FACTS=/etc/ansible/facts

log "Begin Installation"

p1=$(echo $ansiblefqdn|cut -f1 -d.)
tld=$(echo $ansiblefqdn | sed "s?$p1\.??")

log "tld is ${tld}"

mkdir -p ~/.ssh
 
cat << 'EOF' >> ~/.ssh/config
Host *
    user devops
    StrictHostKeyChecking no
EOF

chmod 700 ~/.ssh

for i in $(seq 1 $numberOfNodes)
do
	log "trying to ssh -l ${sshu} ${tld} cat $FACTS/private-ip.fact"

	su - devops -c "ssh -l ${sshu} ${vmNamePrefix}${i}.${tld} cat $FACTS/private-ip.fact" >> /tmp/hosts.inv 
done


# install Ansible (in a loop because a lot of installs happen
# on VM init, so won't be able to grab the dpkg lock immediately)
until apt-get -y update && apt-get -y install python-pip python-dev git 
do
  log "Try again"
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
echo " "           >> /etc/ansible/hosts

echo "[cluster]"   >> /etc/ansible/hosts
for i in `cat /tmp/hosts.inv` 
do
  echo "$i"        >> /etc/ansible/hosts
done 

log "End Installation"
