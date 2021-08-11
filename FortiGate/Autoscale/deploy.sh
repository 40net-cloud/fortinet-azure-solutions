#!/bin/bash
echo "
##############################################################################################################
#
# Deployment of a FortiGate Autoscale cluster
#
##############################################################################################################

"

# Stop on error
set +e

RELEASE_VERSION="2.0.5"

DOWNLOAD_LINK="https://github.com/fortinet/fortigate-autoscale/releases/download/$RELEASE_VERSION/fortigate-autoscale-azure-template-deployment.zip"
DOWNLOAD_DIRECTORY="download"
DOWNLOAD_FILENAME="$RELEASE_VERSION.zip"
DEPLOY_PACKAGE_URL="https://github.com/fortinet/fortigate-autoscale/releases/download/$RELEASE_VERSION/fortigate-autoscale-azure-funcapp.zip"

if [ -f "$DOWNLOAD_DIRECTORY/$DOWNLOAD_FILENAME" ] || [ -d "$DOWNLOAD_DIRECTORY/$RELEASE_VERSION" ]
then
	echo "--> Cleanup previous deployment..."
	echo ""
	rm -rf "$DOWNLOAD_DIRECTORY/$RELEASE_VERSION/" "$DOWNLOAD_DIRECTORY/$DOWNLOAD_FILENAME"
fi

echo ""
echo "--> Download FortiGate Autoscale package from github ..."
echo ""
wget –quiet -O "$DOWNLOAD_DIRECTORY/$DOWNLOAD_FILENAME" $DOWNLOAD_LINK
if [ -f "$DOWNLOAD_DIRECTORY/$DOWNLOAD_FILENAME" ]
then
    echo "--> Preparing and extracting package ..."
    echo ""
    mkdir -p "$DOWNLOAD_DIRECTORY/$RELEASE_VERSION"
    unzip -d "$DOWNLOAD_DIRECTORY/$RELEASE_VERSION" $DOWNLOAD_DIRECTORY/$DOWNLOAD_FILENAME
else
    echo "--> Download of Autoscale deployment package failed from [$DOWNLOAD_LINK] ..."
    exit 1
fi

templatefilename="$DOWNLOAD_DIRECTORY/$RELEASE_VERSION/templates/deploy_fortigate_autoscale.hybrid_licensing.json"
if [ "2.0.5" == "$RELEASE_VERSION" ]
then
	echo ""
	echo "--> Patching deployment template with additional variables ..."
	echo ""
	patch $templatefilename << EOF
1920a1921,1924
>                             "name": "FUNCTIONS_WORKER_RUNTIME",
>                             "value": "node"
>                         },
>                         {
1993c1997
<                             "name": "WEBSITE_RUN_FROM_ZIP",
---
>                             "name": "WEBSITE_RUN_FROM_PACKAGE",
EOF
	echo ""
fi

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
echo "--> Deployment in '$location' location ..."
echo ""

if [ -z "$DEPLOY_INSTANCETYPE" ]
then
    instancetype="Standard_F4s"
else
    instancetype="$DEPLOY_INSTANCETYPE"
fi
echo ""
echo "--> Deployment with instance type '$instancetype' ..."
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
rg="$prefix-RG"
prefix=`echo "$prefix" | tr '[:upper:]' '[:lower:]'`
echo "--> Using prefix '$prefix' for all resources ..."
echo ""

if [ -z "$DEPLOY_PASSWORD" ]
then
    # Input password
    echo -n "Enter FGT VM password: "
    stty_orig=`stty -g` # save original terminal setting.
    stty -echo          # turn-off echoing.
    read passwd         # read the password
    stty $stty_orig     # restore terminal setting.
else
    passwd="$DEPLOY_PASSWORD"
    echo "--> Using password found in env variable DEPLOY_PASSWORD ..."
    echo ""
fi

if [ -z "$DEPLOY_USERNAME" ]
then
    username="azureadmin"
else
    username="$DEPLOY_USERNAME"
fi
echo "--> Using username '$username' ..."
echo ""

if [ -z "$DEPLOY_CLIENT_ID" ]
then
    # Input Service Principal Client ID
    echo -n "Enter client id: "
    stty_orig=`stty -g` # save original terminal setting.
    read clientid         # read the prefix
    stty $stty_orig     # restore terminal setting.
else
    clientid="$DEPLOY_CLIENT_ID"
fi
echo "--> Using Client ID '$clientid' for all resources ..."
echo ""

if [ -z "$DEPLOY_CLIENT_SECRET" ]
then
    # Input Service Principal Client ID
    echo -n "Enter client secret: "
    stty_orig=`stty -g` # save original terminal setting.
    read clientsecret         # read the prefix
    stty $stty_orig     # restore terminal setting.
else
    clientsecret="$DEPLOY_CLIENT_SECRET"
fi
echo "--> Using client secret '$clientsecret' for all resources ..."
echo ""

if [ -z "$DEPLOY_PACKAGE_URL" ]
then
    # Input Service Principal Client ID
    echo -n "Enter deployment package url: "
    stty_orig=`stty -g` # save original terminal setting.
    read packageurl         # read the prefix
    stty $stty_orig     # restore terminal setting.
else
    packageurl="$DEPLOY_PACKAGE_URL"
fi
echo "--> Using package url '$packageurl' for all resources ..."
echo ""

# Create resource group
echo ""
echo "--> Creating $rg resource group ..."
az group create --location "$location" --name "$rg"

# Template validation
echo "--> Validation deployment in $rg resource group ..."
az deployment group validate --resource-group "$rg" \
                           --template-file $templatefilename \
                           --parameters ResourceNamePrefix="$prefix" RestAppID="$clientid" RestAppSecret="$clientsecret" \
					FortiGatePSKSecret="$passwd" AdminUsername="$username" AdminPassword=$passwd \
					PackageResURL="$packageurl" InstanceType="$instancetype"
result=$?
if [ $result != 0 ];
then
    echo "--> Validation failed ..."
    exit $result;
fi

deployment_name="$rg-$location"
# Template deployment
echo "--> Deployment of $rg resources with deployment name [$deployment_name]..."
az deployment group create --resource-group "$rg" \
                           --template-file $templatefilename \
                           --name "$deployment_name" \
                           --parameters ResourceNamePrefix="$prefix" RestAppID="$clientid" RestAppSecret="$clientsecret" \
					FortiGatePSKSecret="$passwd" AdminUsername="$username" AdminPassword=$passwd \
					PackageResURL="$packageurl" InstanceType="$instancetype"
result=$?
if [ $result != 0 ]
then
    echo "--> Deployment failed ..."
    exit $result;
else
    echo "--> Add local baseconfig to github baseconfig ..."
    if [ -f "configset/baseconfig" ]
    then
        cat "configset/baseconfig" >> "$RELEASE_VERSION/assets/configset/baseconfig"
    fi

    echo "--> Copy configset to Azure Storage Account ..."
    storageAccountName=`az deployment group show --resource-group "$rg" --name "$rg-$location" \
                            --query 'properties.outputs.storageAccountName.value' -o tsv`
    storageAccountAccessKey=`az deployment group show --resource-group "$rg" --name "$rg-$location" \
                            --query 'properties.outputs.storageAccountAccessKey.value' -o tsv`
    echo "--> Azure Storage Account found [$storageAccountName] ..."
    az storage blob upload-batch --account-name "$storageAccountName" --account-key "$storageAccountAccessKey" -s "$DOWNLOAD_DIRECTORY/$RELEASE_VERSION/assets/configset" -d "configset"

    if [ -d "licenses" ]
    then
        echo "--> Copy licenses to Azure Storage Account ..."
        az storage blob upload-batch -s "licenses" -d "fgt-asg-license" --account-name "$storageAccountName" --account-key "$storageAccountAccessKey"
    else
        echo "--> No license directory found in the current working directory. Copy the license files to a new directory 'fgt-asc-license' on the storage account [$storageAccountName] ..."
    fi

    echo "--> Starting BYOL Virtual Machine Scale Set ..."
    deploymentName=`az deployment group show --resource-group $rg --name "$rg-$location" \
                            --query 'properties.outputs.byolAutoscaleSettingsName.value' -o tsv`
    az monitor autoscale update --enabled true --resource-group $rg --name $deploymentName

    echo "
##############################################################################################################
 FortiGate Autoscaling cluster on Microsoft Azure

Thank you for the deployment of the Azure Azure Autoscaling cluster of FortiGate NGFWs. You can now create
loadbalancing rules for your services.

The FortiGate instances can be accesss on the public IP on port 40030 and above using HTTPS and 50030 for SSH
"
 IP Public Azure Load Balancer:"
publicIpIds=$(az network lb show -g "$rg" -n "$prefix-ExternalLoadBalancer" --query "frontendIpConfigurations[].publicIpAddress.id" --out tsv)
while read publicIpId; do
    az network public-ip show --ids "$publicIpId" --query "{ ipAddress: ipAddress, fqdn: dnsSettings.fqdn }" --out tsv
done <<< "$publicIpIds"
echo "
echo "
##############################################################################################################
"
fi

exit 0
