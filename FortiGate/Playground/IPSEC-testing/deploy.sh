#!/bin/bash
echo "
################################################################################
#
# Fortinet VPN IPSEC testing
#
# Deploy a VPN IPSEC testing setup using 2x FortiGate and 2x LNX systems in 2
# separate VNET's
#
# To get started you need provide the Azure Service Principal Access if you are
# not usig Azure Cloud Shell. If you want the provision the FortiGate systems
# automatically with a license file you need to add the licenses into the
# licenses directory and add the filename in the environment variable
# TF_VAR_FGT_LICENSE_FILE_A and TF_VAR_FGT_LICENSE_FILE_B.
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
# export TF_VAR_FGT_LICENSE_FILE_A="../licenses/FGVM04xxx.lic"
# export TF_VAR_FGT_LICENSE_FILE_A="../licenses/FGVM04yyy.lic"
#
##############################################################################################################
#export TF_VAR_FGT_LICENSE_FILE_A=""
#export TF_VAR_FGT_LICENSE_FILE_B=""
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

# Generate SSH key
#echo ""
#echo "==> Generate and verify SSH key location and permissions"
#echo ""
#SSH_PRIVATE_KEY_FILE="output/ssh_key"
#if [ ! -f output/ssh_key ]; then
#    ssh-keygen -q -t rsa -b 2048 -f "$SSH_PRIVATE_KEY_FILE" -C "" -N ""
#fi
#SSH_PUBLIC_KEY_FILE="output/ssh_key.pub"
#chmod 700 `dirname $SSH_PUBLIC_KEY_FILE`
#chmod 600 $SSH_PUBLIC_KEY_FILE
#FGT_SSH_PUBLIC_KEY_FILE="../$SSH_PUBLIC_KEY_FILE"
#FGT_SSH_PRIVATE_KEY_FILE="../$SSH_PRIVATE_KEY_FILE"

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
                -var "USERNAME=" \
                -var "PASSWORD=$PASSWORD"
#                -var "FGT_SSH_PUBLIC_KEY_FILE=$FGT_SSH_PUBLIC_KEY_FILE"

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
# Fortinet VPN IPSEC testing
#
# The FortiGate systems are reachable on their public IP on port HTTPS/443 and
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