#!/bin/bash
echo "
##############################################################################################################
#  _                         
# |_) _  __ __ _  _     _| _ 
# |_)(_| |  | (_|(_ |_|(_|(_|
#
# Local deployment bootstrap
#
##############################################################################################################
"

while getopts "bg" option; do
    case "${option}" in
        b) DEPLOYMENTCOLOR="blue" ;;
        g) DEPLOYMENTCOLOR="green" ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

DEPLOYMENTVARFILE="var-$DEPLOYMENTCOLOR.env"

# Terraform state file in Azure Storage
BACKEND_ARM_ACCESS_KEY=''

# Passwords
CCSECRET=''
DB_PASSWORD=''
PASSWORD=''
SSH_KEY_DATA=''

# Azure Credentials
AZURE_CLIENT_ID=''
AZURE_CLIENT_SECRET=''
AZURE_SUBSCRIPTION_ID=''
AZURE_TENANT_ID=''

docker run --rm -itv $PWD/../vsts-cudalab-blue-green:/data \
                    -v terraform-run:/.terraform/ \
                    -v ~/.ssh:/ssh/ \
                    --env-file $DEPLOYMENTVARFILE \
                    jvhoof/cloudgen-essentials \
                    /bin/bash -c "cd /data; ./destroy.sh -b '$BACKEND_ARM_ACCESS_KEY' -d '$DB_PASSWORD' -v '$AZURE_CLIENT_ID' -w '$AZURE_CLIENT_SECRET' -x '$AZURE_SUBSCRIPTION_ID' -y '$AZURE_TENANT_ID' -z '$DEPLOYMENTCOLOR'"
