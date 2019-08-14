#!/bin/bash
echo "
##############################################################################################################
#
# Deployment of a Fortigate Active / Passive cluster with External + Internal Load Balancer
#
##############################################################################################################

"

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
echo "--> Deployment in '$location' location ..."
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
echo "--> Using prefix '$prefix' for all resources ..."
echo ""
rg="$prefix-RG"

if [ -z "$DEPLOY_VPNSITEPREFIX" ]
then
    # Input prefix
    echo -n "Enter on-premise prefix: "
    stty_orig=`stty -g`                 # save original terminal setting.
    read vpnsiteprefix         # read the public ip
    stty $stty_orig                     # restore terminal setting.
    if [ -z "$vpnprefix" ]
    then
        vpnsiteprefix="ONPREM"
    fi
else
    vpnsiteprefix="$DEPLOY_VPNSITEPREFIX"
fi
echo ""
echo "--> Using on-premise prefix '$VPNSITEPREFIX' ..."
echo ""

if [ -z "$DEPLOY_PSK" ]
then
    # Input psk
    echo -n "Enter VPN pre shared key: "
    stty_orig=`stty -g` # save original terminal setting.
    stty -echo          # turn-off echoing.
    read psk            # read the pre shared key
    stty $stty_orig     # restore terminal setting.
else
    psk="$DEPLOY_PSK"
    echo ""
    echo "--> Using pre shared key found in env variable DEPLOY_PSK ..."
    echo ""
fi

if [ -z "$DEPLOY_VPNSITEPUBLICIPADDRESS" ]
then
    # Input prefix
    echo -n "Enter on-premise public ip for VPN tunnel: "
    stty_orig=`stty -g`                 # save original terminal setting.
    read vpnsitepublicipaddress         # read the public ip
    stty $stty_orig                     # restore terminal setting.
    if [ -z "$vpnsitepublicipaddress" ]
    then
        vpnsitepublicipaddress=""
    fi
else
    vpnsitepublicipaddress="$DEPLOY_VPNSITEPUBLICIPADDRESS"
fi
echo ""
echo "--> Using on-premise public ip '$vpnsitepublicipaddress' for all resources ..."
echo ""

# Create resource group
echo ""
echo "--> Creating $rg resource group ..."
az group create --location "$location" --name "$rg"

# Validate template
echo "--> Validation deployment in $rg resource group ..."
az group deployment validate --resource-group "$rg" \
                           --template-file azuredeploy.json \
                           --parameters prefix=$prefix vpnsitePrefix=$vpnsiteprefix sharedkey=$psk vpnsitePublicIPAddress=$vpnsitepublicipaddress
result=$?
if [ $result != 0 ];
then
    echo "--> Validation failed ..."
    exit $rc;
fi

# Deploy resources
echo "--> Deployment of $rg resources ..."
az group deployment create --resource-group "$rg" \
                           --template-file azuredeploy.json \
                           --parameters prefix=$prefix vpnsitePrefix=$vpnsiteprefix sharedkey=$psk vpnsitePublicIPAddress=$vpnsitepublicipaddress
result=$?
if [[ $result != 0 ]];
then
    echo "--> Deployment failed ..."
    exit $result;
else

# Display connection information
az extension show --name virtual-wan
result=$?
if [[ $result != 0 ]];
then
    echo "--> Installing Azure CLI extension for Virtual WAN ..."
    az extension install --name virtual-wan
    result=$?
    if [[ $result != 0 ]];
    then
        echo "--> Unable to add Azure CLI extension for Virtual WAN ..."
        exit $result;
    fi
    echo "
##############################################################################################################

#############################################################################################################
"
fi

exit 0
