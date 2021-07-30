#!/bin/bash
echo "
##############################################################################################################
#
# Fortinet FortiGate ARM deployment template
# Active/Active loadbalanced pair of standalone FortiGates for resilience and scale
#
##############################################################################################################

"
#echo "--> Auto accepting terms for Azure Marketplace deployments ..."
#az vm image terms accept --publisher fortinet --offer fortinet_fortigate-vm_v5 --plan fortinet_fg-vm

# Stop on error
set +e

if [ -z "$DEPLOY_LOCATION" ]
then
    # Input location
    echo -n "Enter location (e.g. eastus2): "
    stty_orig=`stty -g` # save original terminal setting.
    read location         # read the location
    stty $stty_orig     # restore terminal setting.
    if [ -z "$location" ]
    then
        location="eastus2"
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
        prefix="FORTI"
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

if [ -z "$DEPLOY_USERNAME" ]
then
    username="azureuser"
else
    username="$DEPLOY_USERNAME"
fi
echo ""
echo "--> Using username '$username' ..."
echo ""

# Create resource group
echo ""
echo "--> Creating $rg resource group ..."
az group create --location "$location" --name "$rg"

# Validate template
echo "--> Validation deployment in $rg resource group ..."
#az deployment group validate --resource-group "$rg" \
#                           --template-file azuredeploy.json \
#                           --parameters adminUsername="$username" adminPassword=$passwd FortiGateNamePrefix=$prefix
#result=$?
#if [ $result != 0 ];
#then
#    echo "--> Validation failed ..."
#    exit $result;
#fi

# Deploy resources
echo "--> Deployment of $rg resources ..."
az deployment group create --resource-group "$rg" \
                           --template-file azuredeploy.json \
                           --parameters adminUsername="$username" adminPassword=$passwd FortiGateNamePrefix=$prefix
result=$?
if [[ $result != 0 ]];
then
    echo "--> Deployment failed ..."
    exit $result;
else
echo "
##############################################################################################################
#
# FortiGate Azure deployment using ARM Template
# Active/Active loadbalanced pair of standalone FortiGates for resilience and scale
#
# The FortiGate systems is reachable via the public IP addresses of the load balancers
# on HTTPS/443 and SSH/22.
#
##############################################################################################################

Deployment information:

Username:

FortiGate IP addesses
"
query="[?virtualMachine.name.starts_with(@, '$prefix')].{virtualMachine:virtualMachine.name, publicIP:virtualMachine.network.publicIpAddresses[0].ipAddress,privateIP:virtualMachine.network.privateIpAddresses[0]}"
az vm list-ip-addresses --query "$query" --output tsv
echo "

##############################################################################################################
"
fi

exit 0
