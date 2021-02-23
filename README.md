# MongoDB Atlas on Azure Setup With Terraform

---
## Setup

__1. Install and Configure Azure CLI__

* Install the Azure CLI and run `az login` to ensure you are logged into the correct Azure subscription.  

__2. Configure Atlas Org__

* Ensure that you have created [an Atlas organization](https://docs.atlas.mongodb.com/tutorial/manage-organizations/) and created [an API key](https://docs.atlas.mongodb.com/configure-api-access/) with `Org Owner` and `Project Creator` access.
* Add an [API access list entry](https://docs.atlas.mongodb.com/configure-api-access/#add-an-api-access-list-entry)
* Record the private key value - it will not be shown again.

__3. Create necessary Azure permissions__

Necessary permissions need to be applied to the Azure environment in order to allow Atlas to discover the Azure VNet.

* Copy `_peering-role.json` to `peering-role.json` and add in the relevant values for your Azure subscription ID, Azure resouce group, and Azure VNet name.
* Copy `_AtlasSetup.sh` to `AtlasSetup.sh` and run the script.
* __Note__: I had difficulty with assigning the role to the service principal.  It seems that it takes some time for the role to correctly propagate in Azure?

__4. Modify Terraform files__

* Copy `_terraform.tfvars` to `terraform.tfvars` and fill in all of the fields.
* Modify `main.tf` to meet your needs (i.e. project name, cluster size, MongoDB version)
* Initialize Terraform with `terraform init`
* Run terraform with `terraform apply`.

__5. Log into Atlas to see your cluster__

* Go into Atlas and the project should be spun up, along with the peering connection.
* The cluster will take about 10 minutes to fully provision.