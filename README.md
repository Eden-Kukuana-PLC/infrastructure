# Eden terraform infrastructure


Different infrastructure logic to easily spin up a cloud native application. See below for different implementation:

1. Linode LKE with Traefik and Kubevela

This infrastructure module creates a simple linode lke cluster, a Traefik proxy for internal routing and installs kubevela 
helm chart for modern application delivery. Example:

```terraform
    module "linode_lke_kubevela" {
      source                = "modules/linode-lke-traefik-kubevela"
      linode_token          = ""
      ghrc_email            = ""
      ghrc_password         = ""
      ghrc_username         = ""
      kubevela_core_version = "1.10.0-alpha.1"
      traefik_version       = "33.0.0"
      label                 = "uplanit-cluster"
      k8s_version           = "1.31"
      region                = "eu-central"
      pools = [
        {
          type : "g6-standard-1"
          count : 1
        }
      ]
    }

    # FOr backend config we use linode object storage
    # Example
    terraform {
      backend "s3" {
        bucket = "infrastructure"
        key    = "<app>/terraform/terraform.tfstate"
        region = "us-southeast-1"
        skip_credentials_validation = true
        access_key = ""
        secret_key = ""
        skip_region_validation = true
        skip_metadata_api_check = true
        skip_requesting_account_id = true
        force_path_style = true
        skip_s3_checksum = true
        endpoints = {
          s3 = ""
        }
      }
    }
```
