#!/bin/bash

function log()
{
	# Consider to log to an log server
	url="https://rocket.alterway.fr/hooks/44vAPspqqtD7Jtmtv/k4Tw89EoXiT5GpniG/HaxMfijFFi5v1YTEN68DOe5fzFBBxB4YeTQz6w3khFE%3D"
	payload="payload={\"icon_emoji\":\":cloud:\",\"text\":\"$1\"}"
  curl -X POST --data-urlencode "$payload" "$url"
    
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
export FACTS

# Installation of curl for logging
until apt-get -y update && apt-get -y install curl 
do
  log "Try again"
  sleep 2
done


log "Begin Installation"

p1=$(echo $ansiblefqdn|cut -f1 -d.)
tld=$(echo $ansiblefqdn | sed "s?$p1\.??")

log "tld is ${tld}"

mkdir -p ~/.ssh

# Root User
# No host Checking for root 
cat << 'EOF' >> ~/.ssh/config
Host *
    user devops
    StrictHostKeyChecking no
EOF

cp id_rsa ~/.ssh/id_rsa
cp id_rsa.pub ~/.ssh/id_rsa.pub

chmod 700 ~/.ssh
chmod 400 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub

## Devops User
# No host Checking for sshu 
cat << 'EOF' >> /home/${sshu}/.ssh/config
Host *
    user devops
    StrictHostKeyChecking no
EOF

cp id_rsa /home/${sshu}/.ssh/id_rsa
cp id_rsa.pub /home/${sshu}/.ssh/id_rsa.pub

chmod 700 /home/${sshu}/.ssh
chown -R ${sshu}: /home/${sshu}/.ssh
chmod 400 /home/${sshu}/.ssh/id_rsa
chmod 644 /home/${sshu}/.ssh/id_rsa.pub

# remove when debugging
# rm id_rsa id_rsa.pub 

for i in $(seq 0 $numberOfNodes)
do
	log "trying to su - devops -c ssh -l ${sshu} ${vmNamePrefix}${i}.${tld} cat $FACTS/private-ip.fact"

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
