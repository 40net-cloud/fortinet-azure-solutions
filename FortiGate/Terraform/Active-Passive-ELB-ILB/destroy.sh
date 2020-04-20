#!/bin/bash
echo "
##############################################################################################################
#
# FortiGate Active/Passive High Availability with Azure Standard Load Balancer - External and Internal
# Terraform deployment template for Microsoft Azure
#
# Remove the deployed environment based on state
#
##############################################################################################################
"

# Stop running when command returns error
set -e

PLAN="terraform.tfplan"

cd terraform/
echo ""
echo "==> Starting Terraform destroy"
echo ""

echo ""
echo "==> Terraform init"
echo ""
terraform init

echo ""
echo "==> Terraform plan -destroy"
echo ""
terraform plan -out "$PLAN" -destroy

echo ""
echo "==> Terraform destroy"
echo ""
terraform apply "$PLAN"
if [[ $? != 0 ]];
then
    echo "--> ERROR: Destory failed ..."
    rg=`grep -m 1 -o '"resource_group_name": "[^"]*' terraform.tfstate | grep -o '[^"]*$'`
    echo "--> Trying to delete the resource group $rg..."
    az group delete --resource_group "$rg"
    exit $rc;
fi