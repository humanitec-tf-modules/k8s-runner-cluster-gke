output "runner_namespace" {
  description = "Name of the Kubernetes namespace for the runner."
  value       = module.k8s_runner_cluster.runner_namespace
}
output "runner_serviceaccount_name" {
  description = "Name of the Kubernetes service account for the runner."
  value       = module.k8s_runner_cluster.runner_serviceaccount_name
}
output "runner_role_name" {
  description = "Name of the Kubernetes role for the runner."
  value       = module.k8s_runner_cluster.runner_role_name
}
output "runner_rolebinding_name" {
  description = "Name of the Kubernetes rolebinding for the runner."
  value       = module.k8s_runner_cluster.runner_rolebinding_name
}
output "separate_runner_cluster_role_name" {
  description = "Name of the Kubernetes role created if `is_separate_runner_cluster` is `true`. Returns `null` otherwise."
  value       = module.k8s_runner_cluster.separate_runner_cluster_role_name
}
output "separate_runner_cluster_rolebinding_name" {
  description = "Name of the Kubernetes rolebinding created if `is_separate_runner_cluster` is `true`. Returns `null` otherwise."
  value       = module.k8s_runner_cluster.separate_runner_cluster_rolebinding_name
}
output "separate_runner_cluster_rolebinding_subjects" {
  description = "Subjects of the Kubernetes rolebinding created if `is_separate_runner_cluster` is `true`, including any attributes filled in by the provider. Returns `null` otherwise."
  value       = module.k8s_runner_cluster.separate_runner_cluster_rolebinding_subjects
}
output "runner_principal" {
  value       = local.runner_principal
  description = "IAM principal identifier of the runner Kubernetes service account for Workload Identity Federation for GKE, like `principal://iam.googleapis.com/projects/<project-number>/locations/global/workloadIdentityPools/<project-id>.svc.id.goog/subject/ns/<namespace>/sa/<serviceaccount>`. Use it as the member to grant Google Cloud IAM roles to the runner."
}
output "workload_identity_pool" {
  value       = local.workload_identity_pool
  description = "Name of the Workload Identity pool of the GKE cluster project, like `<project-id>.svc.id.goog`."
}
output "gke_project_id" {
  value       = data.google_project.gke.project_id
  description = "ID of the Google Cloud project hosting the GKE cluster."
}
output "gke_project_number" {
  value       = data.google_project.gke.number
  description = "Number of the Google Cloud project hosting the GKE cluster."
}
