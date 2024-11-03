output "k8s_cluster_id" {
  description = "ID of the created Kubernetes cluster"
  value       = linode_lke_cluster.k8s_cluster.id
}

output "traefik_helm_release" {
  description = "Details of the Traefik Helm release"
  value = {
    name       = helm_release.traefik.name
    namespace  = helm_release.traefik.namespace
    version    = helm_release.traefik.version
    chart      = helm_release.traefik.chart
  }
}

output "kubevela_helm_release" {
  description = "Details of the KubeVela Helm release"
  value = {
    name       = helm_release.kubevela.name
    namespace  = helm_release.kubevela.namespace
    version    = helm_release.kubevela.version
    chart      = helm_release.kubevela.chart
  }
}


output "api_endpoints" {
  value = linode_lke_cluster.k8s_cluster.api_endpoints
}

output "status" {
  value = linode_lke_cluster.k8s_cluster.status
}

output "id" {
  value = linode_lke_cluster.k8s_cluster.id
}

output "pool" {
  value = linode_lke_cluster.k8s_cluster.pool
}