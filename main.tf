terraform {
  required_version = ">= 0.12"
}

#
# Configure the MongoDB Atlas Provider
#
provider "mongodbatlas" {
  public_key = var.atlas_public_key
  private_key = var.atlas_private_key
}

resource "mongodbatlas_project" "tf_test" {
  name   = "TF-Testing"
  org_id = var.atlas_org_id
}

# Network peering container is a general term used to describe any cloud providers' VPC/VNet 
# concept. Containers only need to be created if the peering connection to the cloud provider will 
# be created before the first cluster that requires the container. If the cluster has been/will be 
# created first Atlas automatically creates the required container per the "containers per cloud 
# provider" information that follows (in this case you can obtain the container id from the 
# cluster resource attribute container_id).
#
# See https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/network_container for more info
resource "mongodbatlas_network_container" "tf_test_container" {
  project_id       = mongodbatlas_project.tf_test.id
  atlas_cidr_block = "10.8.0.0/21"
  provider_name    = "AZURE"
  region           = var.atlas_region
}

# Ensure you have first created a network container if it is required for your configuration. 
# See the network_container resource documentation to determine if you need a network container 
# first.
#
# See https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/network_peering
resource "mongodbatlas_network_peering" "tf_test_peering" {
  project_id            = mongodbatlas_project.tf_test.id
  container_id          = mongodbatlas_network_container.tf_test_container.container_id
  provider_name         = "AZURE"
  atlas_cidr_block      = "10.8.0.0/21"
  azure_directory_id    = var.azure_directory_id
  azure_subscription_id = var.azure_subscription_id
  resource_group_name   = var.azure_resource_group_name
  vnet_name             = var.azure_vnet_name
}

# You must whitelist the private CIDR block of your Azure VNET that is peered to Atlas
# See https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/project_ip_whitelist
resource "mongodbatlas_project_ip_whitelist" "azure_privateip" {
  project_id = mongodbatlas_project.tf_test.id
  cidr_block = var.azure_cidr_block
  comment    = "Azure VNET CIDR Block"
  depends_on = [ "mongodbatlas_network_peering.tf_test_peering" ]
}

# Add in public IP access to Atlas
# See https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/project_ip_whitelist
resource "mongodbatlas_project_ip_whitelist" "public_ip_access" {
  project_id = mongodbatlas_project.tf_test.id
  ip_address = var.public_ip_address
  comment = "My IP Address"
}

# Creating a database user
# See https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/database_user
resource "mongodbatlas_database_user" "text_user" {
  username = "test-acc-username"
  password = "test-acc-password"
  project_id = mongodbatlas_project.tf_test.id
  auth_database_name = "admin"

  roles {
    role_name = "atlasAdmin"
    database_name = "admin"
  } 
}

# Create cluster
# See https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/cluster
resource "mongodbatlas_cluster" "cluster" {
  name                  	= "AzureCluster"
  project_id            	= mongodbatlas_project.tf_test.id
  auto_scaling_disk_gb_enabled	= true
  mongo_db_major_version 	= "4.4"
  cluster_type   		= "REPLICASET"

  provider_name         	= "AZURE"
  provider_instance_size_name   = "M10"
  provider_backup_enabled 	= true

  depends_on = [ "mongodbatlas_network_peering.tf_test_peering" ]

  replication_specs {
    num_shards	    		= 1
    regions_config {
      region_name     		= var.atlas_region
      priority            = 7
      electable_nodes 		= 3
    }
  }
}
