#!/bin/bash
echo "
################################################################################
#
# Fortinet testing
#
# Deploy a testing setup using a FortiGate and 2x LNX systems in 2
# separate SUBNET's
#
# To get started you need provide the Azure Service Principal Access if you are
# not usig Azure Cloud Shell. If you want the provision the FortiGate systems
# automatically with a license file you need to add the licenses into the
# licenses directory and add the filename in the environment variable
# TF_VAR_FGT_LICENSE_FILE.
#
################################################################################
"

# Stop running when command returns error
set -e

##############################################################################################################
# Azure Service Principal
##############################################################################################################
# AZURE_CLIENT_ID=''
# AZURE_CLIENT_SECRET=''
# AZURE_SUBSCRIPTION_ID=''
# AZURE_TENANT_ID=''
##############################################################################################################

##############################################################################################################
# LICENSE FILE Location
#
# Examples
# export TF_VAR_FGT_LICENSE_FILE="../licenses/FGVM04xxx.lic"
#
##############################################################################################################
#export TF_VAR_FGT_LICENSE_FILE=""
##############################################################################################################

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
PASSWORD="$passwd"
DB_PASSWORD="$passwd"

if [ -z "$DEPLOY_USERNAME" ]
then
    USERNAME="azureuser"
else
    USERNAME="$DEPLOY_USERNAME"
fi
echo ""
echo "--> Using username '' ..."
echo ""

SUMMARY="summary.out"

echo ""
echo "==> Starting Terraform deployment"
echo ""
cd terraform/

echo ""
echo "==> Terraform init"
echo ""
terraform -v
terraform init

echo ""
echo "==> Terraform plan"
echo ""
terraform plan --out "$PLAN" \
                -var "USERNAME=" \
                -var "PASSWORD=$PASSWORD"

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
echo "
################################################################################
#
# Fortinet FortiGate testing
#
# The FortiGate system is reachable on their public IP on port HTTPS/443 and
# SSH/22. The backend linux systems are reachable on their public IP on SSH/22
# to start the tests.
#
# BEWARE: The state files contain sensitive data like passwords and others.
#         After the demo clean up your clouddrive directory.
#
################################################################################

 Deployment information:

Username:
"
cat "output/$SUMMARY"
echo "

################################################################################
"
