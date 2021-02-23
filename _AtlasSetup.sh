#!/bin/bash

# For more information, see https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/network_peering
# See Azure docs: https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-manage-peering#permissions
echo "Creating Service Principal for Atlas.."
az ad sp create --id e90a1407-55c3-432d-9cb1-3638900a9d22

echo "Creating role using peering-role.json file.."
az role definition create --role-definition peering-role.json

echo "Waiting 20 seconds for role propagation.."
sleep 20

# I noticed that the role propagation took some time to take effect; the below command may not work
echo "Assigning role to service principal created in first command.."
az role assignment create --role "AtlasPeering/<azure_subscription_id>/<resource_group_name>/" --assignee "e90a1407-55c3-432d-9cb1-3638900a9d22" --scope "/subscriptions/<azure_subscription_id>/resourceGroups/<resource_group_name>/providers/Microsoft.Network/virtualNetworks/<Azure_Vnet_Name>"

echo "Provisioning Atlas infrastructure through Terraform.."
#terraform init
#terraform apply -auto-approve


