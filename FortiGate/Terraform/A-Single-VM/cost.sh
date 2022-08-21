#!/bin/bash
echo "
##############################################################################################################
#
# FortiGate Active/Active Load Balanced pair of standalone FortiGate VMs for resilience and scale
# Terraform deployment template for Microsoft Azure
#
##############################################################################################################
"

# Stop running when command returns error
set -e

##############################################################################################################
# FortiGate variables
#
# FortiGate License type PAYG or BYOL
# Default = PAYG
# FGT_IMAGE_SKU PAYG/ONDEMAND = fortinet_fg-vm_payg_2022
# FGT_IMAGE_SKU BYOL = fortinet_fg-vm
#
# FortiGate version
# Default = latest
#
##############################################################################################################
#export TF_VAR_FGT_IMAGE_SKU=""
#export TF_VAR_FGT_VERSION=""
#export TF_VAR_FGT_BYOL_LICENSE_FILE_A=""
#export TF_VAR_FGT_BYOL_LICENSE_FILE_B=""

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
export TF_VAR_LOCATION="$location"
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
export TF_VAR_PREFIX="$prefix"
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
    if [ -z "$username" ]
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
    read password         # read the password
    stty $stty_orig     # restore terminal setting.
    echo ""
else
    password="$DEPLOY_PASSWORD"
    echo ""
    echo "--> Using password found in env variable DEPLOY_PASSWORD ..."
    echo ""
fi

infracost breakdown --path terraform --show-skipped \
                --terraform-plan-flags "-var USERNAME=$username -var PASSWORD=$password"

