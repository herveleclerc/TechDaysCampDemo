

### Create from template
### Mode
azure config mode arm
### Group
azure group create techsimplevmgrp northeurope
### VM


azure group deployment create techsimplevmgrp techsimplevm --template-uri https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-vm-simple-linux/azuredeploy.json