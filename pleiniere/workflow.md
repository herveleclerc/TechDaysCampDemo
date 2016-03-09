# WORKFLOW

### Login
azure login  
  
### Create Resource group  
azure group create techdayscamp northeurope  

### Create VNet
azure network vnet create techdayscamp -n techdayscamp-vnet -l northeurope -a "10.0.0.0/24" -d "8.8.8.8"
  
### Create Subnet
azure network vnet subnet create techdayscamp techdayscamp-vnet -n techdayscamp-sub01 -a "10.0.0.0/24"  

### Create Public IP
azure network public-ip create techdayscamp techdayscamp-ip northeurope -a Dynamic -d techdayscamp01  

### Create NIC
azure network nic create techdayscamp nic0 northeurope -m techdayscamp-vnet -k techdayscamp-sub01 -p techdayscamp-ip


### Create VM 
azure vm create -g techdayscamp -l northeurope -n techdayscampvm -u devops -p TechDaysCamp2016# -w techdayscamp01 -M /Users/hleclerc/.ssh/id_rsa.pub -z standard_a0 -y linux -Q "credativ:Debian:8:latest" -N nic0 -m Dynamic -i techdayscamp-ip

### Extract 
azure resource show "techdayscamp" "techdayscampvm" Microsoft.Compute/virtualMachines -o "2015-06-15" --json









