# Azure private DNS resolver Samples

## Simple private DNS resolver inbound demo

Based on:
- https://docs.microsoft.com/en-us/azure/dns/dns-private-resolver-get-started-portal
- https://docs.microsoft.com/en-US/cli/azure/dns-resolver?view=azure-cli-latest

The following sample demonstrates how to create a private DNS resolver inbound rule.
![Overview](media/cptdpdnsr.001.png)

The sample includes:
- Azure Private DNS zone "cptddnsr.org" which use autoregistration 
- a VM called "VM" which does get auto-registered by the private DNS zone "cptddnsr.org"
- a VM called "ADDC" which runs Windows Server with DNS service enabled and conditional DNS configured to point to the private DNS resolver.
- a VM called "WIN10" which will be used to send a DNS query which will be finally resolved by the private DNS zone via the private DNS resolver.

The following sequence diagram does show how the DNS query does get resolved.

- VM: VM which does get autoregistered via Azure private DNS (10.3.1.4)
- ADDC: The VM which does run the DNS Service (10.1.0.4)
- WIN10: The VM which acts as a client (10.1.0.5)
- DNSRInbound: The Azure private DNS resolver inbound service (10.3.2.4)
- AzPrivateDNSZone: The Azure private DNS zone which will be used to autoregister  (cptddnsr.org.)

~~~ mermaid
sequenceDiagram
    participant WIN10
    participant ADDC
    participant DNSRInbound
    participant AzPrivateDNSZone
    WIN10->>ADDC: DNS query resolve cptddnsr.cptddnsr.org.
    Note right of ADDC: verify if conditional dns forward exists
    ADDC-->>DNSRInbound: fwd DNS query for cptddnsr.cptddnsr.org.
    DNSRInbound->>AzPrivateDNSZone: fwd DNS query for cptddnsr.cptddnsr.org.
    Note right of AzPrivateDNSZone: resolve to IP 10.3.1.4
    AzPrivateDNSZone->>DNSRInbound: fwd IP 10.3.1.4
    DNSRInbound->>ADDC: fwd IP 10.3.1.4
    ADDC->>WIN10: IP 10.3.1.4
~~~

The idea of the Azure private DNS resolver is to overcome the challenge with the none routable IP 168.63.129.16 which does provide DNS services inside a azure vNet. The issue is described [here](https://docs.microsoft.com/en-us/answers/questions/181776/azure-private-dns-zone-resolution-from-on-prem.html) in more details. To overcome the need to setup your own VMs which run a DNS Server (IaaS) Azure now offers a managed version (PaaS). Because our demo does not include a real on-prem enviroment we are going to mimic one by using two VNets which are connected via vnet peering with each other.

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

Env. variables which will be used during this demo.

~~~ bash
prefix=cptddnsr
location=eastus
myip=$(curl ifconfig.io) # Just in case we like to whitelist our own ip.
myobjectid=$(az ad user list --query '[?displayName==`ga`].id' -o tsv) # just in case we like to assing some RBAC roles to ourself.
~~~

Create foundation resources.

~~~ bash
az group create -n $prefix -l $location
az deployment group create -n $prefix -g $prefix --mode incremental --template-file bicep/deploy.bicep -p prefix=$prefix myobjectid=$myobjectid location=$location myip=$myip
~~~

Create the private DNS resolver.

~~~ bash
vnetid=$(az network vnet show -g $prefix -n $prefix --query id -o tsv) # Retrieve vnet id.
subnetinid=$(az network vnet subnet show -g $prefix -n dnsrin --vnet-name $prefix --query id -o tsv) # Retrieve subnet in id.
subnetoutid=$(az network vnet subnet show -g $prefix -n dnsrout --vnet-name $prefix --query id -o tsv) # Retrieve subnet out id.
az dns-resolver create -n $prefix -g $prefix -l $location --id $vnetid # create private dns resolver inside vnet.
az dns-resolver inbound-endpoint create --dns-resolver-name $prefix -n $prefix -g $prefix --ip-configuration private-ip-address="" private-ip-allocation-method=dynamic id=$subnetinid -l $location
dnsinip=$(az dns-resolver inbound-endpoint show --dns-resolver-name $prefix -n $prefix -g $prefix --query ipConfigurations[].privateIpAddress -o tsv)
~~~

As part of the foundation resources we created a private DNS zone.
Let us get all A-Records for this zone.

~~~ bash
az network private-dns zone show -g $prefix -n ${prefix}.org
az network private-dns record-set list -g $prefix -z ${prefix}.org --query '[?type==`Microsoft.Network/privateDnsZones/A`].{aRecords:aRecords,fqdn:fqdn}'
~~~

Result

~~~ json
[
  {
    "aRecords": [
      {
        "ipv4Address": "10.3.1.4"
      }
    ],
    "fqdn": "cptddnsr.cptddnsr.org."
  }
]
~~~

Resolve the A-Record from the WIN10 client VM.
Like mentioned at the beginning, some part of the resources are not covered by the templates of this repo.
The WIN10 client VM is such a resource:

![windows 10 client](media/cptdpdnsr.003.png)

In my case the WIN10 has the VM name "client-01-win-vm" and has been created under the resource group "file-rg".

~~~ bash
fqdn=$(az network private-dns record-set list -g $prefix -z ${prefix}.org --query '[?type==`Microsoft.Network/privateDnsZones/A`].{fqdn:fqdn}' -o tsv)
vmwin10=client-01-win-vm
rgwin10=file-rg
az vm run-command invoke --command-id RunPowerShellScript --name $vmwin10 -g $rgwin10 --scripts nslookup $fqdn #IMPORTANT: This command took ages to run and I finally did end up to use azure bastion to do the nslookup directly on the vm.
~~~

Outcome should be

~~~ bash
nslookup cptddnsr.cptddnsr.org
Server:  UnKnown
Address:  10.1.0.4

Non-authoritative answer:
Name:    cptddnsr.cptddnsr.org
Address:  10.3.1.4
~~~

- "Address:  10.3.1.4" IP of the VM called "VM".
- "Address:  10.1.0.4" Ip of the VM ADDC which does provide DNS to WIN10 and is setup with conditional DNS forwarding.

### Clean up

~~~ bash
az group delete -n $prefix -y
~~~


## Simple private DNS resolver outbound demo (work in progress)	

~~~ bash
az dns-resolver outbound-endpoint create --dns-resolver-name $prefix -n $prefix -g $prefix -l $location --id $subnetoutid
dnsoutip=$(az dns-resolver outbound-endpoint show --dns-resolver-name $prefix -n $prefix -g $prefix --query ipConfigurations[].privateIpAddress -o tsv) 
~~~


# Misc

## private DNS resolver tips and tricks

~~~ bash
# Verify dns resolver state.
az dns-resolver show -n $prefix -g $prefix --query dnsResolverState 
~~~

## general usefull cli commands

~~~ bash
az resource list -g $prefix -o table # list all azure resource inside a resource group.
~~~

## gh, git tips and tricks

~~~ bash
git init master
gh repo create $prefix --public
git remote add origin https://github.com/cpinotossi/$prefix.git
git status
git commit -m"initial commit"
git push origin master
~~~