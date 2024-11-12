#!/bin/bash
echo "
##############################################################################################################
#
# FortiManager VM
# Terraform deployment template for Microsoft Azure
#
##############################################################################################################
"

# Stop running when command returns error
set -e

##############################################################################################################
# FortiManager variables
#
# FortiManager version
# Default = latest
#
##############################################################################################################
#export TF_VAR_FMG_IMAGE_SKU=""
#export TF_VAR_FMG_VERSION=""
#export TF_VAR_FMG_BYOL_LICENSE_FILE=""

PLAN="terraform.tfplan"

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
export TF_VAR_location="$location"
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
export TF_VAR_prefix="$prefix"
echo ""
echo "--> Using prefix $prefix for all resources ..."
echo ""
rg_cgf="$prefix-RG"

if [ -z "$DEPLOY_USERNAME" ]
then
    # Input username
    echo -n "Enter username (default: azureuser): "
    stty_orig=`stty -g` # save original terminal setting.
    read username         # read the prefix
    stty $stty_orig     # restore terminal setting.
    if [ -z "$USERNAME" ]
    then
        username="azureuser"
    fi
else
    username="$DEPLOY_USERNAME"
fi
echo ""
echo "--> Using username '$username' ..."
echo ""

if [ -z "$DEPLOY_PASSWORD" ]
then
    # Input password
    echo -n "Enter password: "
    stty_orig=`stty -g` # save original terminal setting.
    stty -echo          # turn-off echoing.
    read passwd         # read the password
    stty $stty_orig     # restore terminal setting.
    echo ""
else
    passwd="$DEPLOY_PASSWORD"
    echo ""
    echo "--> Using password found in env variable DEPLOY_PASSWORD ..."
    echo ""
fi
password="$passwd"

if [ -z "$DEPLOY_SUBSCRIPTION_ID" ]
then
    detected_id=`az account show | jq ".id" -r`
    # Input username
    echo -n "Enter subscription ID (press enter for detected id: '$detected_id'): "
    stty_orig=`stty -g` # save original terminal setting.
    read subscription_id         # read the subscription id
    stty $stty_orig     # restore terminal setting.
    if [ -z "$subscription_id" ]
    then
        subscription_id="$detected_id"
    fi
else
    subscription_id="$DEPLOY_SUBSCRIPTION_ID"
fi
export TF_VAR_subscription_id="$subscription_id"
echo ""
echo "--> Using subscription id '$subscription_id' ..."
echo ""

SUMMARY="summary.out"

echo ""
echo "==> Starting Terraform deployment"
echo ""
cd terraform/

echo ""
echo "==> Terraform init"
echo ""
terraform init

echo ""
echo "==> Terraform plan"
echo ""
terraform plan --out "$PLAN" \
                -var "username=$username" \
                -var "password=$password"

echo ""
echo "==> Terraform apply"
echo ""
terraform apply "$PLAN"
if [[ $? != 0 ]];
then
    echo "--> ERROR: Deployment failed ..."
    exit $result;
fi

echo ""
echo "==> Terraform output deployment summary"
echo ""
terraform output deployment_summary > "../output/$SUMMARY"

cd ../
cat "output/$SUMMARY"
