# Single Click provisioning of :  
- Multiple instances of debian  
- Ansible command control vm  

Then  install on each node crate database node (http://crate.io)
After installation cluster will be reachable on :
for exemple :  
- http://lbawtecnode.northeurope.cloudapp.azure.com:4200/  
or  
- http://lbawtecnode.northeurope.cloudapp.azure.com:8201/  
  
- the fqdn depends on the choice you've made in the parameter's screen.

To make it works you mus create a resource group with an storage account with 3 containers named :  
- keys  
- playbooks  
- scripts  
  
you must put a id_rsa and id_rsa.pub files in keys, crate-setup.yml, crate.yml in playbooks, and deploy-via-ansible.sh in scripts  
   

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fherveleclerc%2FTechDaysCampDemo%2Fmaster%2Fansible-stack-driven-lb%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https://raw.githubusercontent.com/herveleclerc/TechDaysCampDemo/master/ansible-stack-driven-lb/azuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>


    ┌─────────────────────────────────────────────────────────────────────────────────────────────────────┐
    │                                                                                                     │
    │                                                                                                     │
    │                                                                                                     │
    │                                                                                                     │
    │                          ┌──────────────────────────────────────────┐                               │
    │                          │lbawtecnode.northeurop─.cloudapp.azure.com│                               │
    │                          └──────────────────────────────────────────┘                               │
    │                          ┌───────────────────┐  ┌───────────────────┐                               │
    │                          │ VM # 1: scale.io  │  │ VM #2 : scale.io  │                               │
    │                          └───────────────────┘  └───────────────────┘                               │
    │┌───────────────────┐               ▲                      ▲                                         │
    ││ansible vault :    │               └──────────────────────┴────────────────────────────┐            │
    ││(storage account)  │                                                                   ▼            │
    ││Private Blob :     │                                                         ┌───────────────────┐  │
    ││- keys             │ ◀────────────────Script VMExtension────────────────────▶│  VM # : ansible   │  │
    ││- playbooks        │                                                         └───────────────────┘  │
    ││- scripts          │                                                                                │
    │└───────────────────┘                                                                                │
    │                                                                                                     │
    │                                                                                                     │
    │                                                                                                     │
    │                                           Resource Group                                            │
    └─────────────────────────────────────────────────────────────────────────────────────────────────────┘