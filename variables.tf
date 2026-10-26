variable "runner_namespace" {
  description = "Name of the Kubernetes namespace for the runner."
  type        = string
  nullable    = false
  default     = "humanitec-runner"
}
variable "runner_serviceaccount" {
  description = "Name of the Kubernetes service account for the runner."
  type        = string
  nullable    = false
  default     = "humanitec-runner"
}
variable "runner_serviceaccount_annotations" {
  description = "Annotations to add to the runner Kubernetes service account."
  type        = map(string)
  nullable    = false
  default     = {}
}
variable "runner_role" {
  description = "Name of the Kubernetes role for the runner"
  type        = string
  nullable    = false
  default     = "humanitec-runner"
}
variable "support_kubernetes_tf_backend" {
  description = "Whether to support a `kubernetes` OpenTofu/Terraform backend for the runner. Setting this to `true` adds extended permissions to the role for the runner service account. If not required, leave it at `false` to maintain least privilege."
  type        = bool
  nullable    = false
  default     = false
}
variable "is_separate_runner_cluster" {
  description = "Whether the target cluster is a separate runner cluster, i.e. not on the same cluster as an Operator. Setting this to `true` results in an additional role created and bound to the runner service account for managing Kubernetes Jobs and related resources."
  type        = bool
  nullable    = false
  default     = false
}
variable "separate_runner_cluster_subjects" {
  description = "Subjects to bind to the additional role created if `is_separate_runner_cluster` is `true`. These are the identities accessing the separate runner cluster, which depend on the technology used for that kind of access. Required to contain at least one subject if `is_separate_runner_cluster` is `true`."
  type = list(object({
    kind      = string
    name      = string
    api_group = optional(string)
    namespace = optional(string)
  }))
  nullable = false
  default  = []

  validation {
    condition     = !var.is_separate_runner_cluster || length(var.separate_runner_cluster_subjects) > 0
    error_message = "separate_runner_cluster_subjects must contain at least one subject if is_separate_runner_cluster is true."
  }
}
variable "gke_project_id" {
  description = "ID of the Google Cloud project hosting the GKE cluster of the runner. The cluster must have Workload Identity Federation for GKE enabled. If not set, the project of the `google` provider that is passed in to the module is used. The module reads the project to obtain its number for the `runner_principal` output."
  type        = string
  nullable    = true
  default     = null

  validation {
    condition     = var.gke_project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.gke_project_id))
    error_message = "gke_project_id must be a Google Cloud project ID of 6 to 30 lowercase letters, digits, or hyphens, starting with a letter and not ending with a hyphen."
  }
}
