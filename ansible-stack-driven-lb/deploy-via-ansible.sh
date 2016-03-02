#!/bin/bash

error_log()
{
    if [ "$?" != "0" ]; then
        log "$1" "1"
        log "Deployment ends with an error" "1"
        exit 1
    fi
}

function log()
{
	
  x=":ok:"

  if [ "$2" != "0" ]; then
    x=":hankey:"
  fi
  mess="$(hostname): $x $1"

	url="https://rocket.alterway.fr/hooks/44vAPspqqtD7Jtmtv/k4Tw89EoXiT5GpniG/HaxMfijFFi5v1YTEN68DOe5fzFBBxB4YeTQz6w3khFE%3D"
	payload="payload={\"icon_emoji\":\":cloud:\",\"text\":\"$mess\"}"
  curl -X POST --data-urlencode "$payload" "$url"
    
  echo "$(date) : $1"
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
viplb=$5

FACTS=/etc/ansible/facts
export FACTS

ANSIBLE_HOST_FILE=/etc/ansible/hosts
ANSIBLE_CONFIG_FILE=/etc/ansible/ansible.cfg

CRATE_TPL="/tmp/crate.yml.j2"


# Installation of curl for logging
until apt-get -y update && apt-get -y install curl 
do
  log "Lock detected on VM init Try again..."
  sleep 2
done


log "Begin Installation on Azure parameters : numberOfNodes=$numberOfNodes vmNamePrefix=$vmNamePrefix ansiblefqdn=$ansiblefqdn sshu=$sshu viplb=$viplb" "0"

p1=$(echo "$ansiblefqdn" | cut -f1 -d.)
tld=$(echo "$ansiblefqdn"  | sed "s?$p1\.??")

# log "tld is ${tld}"

mkdir -p ~/.ssh

# Root User
# No host Checking for root 

log "Create ssh configuration for root" "0"
cat << 'EOF' >> ~/.ssh/config
Host *
    user devops
    StrictHostKeyChecking no
EOF
error_log "unable to create ssh config file for root"

cp id_rsa ~/.ssh/id_rsa
error_log "unable to copy id_rsa key to root .ssh directory"

cp id_rsa.pub ~/.ssh/id_rsa.pub
error_log "unable to copy id_rsa.pub key to root .ssh directory"

chmod 700 ~/.ssh
error_log "unable to chmod root .ssh directory"

chmod 400 ~/.ssh/id_rsa
error_log "unable to chmod root id_rsa file"

chmod 644 ~/.ssh/id_rsa.pub
error_log "unable to chmod root id_rsa.pub file"

## Devops User
# No host Checking for sshu 

log "Create ssh configuration for ${sshu}" "0"
cat << 'EOF' >> /home/${sshu}/.ssh/config
Host *
    user devops
    StrictHostKeyChecking no
EOF
error_log "unable to create ssh config file for user ${sshu}"


cp id_rsa "/home/${sshu}/.ssh/id_rsa"
error_log "unable to copy id_rsa key to $sshu .ssh directory"

cp id_rsa.pub "/home/${sshu}/.ssh/id_rsa.pub"
error_log "unable to copy id_rsa.pub key to $sshu .ssh directory"

chmod 700 "/home/${sshu}/.ssh"
error_log "unable to chmod $sshu .ssh directory"

chown -R "${sshu}:" "/home/${sshu}/.ssh"
error_log "unable to chown to $sshu .ssh directory"

chmod 400 "/home/${sshu}/.ssh/id_rsa"
error_log "unable to chmod $sshu id_rsa file"

chmod 644 "/home/${sshu}/.ssh/id_rsa.pub"
error_log "unable to chmod $sshu id_rsa.pub file"

# remove when debugging
# rm id_rsa id_rsa.pub 

log "Get private Ips..." "0"

let numberOfNodes=$numberOfNodes-1

for i in $(seq 0 $numberOfNodes)
do
	# log "trying to su - devops -c ssh -l ${sshu} ${vmNamePrefix}${i}.${tld} cat $FACTS/private-ip.fact"
	su - devops -c "ssh -p 220${i} -l ${sshu} ${viplb} cat $FACTS/private-ip.fact" >> /tmp/hosts.inv 
  error_log "unable to ssh to ${viplb} with user $sshu"
done


# install Ansible (in a loop because a lot of installs happen
# on VM init, so won't be able to grab the dpkg lock immediately)
log "Install ansible required packets..." "0"

until apt-get -y update && apt-get -y install python-pip python-dev git 
do
  log "Lock detected on VM init Try again..." "0"
  sleep 2
done
error_log "unable to get system packages"

log "Install ansible required python modules..." "0"
pip install PyYAML jinja2 paramiko
error_log "unable to install python packages via pip"


log "Clone ansible repo..."
git clone https://github.com/ansible/ansible.git
error_log "unable to clone ansible repo"

cd ansible || error_log "unable to cd to ansible directory"

log "Clone ansible submodules..."
git submodule update --init --recursive
error_log "unable to clone ansible submodules"

log "Install ansible..."
make install
error_log "unable to install ansible"

log "Generate ansible files..." "0"
mkdir /etc/ansible
error_log "unable to create /etc/ansible directory"

cp examples/hosts /etc/ansible/.
error_log "unable to copy hosts file to /etc/ansible"

printf "[localhost]\n127.0.0.1\n\n" >> ${ANSIBLE_HOST_FILE}

echo "[cluster]"   >> ${ANSIBLE_HOST_FILE}
for i in $(cat /tmp/hosts.inv)
do
  echo "$i"        >> ${ANSIBLE_HOST_FILE}
done 
error_log "unable to create hosts file entries to /etc/ansible"



# Accept ssh keys by default    
printf  "[defaults]\nhost_key_checking = False\n\n" >> "${ANSIBLE_CONFIG_FILE}"   
# Shorten the ControlPath to avoid errors with long host names , long user names or deeply nested home directories
echo  $'[ssh_connection]\ncontrol_path = ~/.ssh/ansible-%%h-%%r' >> "${ANSIBLE_CONFIG_FILE}"   

mess=$(ansible cluster -m ping)
log "$mess" "1"


log "Create crate.yml template" "0"
echo "cluster.name: techdayscamp2016"              >  "${CRATE_TPL}"
echo "discovery.zen.ping.multicast.enabled: false" >> "${CRATE_TPL}"
echo "discovery.zen.ping.unicast.hosts:"           >> "${CRATE_TPL}"
for i in $(cat /tmp/hosts.inv)
do
  echo "- $i:4300"                                 >> "${CRATE_TPL}"
done
error_log "unable to create crate config file content"


log "Download ansible galaxy roles" "0"
log "  - java" "0"
ansible-galaxy install williamyeh.oracle-java -p .
error_log "unable to galaxy java"

log "Playing playbook" "0"
ansible-playbook crate-setup.yml --extra-vars "target=cluster"
error_log "playbook crate had errors"

log "End Installation On Azure" "0"
