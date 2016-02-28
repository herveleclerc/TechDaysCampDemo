#!/bin/bash

privateIP=$1
FACTS=/etc/ansible/facts

mkdir -p $FACTS
echo "${privateIP}" > $FACTS/private-ip.fact 

chmod 755 /etc/ansible
chmod 755 /etc/ansible/facts
chmod a+r $FACTS/private-ip.fact 

exit 0