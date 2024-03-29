# Azure private DNS resolver Samples

Env. variables which will be used during this demo:

~~~ bash
$prefix="cptddnsr"
$location="eastus"
$myip=$(curl ifconfig.io).Content # Just in case we like to whitelist our own ip.
$myobjectid=$(az ad user list --query '[?displayName==`ga`].id' -o tsv) # just in case we like to assing some RBAC roles to ourself.
$oprgname="file-rg" # name of the already existing resource group
$opvnetname="file-rg-vnet" # name of the already existing vnet
$opvnetid=$(az network vnet show -g $oprgname -n $opvnetname --query id -o tsv) 
$opvnetcidr=$(az network vnet show -g $oprgname -n $opvnetname --query addressSpace.addressPrefixes[0] -o tsv)
$opvmdcname="dc-01-win-vm"
$opvmclname="client-01-win-vm"
$opnicdcname="dc-01-win-vm267"
$opnicdcid=$(az vm show -g $oprgname -n $opvmdcname --query networkProfile.networkInterfaces[0].id -o tsv)
$opdnsip=$(az network nic show --ids $opnicdcid --query ipConfigurations[0].privateIpAddress -o tsv)
$opfqdn="myedge.org."
~~~

## Test Inbound case

Show DNS settings on ADDC

~~~powershell
$opvmdcid=$(az vm show -g $oprgname -n $opvmdcname --query id -o tsv)
az network bastion rdp -n ${prefix}hub -g $prefix --target-resource-id $opvmdcid
# use the fqdn of our spoke vm, autogenerated by our private dns zone.
~~~

Send dns query from onprem VM

~~~powershell
$opvmclid=$(az vm show -g $oprgname -n $opvmclname --query id -o tsv)
az network bastion rdp -n ${prefix}hub -g $prefix --target-resource-id $opvmclid
nslookup cptddnsrspoke1.cptddnsr.org
~~~
