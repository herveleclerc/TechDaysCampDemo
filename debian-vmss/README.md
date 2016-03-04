
# Autoscale a Linux VM Scale Set  

The following template deploys a Linux VM Scale Set integrated with Azure autoscale  

The template deploys a Linux VMSS with a desired count of VMs in the scale set. Once the VM Scale Sets is deployed, user can deploy an application inside each of the VMs (either by directly logging into the VMs or via a custom script extension)  

The Autoscale rules are configured as follows  
- sample for CPU (\\Processor\\PercentProcessorTime) in each VM every 1 Minute  
- if the Percent Processor Time is greater than 50% for 5 Minutes, then the scale out action (add more VM instances, one at a time) is triggered
- once the scale out action is completed, the cool down period is 1 Minute  



### Azure portal  

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fherveleclerc%2FTechDaysCampDemo%2Fmaster%2Fdebian-vmss%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fherveleclerc%2FTechDaysCampDemo%2Fmaster%2Fdebian-vmss%2Fazuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>


### Dedicated Deployment portal  

[![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://azuredeploy.net/)  


### Access to vm
ssh   from port 50000 to 50099
crate from port 4200  to 4299

