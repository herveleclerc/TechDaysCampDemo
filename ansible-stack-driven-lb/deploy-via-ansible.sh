#!/bin/bash

function log()
{
	# Consider to log to an log server
  mess="`hostname`: $1"

	url="https://rocket.alterway.fr/hooks/44vAPspqqtD7Jtmtv/k4Tw89EoXiT5GpniG/HaxMfijFFi5v1YTEN68DOe5fzFBBxB4YeTQz6w3khFE%3D"
	payload="payload={\"icon_emoji\":\":cloud:\",\"text\":\"$mess\"}"
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

ANSIBLE_HOST_FILE=/etc/ansible/hosts
ANSIBLE_CONFIG_FILE=/etc/ansible/ansible.cfg

CRATE_TPL="/tmp/crate.yml.j2"



# Installation of curl for logging
until apt-get -y update && apt-get -y install curl 
do
  log "Lock detected on VM init Try again..."
  sleep 2
done


log "Begin Installation on Azure"

p1=$(echo $ansiblefqdn|cut -f1 -d.)
tld=$(echo $ansiblefqdn | sed "s?$p1\.??")

# log "tld is ${tld}"

mkdir -p ~/.ssh

# Root User
# No host Checking for root 

log "Create ssh configuration for root"
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

log "Create ssh configuration for ${sshu}"
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

log "Get private Ips..."

let numberOfNodes=$numberOfNodes-1

for i in $(seq 0 $numberOfNodes)
do
	# log "trying to su - devops -c ssh -l ${sshu} ${vmNamePrefix}${i}.${tld} cat $FACTS/private-ip.fact"
	su - devops -c "ssh -l ${sshu} ${vmNamePrefix}${i}.${tld} cat $FACTS/private-ip.fact" >> /tmp/hosts.inv 
done


# install Ansible (in a loop because a lot of installs happen
# on VM init, so won't be able to grab the dpkg lock immediately)
log "Install ansible required packets..."

until apt-get -y update && apt-get -y install python-pip python-dev git 
do
  log "Lock detected on VM init Try again..."
  sleep 2
done

log "Install ansible required python modules..."
pip install PyYAML jinja2 paramiko

log "Clone ansible repo..."
git clone https://github.com/ansible/ansible.git

cd ansible

log "Clone ansible submodules..."
git submodule update --init --recursive

log "Install ansible..."
make install

log "Generate ansible files..."
mkdir /etc/ansible
cp examples/hosts /etc/ansible/.
echo "[localhost]" >> ${ANSIBLE_HOST_FILE}
echo "127.0.0.1"   >> ${ANSIBLE_HOST_FILE}
echo " "           >> ${ANSIBLE_HOST_FILE}

echo "[cluster]"   >> ${ANSIBLE_HOST_FILE}
for i in `cat /tmp/hosts.inv` 
do
  echo "$i"        >> ${ANSIBLE_HOST_FILE}
done 


# Accept ssh keys by default    
printf  "[defaults]\nhost_key_checking = False\n\n" >> "${ANSIBLE_CONFIG_FILE}"   
# Shorten the ControlPath to avoid errors with long host names , long user names or deeply nested home directories
echo  $'[ssh_connection]\ncontrol_path = ~/.ssh/ansible-%%h-%%r' >> "${ANSIBLE_CONFIG_FILE}"   

mess=$(ansible cluster -m ping)
log "$mess"



log "Create crate.yml template"
echo "cluster.name: techdayscamp2016"              >  "${CRATE_TPL}"
echo "discovery.zen.ping.multicast.enabled: false" >> "${CRATE_TPL}"
echo "discovery.zen.ping.unicast.hosts:"           >> "${CRATE_TPL}"
for i in `cat /tmp/hosts.inv` 
do
  echo "- $i:4300"                                 >> "${CRATE_TPL}"
done

log "Download ansible galaxy roles"
log "  - java"
ansible-galaxy install williamyeh.oracle-java -p .

log "Playing playbook"
ansible-playbook crate-setup.yml --extra-vars "target=cluster"

log "End Installation On Azure"
