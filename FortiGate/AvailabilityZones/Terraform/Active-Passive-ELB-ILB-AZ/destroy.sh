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
STATE="terraform.tfstate"

cd terraform/
echo ""
echo "==> Starting Terraform destroy"
echo ""

echo ""
echo "==> Terraform init"
echo ""
terraform init

echo ""
echo "==> terraform destroy"
echo ""
terraform destroy -auto-approve
if [[ $? != 0 ]];
then
    echo "--> ERROR: Destroy failed ..."
    rg=`grep -m 1 -o '"resource_group_name": "[^"]*' terraform.tfstate | grep -o '[^"]*$'`
    echo "--> Trying to delete the resource group $rg..."
    az group delete --resource-group "$rg"
    exit $rc;
fi
