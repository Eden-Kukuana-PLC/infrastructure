terraform {
  required_providers {
    linode = {
      source  = "linode/linode"
      version = "2.30.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.0.3"  # check the latest version for compatibility
    }

    helm = {
      source  = "hashicorp/helm"
      version = "2.16.1"
    }

  }
}
//Use the Linode Provider
provider "linode" {
  token = var.linode_token
}

locals {
  pools = [
    {
      type : "g6-standard-1"
      count : 2
    }
  ]

  kubeconfig_string = base64decode(linode_lke_cluster.k8s_cluster.kubeconfig)
  kubeconfig = yamldecode(local.kubeconfig_string)

  api_endpoint = linode_lke_cluster.k8s_cluster.api_endpoints[0]
  api_token = local.kubeconfig.users[0].user.token
  ca_certificate = base64decode(local.kubeconfig.clusters[0].cluster["certificate-authority-data"])
}

//Use the linode_lke_cluster resource to create
//a Kubernetes cluster
resource "linode_lke_cluster" "k8s_cluster" {
  k8s_version = var.k8s_version
  label       = var.label
  region      = var.region
  tags        = var.tags

  dynamic "pool" {
    for_each = local.pools
    content {
      type  = pool.value["type"]
      count = pool.value["count"]
    }
  }
}

data "linode_lke_cluster" "k8s_cluster_data" {
  depends_on = [linode_lke_cluster.k8s_cluster]
  id = linode_lke_cluster.k8s_cluster.id
}


provider "helm" {
  kubernetes {
    host = local.api_endpoint
    token = local.api_token

    cluster_ca_certificate = local.ca_certificate
  }
}

provider "kubernetes" {
  host = local.api_endpoint
  token = local.api_token

  cluster_ca_certificate = local.ca_certificate
}

resource "null_resource" "add-ghrc-secrets-kubectl" {
  depends_on = [linode_lke_cluster.k8s_cluster]
  triggers = {
    cluster_id = linode_lke_cluster.k8s_cluster.id
  }
  provisioner "local-exec" {
    command = <<EOT
        echo "${local.kubeconfig_string}" > /tmp/kubeconfig-temp.yaml
        export KUBECONFIG=/tmp/kubeconfig-temp.yaml
        kubectl create secret docker-registry ghrc --docker-server=ghrc.io --docker-username=${var.ghrc_username} --docker-password=${var.ghrc_password} --docker-email=${var.ghrc_email}
      exit;
    EOT
  }
}

# This fails on the pipeline
# So we use the null resource above
# resource "kubernetes_secret" "github-container-registry" {
#   depends_on = [null_resource.apply_ingress_route_trait]
#   metadata {
#     name = "docker-cfg"
#   }
#
#   type = "kubernetes.io/dockerconfigjson"
#
#   data = {
#     ".dockerconfigjson" = jsonencode({
#       auths = {
#         "ghcr.io" = {
#           "username" = var.ghrc_username
#           "password" = var.ghrc_password
#           "email"    = var.ghrc_email
#           "auth"     = base64encode("${var.ghrc_username}:${var.ghrc_password}")
#         }
#       }
#     })
#   }
# }

resource "helm_release" "traefik" {
  depends_on = [linode_lke_cluster.k8s_cluster]
  name             = "traefik"
  repository       = "https://traefik.github.io/charts"
  chart            = "traefik"
  namespace        = "traefik"
  create_namespace = true
  version          = var.traefik_version

  values = [
    yamlencode({
      ports = {
        web = {
          http = {
            redirections = {
              entryPoint = {
                to       = "websecure"
                scheme   = "https"
                permanent = true
              }
            }
          }
        }
        websecure = {
          tls = {
            enabled      = true
            certResolver = "letsEncrypt"
          }
        }
      }

      ingressRoute = {
        dashboard = {
          enabled = true
        }
      }

      providers = {
        kubernetesCRD = {
          enabled = true
        }
      }

      persistence = {
        enabled = true
        size    = "128Mi"
        name    = "traefik"
        path    = "/data"
      }

      certificatesResolvers = {
        letsEncrypt = {
          acme = {
            tlschallenge = {}
            caServer     = "https://acme-v02.api.letsencrypt.org/directory"
            email        = "emmanuel@uplanit.xyz"
            storage      = "/data/acme.json"
            httpChallenge = {
              entryPoint = "web"
            }
          }
        }
      }

      deployment = {
        initContainers = [
          {
            name  = "volume-permissions"
            image = "busybox:1.31.1"
            command = ["sh", "-c", "chmod -Rv 777 /data/* && touch /data/acme.json && chmod -Rv 600 /data/* && chown 65532:65532 /data/acme.json"]
            securityContext = {
              runAsNonRoot = false
              runAsGroup   = 0
              runAsUser    = 0
            }
            volumeMounts = [
              {
                name      = "traefik"
                mountPath = "/data"
              }
            ]
          }
        ]
      }
    })
  ]
}


resource "helm_release" "kubevela" {
  depends_on = [helm_release.traefik]
  name             = "vela-core"
  repository       = "https://kubevela.github.io/charts"
  chart            = "vela-core"
  namespace        = "vela-system"
  create_namespace = true
  version          = var.kubevela_core_version
}



resource "null_resource" "add_kubevela_experimental_addon_registry" {
  depends_on = [helm_release.kubevela]
  triggers = {
    cluster_id = linode_lke_cluster.k8s_cluster.id
  }
  provisioner "local-exec" {
    command = <<EOT
      echo "${local.kubeconfig_string}" > /tmp/kubeconfig-temp.yaml
      export KUBECONFIG=/tmp/kubeconfig-temp.yaml
      vela addon registry add experimental --type=helm --endpoint=https://addons.kubevela.net/experimental/ --insecureSkipTLS;
      exit;
    EOT
  }
}

resource "null_resource" "enable_mongodb_operator" {
  depends_on = [helm_release.traefik, helm_release.kubevela, null_resource.add_kubevela_experimental_addon_registry]
  triggers = {
    cluster_id = linode_lke_cluster.k8s_cluster.id
  }
  provisioner "local-exec" {
    command = <<EOT
      echo "${local.kubeconfig_string}" > /tmp/kubeconfig-temp.yaml
      export KUBECONFIG=/tmp/kubeconfig-temp.yaml
      vela addon ls;
      vela addon enable mongodb-operator;
      exit;
    EOT
  }
}

resource "null_resource" "initialise_kubevela_environments" {
  depends_on = [null_resource.add_kubevela_experimental_addon_registry]
  triggers = {
    cluster_id = linode_lke_cluster.k8s_cluster.id
  }
  provisioner "local-exec" {
    command = <<EOT
      vela env init production --namespace production
      vela env init playground --namespace playground
      exit 0;
    EOT
  }
}

resource "null_resource" "apply_ingress_route_trait" {
  depends_on = [null_resource.initialise_kubevela_environments]
  triggers = {
    cluster_id = linode_lke_cluster.k8s_cluster.id
  }
  provisioner "local-exec" {
    command = <<EOT
      vela def apply ${path.module}/kubevela/traits/ingress-route.cue
      exit;
    EOT
  }
}
