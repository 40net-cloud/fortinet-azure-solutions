#!/bin/bash
echo "
##############################################################################################################
#
##############################################################################################################

"

if [ -z "$DEPLOY_LOCATION" ]
then
    # Input location
    echo -n "Enter location (e.g. eastus2): "
    stty_orig=`stty -g` # save original terminal setting.
    read location         # read the location
    stty $stty_orig     # restore terminal setting.
    if [ -z "$location" ]
    then
        location="westeurope"
    fi
else
    location="$DEPLOY_LOCATION"
fi
echo ""
echo "--> Deployment in $location location ..."
echo ""

if [ -z "$DEPLOY_PREFIX" ]
then
    # Input prefix
    echo -n "Enter prefix: "
    stty_orig=`stty -g` # save original terminal setting.
    read prefix         # read the prefix
    stty $stty_orig     # restore terminal setting.
    if [ -z "$prefix" ]
    then
        prefix="CUDA"
    fi
else
    prefix="$DEPLOY_PREFIX"
fi
echo ""
echo "--> Using prefix $prefix for all resources ..."
echo ""
rg="$prefix-RG"

if [ -z "$DEPLOY_PASSWORD" ]
then
    # Input password
    echo -n "Enter password: "
    stty_orig=`stty -g` # save original terminal setting.
    stty -echo          # turn-off echoing.
    read passwd         # read the password
    stty $stty_orig     # restore terminal setting.
else
    passwd="$DEPLOY_PASSWORD"
    echo ""
    echo "--> Using password found in env variable DEPLOY_PASSWORD ..."
    echo ""
fi

vnet="$prefix-VNET"
az network nic create --resource-group "$rg" --name "$prefix-VM01-NIC" --vnet-name "$vnet" --subnet "ProtectedSubnet"
az network nic create --resource-group "$rg" --name "$prefix-VM02-NIC" --vnet-name "$vnet" --subnet "ProtectedSubnet"
az network nic create --resource-group "$rg" --name "$prefix-VM03-NIC" --vnet-name "$vnet" --subnet "ProtectedSubnet"
az vm create --resource-group "$rg" --name "$prefix-VM01" --nics "$prefix-VM01-NIC" --image Canonical:0001-com-ubuntu-server-focal:20_04-lts:latest --admin-username azureuser --admin-password "$passwd" --output json
az vm create --resource-group "$rg" --name "$prefix-VM02" --nics "$prefix-VM02-NIC" --image Canonical:0001-com-ubuntu-server-focal:20_04-lts:latest --admin-username azureuser --admin-password "$passwd" --output json
az vm create --resource-group "$rg" --name "$prefix-VM03" --nics "$prefix-VM03-NIC" --image Canonical:0001-com-ubuntu-server-focal:20_04-lts:latest --admin-username azureuser --admin-password "$passwd" --output json

echo "
##############################################################################################################
#
##############################################################################################################
 IP Assignment:
"
query="[?virtualMachine.name.starts_with(@, '$prefix')].{virtualMachine:virtualMachine.name, publicIP:virtualMachine.network.publicIpAddresses[0].ipAddress,privateIP:virtualMachine.network.privateIpAddresses[0]}"
az vm list-ip-addresses --query "$query" --output tsv
echo "
##############################################################################################################
"
