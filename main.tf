data "google_client_config" "current" {}

# Project hosting the GKE cluster. Read to obtain its number
data "google_project" "gke" {
  project_id = local.gke_project_id

  lifecycle {
    precondition {
      condition     = local.gke_project_id != null
      error_message = "gke_project_id must be set if the google provider has no default project."
    }
  }
}

locals {
  # Default to the project of the google provider
  gke_project_id = try(coalesce(var.gke_project_id, data.google_client_config.current.project), null)

  # GKE uses one Workload Identity pool per project, named after the project ID
  workload_identity_pool = "${data.google_project.gke.project_id}.svc.id.goog"

  # IAM principal identifier of the runner Kubernetes service account for Workload Identity Federation for GKE
  runner_principal = "principal://iam.googleapis.com/projects/${data.google_project.gke.number}/locations/global/workloadIdentityPools/${local.workload_identity_pool}/subject/ns/${module.k8s_runner_cluster.runner_namespace}/sa/${module.k8s_runner_cluster.runner_serviceaccount_name}"
}

# Provision the core Kubernetes setup using the generic module
module "k8s_runner_cluster" {
  # ❌❌ TODO: use tag once available
  source = "github.com/humanitec-tf-modules/k8s-runner-cluster?ref=add-runner-cluster"
  providers = {
    kubernetes = kubernetes
  }

  # Pass through all core variables
  runner_namespace                  = var.runner_namespace
  runner_serviceaccount             = var.runner_serviceaccount
  runner_serviceaccount_annotations = var.runner_serviceaccount_annotations
  runner_role                       = var.runner_role
  support_kubernetes_tf_backend     = var.support_kubernetes_tf_backend
  # Handling for separate runner cluster
  is_separate_runner_cluster       = var.is_separate_runner_cluster
  separate_runner_cluster_subjects = var.separate_runner_cluster_subjects
}
