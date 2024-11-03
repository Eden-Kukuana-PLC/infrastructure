# This just shows an example of how to use this modules


# required to store remote state
# terraform {
#   backend "s3" {
#     bucket = "infrastructure"
#     key    = "uplanit/terraform/terraform.tfstate"
#     region = "us-southeast-1"
#     skip_credentials_validation = true
#     access_key = ""
#     secret_key = ""
#     skip_region_validation = true
#     skip_metadata_api_check = true
#     skip_requesting_account_id = true
#     force_path_style = true
#     skip_s3_checksum = true
#     endpoints = {
#       s3 = ""
#     }
#   }
# }


module "linode_lke_kubevela" {
  source = "./modules/linode-lke-traefik-kubevela"
  linode_token = ""
  ghrc_email = ""
  ghrc_password = ""
  ghrc_username = ""
  kubevela_core_version = ""
  traefik_version = "33.0.0"
  label = "uplanit-cluster"
  k8s_version = "1.31"
  region = "eu-central"
  pools = [
    {
      type : "g6-standard-3"
      count : 3
    }
  ]
}