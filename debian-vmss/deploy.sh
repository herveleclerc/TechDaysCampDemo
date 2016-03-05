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
  curl -s -X POST --data-urlencode "$payload" "$url" > /dev/null 2>&1
    
  echo "$(date) : $1"
}

function install_ansible()
{
  log "Installing Ansible from repo ..." "0"
  until apt-get -y update && apt-get -y install python-pip python-dev git htop stress libssl1.0.0 libssl-dev
  do
    log "Lock detected on VM init Try again..." "0"
    sleep 2
  done
  error_log "unable to get system packages"

  log "Install ansible required python modules..." "0"
  pip install PyYAML jinja2 paramiko
  error_log "unable to install python packages via pip"


  log "Clone ansible repo..." "0"
  rm -rf ansible
  error_log "unable to remove ansible directory"

  git clone https://github.com/ansible/ansible.git
  error_log "unable to clone ansible repo"

  cd ansible || error_log "unable to cd to ansible directory"

  log "Clone ansible submodules..." "0"
  git submodule update --init --recursive
  error_log "unable to clone ansible submodules"

  log "Install ansible..." "0"
  make install
  error_log "unable to install ansible"

  log "Generate ansible files..." "0"
  rm -rf /etc/ansible
  error_log "unable to remove /etc/ansible directory"
  mkdir -p /etc/ansible
  error_log "unable to create /etc/ansible directory"

  cp examples/hosts /etc/ansible/.
  error_log "unable to copy hosts file to /etc/ansible"

  printf "[local]\nlocalhost ansible_connection=local\n\n" >> ${ANSIBLE_HOST_FILE}
  printf "deprecation_warnings=False\n\n"                  >> ${ANSIBLE_CONFIG_FILE}

  cd $CWD

  log "Installing Ansible from repo done !" "0"
}

function write_fact()
{
  mkdir -p $FACTS
  echo "${privateIP}" > $FACTS/private-ip.fact 

  chmod a+r $FACTS/private-ip.fact 
}

function install_curl()
{
  # Installation of curl for logging
  until apt-get -y update && apt-get -y install curl 
  do
    log "Lock detected on VM init Try again..." "0"
    sleep 2
  done
  log "Installing curl done !" "0"
  log ":rocket:INSTALLING CRATE CLUSTER ON VM SCALESET (VMSS)" "0"
}

function create_crate_config()
{
  log "Create crate.yml template" "0"
  echo "cluster.name: techdayscamp2016"              >  "${CRATE_TPL}"
  echo "discovery.zen.ping.multicast.enabled: false" >> "${CRATE_TPL}"
  echo "discovery.zen.ping.unicast.hosts:"           >> "${CRATE_TPL}"
  
  let num=$numberOfNodes-1
  for i in $(seq 0 $num)
  do
  	  let j=4+$i
      echo "- 10.0.0.$j:4300"                        >> "${CRATE_TPL}"
  done
  error_log "unable to create crate config file content"
  log "Create crate.yml template done !" "0"
}

function deploy_crate()
{
  log "Deploying crate ..." "0"
  cd $CWD
  log "Download ansible galaxy roles" "0"
  log "  - java" "0"

  rm -rf smola.java
  error_log "unable to remove smola.java role"

  rm -rf ansible-java-role
  error_log "unable to remove ansible-java-role role"

  ansible-galaxy install -p . git+https://github.com/smola/ansible-java-role
  error_log "unable to galaxy java"

  mv ansible-java-role smola.java
  error_log "unable to rename role"

  log "Playing playbook" "0"
  ansible-playbook crate-setup.yml --extra-vars "target=local"
  error_log "playbook crate had errors"

  log "End Installation On Azure" "0"
}

## Script begins here

CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"

IPpriv=$1
numberOfNodes=$2

FACTS=/etc/ansible/facts
export FACTS

ANSIBLE_HOST_FILE=/etc/ansible/hosts
ANSIBLE_CONFIG_FILE=/etc/ansible/ansible.cfg
CRATE_TPL="/tmp/crate.yml.j2"

## deploy start here
write_fact
install_curl
create_crate_config
install_ansible
deploy_crate
