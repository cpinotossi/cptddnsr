# Azure private DNS resolver Samples

## Simple private DNS resolver demo

Based on:
- https://docs.microsoft.com/en-us/azure/dns/dns-private-resolver-get-started-portal
- https://docs.microsoft.com/en-US/cli/azure/dns-resolver?view=azure-cli-latest

The following sample demonstrates how to create a private DNS resolver inbound rule.

~~~ mermaid
classDiagram
hub --> OnPrem : vpn
hub --> spoke1 : peering
hub : cidr 10.5.0.0/16
hub : bastion
hub : privat DNS Resolver
pDNS --> hub : link/resolve
pDNS --> spoke1 : link/autoreg
pDNS --> spoke2 : link/autoreg
pDNS: cptddnsr.org
spoke2 : cidr 10.4.0.0/16
spoke2 : bastion
spoke2 : vm 10.4.0.4
spoke1 : cidr 10.3.0.0/16
spoke1 : vm 10.3.0.4
OnPrem : cidr 10.1.0.0/16
OnPrem : ADDC 10.1.0.4
OnPrem : vm 10.1.0.5
~~~

The following sequence diagram does show how the DNS query does get resolved.

- spoke1VM: VM located at Spoke1. Autoregistered via Azure private DN (10.3.1.4)
- ADDC: VM located onPrem which does run the DNS Service (10.1.0.4)
- onPremVM: VM located onPrem which acts as a client (10.1.0.5)
- pDNSr: The Azure private DNS resolver service (listen on 10.3.2.4:53)
- pDNSz: The Azure private DNS zone (cptddnsr.org.)

~~~ mermaid
sequenceDiagram
    participant onPremVM
    participant ADDC
    participant pDNSr
    participant pDNSz
    onPremVM->>ADDC: DNS query resolve cptddnsrspoke1.cptddnsr.org.
    Note right of ADDC: verify if conditional dns forward exists
    ADDC-->>pDNSr: fwd DNS query for cptddnsrspoke1.cptddnsr.org.
    pDNSr->>pDNSz: fwd DNS query for cptddnsrspoke1.cptddnsr.org.
    Note right of pDNSz: resolve to IP 10.3.1.4
    pDNSz->>pDNSr: fwd IP 10.3.1.4
    pDNSr->>ADDC: fwd IP 10.3.1.4
    ADDC->>onPremVM: IP 10.3.1.4
~~~

The idea of the Azure private DNS resolver is to overcome the challenge with the none routable IP 168.63.129.16 which does provide DNS services inside a azure vNet. The issue is described [here](https://docs.microsoft.com/en-us/answers/questions/181776/azure-private-dns-zone-resolution-from-on-prem.html) in more details. 

To overcome the need to setup your own VMs which run a DNS Server (IaaS) Azure now offers a managed version (PaaS). Because our demo does not include a real on-prem enviroment we are going to mimic one by just using an Azure VNets which is peering to the hub vnet.

> IMPORTANT: The templates and commands provide here will only create parts of the enviroment.
The grey area is not covered by the templates and commands of this repo.

![Overview](media/cptdpdnsr.002.png)

In case you like to create the whole enviroment the following repo could be helpfully:
- [Github repo to create a ADDC](https://github.com/Azure/azure-quickstart-templates/tree/master/application-workloads/active-directory/active-directory-new-domain-module-use)
- [How to setup conditional forwarding on MS Server](https://www.interfacett.com/blogs/windows-server-how-to-configure-a-conditional-forwarder-in-dns/)

Register the private DNS resolver at our Azure subscription

> NOTE: At the time of writing, Azure private DNS resolver is still in preview. Therefore we need to verify if Azure privat DNS resolver is registered under your subscription.

~~~ bash
az provider register --namespace Microsoft.Network # register the whole namespace wich also includes the dns-resolver
az provider show --namespace Microsoft.Network -o table --query resourceTypes[].resourceType -o table | grep dnsResolvers # verify if dnsResolver has been installed
~~~

Env. variables which will be used during this demo:

~~~ bash
prefix=cptddnsr
location=eastus
myip=$(curl ifconfig.io) # Just in case we like to whitelist our own ip.
myobjectid=$(az ad user list --query '[?displayName==`ga`].id' -o tsv) # just in case we like to assing some RBAC roles to ourself.
~~~

Create foundation resources:

~~~ bash
az group create -n $prefix -l $location
az deployment group create -n $prefix -g $prefix --mode incremental --template-file bicep/deploy.bicep -p prefix=$prefix myobjectid=$myobjectid location=$location
~~~

Peer to existing infrastructe which does mimic onprem with ADDC and windows and linux clients:

~~~ bash
rgop=file-rg # name of the already existing resource group
vnetop=file-rg-vnet # name of the already existing vnet
# peer from hub to onprem
vnetopid=$(az network vnet show -g $rgop -n $vnetop --query id -o tsv) 
az network vnet peering create -n hub2onprem --remote-vnet $vnetopid -g $prefix --vnet-name ${prefix}hub --allow-forwarded-traffic --allow-vnet-access
# peer from onprem to hub
vnethubid=$(az network vnet show -g $prefix -n ${prefix}hub --query id -o tsv)
az network vnet peering create -n onprem2hub --remote-vnet $vnethubid -g $rgop --vnet-name $vnetop  --allow-forwarded-traffic --allow-vnet-access 
~~~

Create the private DNS resolver:

~~~ bash
# Create dns resolver
az dns-resolver create -n $prefix -g $prefix -l $location --id $vnethubid
# Create dns resolver inbound
dnsinsn=$(az network vnet subnet show -g $prefix -n dnsrin --vnet-name ${prefix}hub --query id -o tsv) # subnet id dns resolver in.
az dns-resolver inbound-endpoint create --dns-resolver-name $prefix -n $prefix -g $prefix --ip-configurations "[{private-ip-address:'',private-ip-allocation-method:dynamic,id:$dnsinsn}]" -l $location
# Create dns resolver outbound
dnsoutsn=$(az network vnet subnet show -g $prefix -n dnsrout --vnet-name ${prefix}hub --query id -o tsv) # subnet id dns resolver out
az dns-resolver outbound-endpoint create --dns-resolver-name $prefix -n $prefix -g $prefix -l $location --id $dnsoutsn
dnsoutid=$(az dns-resolver outbound-endpoint show --dns-resolver-name $prefix -n $prefix -g $prefix --query id -o tsv) 
az dns-resolver forwarding-ruleset create -n $prefix -l $location -g $prefix --outbound-endpoints "[{id:$dnsoutid}]"
dcip=$(az network nic show --ids $(az vm show -g $rgop -n dc-01-win-vm --query networkProfile.networkInterfaces[0].id -o tsv) --query ipConfigurations[0].privateIpAddress -o tsv)
az dns-resolver forwarding-rule create --forwarding-rule-name $prefix -g $prefix --ruleset-name $prefix --domain-name myedge.org. --forwarding-rule-state Enabled --target-dns-servers ip-address="${dcip}"
# link dns resolver to spoke vnets
vnetspoke1id=$(az network vnet show -g $prefix -n ${prefix}spoke1 --query id -o tsv) # Retrieve vnet id.
az dns-resolver vnet-link create -n ${prefix}spoke1 -g $prefix --ruleset-name $prefix --id $vnetspoke1id # link dns resolver to spoke vnet
vnetspoke2id=$(az network vnet show -g $prefix -n ${prefix}spoke2 --query id -o tsv) # Retrieve vnet id.
az dns-resolver vnet-link create -n ${prefix}spoke2 -g $prefix --ruleset-name $prefix --id $vnetspoke2id # link dns resolver to spoke vnet
~~~

List all A-Records of zone "cptddnsr.org":

~~~ bash
az network private-dns record-set list -g $prefix -z ${prefix}.org --query '[?type==`Microsoft.Network/privateDnsZones/A`].{aRecords:aRecords[0].ipv4Address,fqdn:fqdn}' -o table
~~~

Result:

~~~ json
ARecords    Fqdn
----------  ----------------------------
10.3.0.4    cptddnsrspoke1.cptddnsr.org.
10.4.0.4    cptddnsrspoke2.cptddnsr.org.
10.4.1.4    vm000000.cptddnsr.org.
10.4.1.5    vm000001.cptddnsr.org.
~~~

NOTE: vm000000, vm000001 belong to bastion.

### Test Inbound case

Send dns query from onprem VM

~~~ bash
vmopid=$(az vm show -g $rgop -n linux --query id -o tsv)
az network bastion ssh -n ${prefix}hub -g $prefix --target-resource-id $vmopid --auth-type password --username chpinoto # log into onprem vm
demo!pass123
# use the fqdn of our spoke vm, autogenerated by our private dns zone.
ip addr show | grep inet.*eth0
dig +noall +answer cptddnsrspoke1.cptddnsr.org. # expect 10.3.0.4
logout
~~~

Same result can be achieved via windows client:

~~~ powershell
vmwinid=$(az vm show -g $rgop -n client-01-win-vm --query id -o tsv)
az network bastion rdp -n ${prefix}hub -g $prefix --target-resource-id $vmwinid
nslookup cptddnsrspoke1.cptddnsr.org
~~~

### Test Outbound case

From spoke1 peered to hub:

~~~ bash
vmspoke1id=$(az vm show -g $prefix -n ${prefix}spoke1 --query id -o tsv)
az network bastion ssh -n ${prefix}hub -g $prefix --target-resource-id $vmspoke1id --auth-type password --username chpinoto
demo!pass123
ip addr show | grep eth0 # expect 10.3.0.4
dig +noall +answer client-01-win-v.myedge.org. # expect 10.1.0.5
dig +noall +answer dc-01-win-vm.myedge.org. # exptect 10.1.0.4
ping dc-01-win-vm.myedge.org
# trigger ms defender dns
dig 164e9408d12a701d91d206c6ab192994.info
dig micros0ft.com
dig all.mainnet.ethdisco.net
logout
~~~

From spoke2 not peered to hub:

~~~ bash
vmspoke2id=$(az vm show -g $prefix -n ${prefix}spoke2 --query id -o tsv)
az network bastion ssh -n ${prefix}spoke2 -g $prefix --target-resource-id $vmspoke2id --auth-type password --username chpinoto 
demo!pass123
ip addr show | grep eth0 # expect 10.4.0.4
dig +noall +answer client-01-win-v.myedge.org. # expect 10.1.0.5
dig +noall +answer dc-01-win-vm.myedge.org. # exptect 10.1.0.4
logout
~~~

### Clean up

~~~ bash
az network vnet peering delete -n hub2onprem -g $prefix --vnet-name ${prefix}hub
az network vnet peering delete -n onprem2hub -g $rgop --vnet-name $vnetop
az group delete -n $prefix -y
~~~

# Misc

## private DNS zone

~~~ bash
az network private-dns zone show -g $prefix -n ${prefix}.org
~~~

## private DNS resolver tips and tricks

~~~ bash
# Verify dns resolver state.
az dns-resolver show -n $prefix -g $prefix --query dnsResolverState 
nslookup dc-01-win-vm.myedge.org # look domain controller.
dnsinip=$(az dns-resolver inbound-endpoint show --dns-resolver-name $prefix -n $prefix -g $prefix --query ipConfigurations[].privateIpAddress -o tsv) # get inbount ip
az dns-resolver outbound-endpoint show --dns-resolver-name $prefix -n $prefix -g $prefix --query ipConfigurations[].privateIpAddress -o tsv  # get outbound details
~~~

## general usefull cli commands

~~~ bash
az resource list -g $prefix -o table # list all azure resource inside a resource group.
az network vnet peering list -g $prefix --vnet-name $prefix --query [].name
az network vnet peering list --vnet-name file-rg-vnet -g file-rg --query [].name
az network vnet peering delete -n hub-appproxy --vnet-name file-rg-vnet -g file-rg
~~~

## gh, git tips and tricks

~~~ bash
gh repo create $prefix --public
git remote add origin https://github.com/cpinotossi/$prefix.git
git status
git add *
git commit -m"add disconnnected spoke demo"
git push origin main 
~~~