# GKE Kubernetes runner cluster

This repository contains an OpenTofu/Terraform module to set up a Google Kubernetes Engine (GKE) cluster as a runner cluster for the [Container (builtin)](https://developer.humanitec.com/platform-orchestrator/docs/integration-and-extensions/drivers/container-builtin/) Driver and Drivers based on it such as the [Terraform and OpenTofu Container (builtin)](https://developer.humanitec.com/platform-orchestrator/docs/integration-and-extensions/drivers/terraform-and-opentofu-container-builtin/) Driver.

> [!NOTE]
> The module does not support the setup of the non-built-in Drivers, including the [Container Runner](https://developer.humanitec.com/platform-orchestrator/docs/integration-and-extensions/drivers/generic-drivers/container-runner/), [Terraform Runner](https://developer.humanitec.com/platform-orchestrator/docs/integration-and-extensions/drivers/generic-drivers/terraform-runner/), and [Terraform and OpenTofu Container Runner](https://developer.humanitec.com/platform-orchestrator/docs/integration-and-extensions/drivers/generic-drivers/terraform-and-opentofu-container-runner/) Drivers.

The module is based on [Workload Identity Federation for GKE](https://cloud.google.com/kubernetes-engine/docs/concepts/workload-identity) being enabled for the target GKE cluster. This is the recommended setup for your runners. If you are not using Workload Identity Federation for GKE, use the [generic runner cluster module](https://github.com/humanitec-tf-modules/k8s-runner-cluster) instead.

With Workload Identity Federation for GKE, the runner Kubernetes service account is an IAM principal by itself. The module therefore does not create any Google Cloud identity. Instead, it provides the IAM principal identifier of the runner service account in the `runner_principal` output so you can grant Google Cloud IAM roles to the runner directly.

## Usage

### Common usage: Runner cluster is also an Operator cluster

When the runner cluster is also an Operator cluster, you can use all defaults and provide just the essential properties. This configuration creates the Kubernetes namespace, roles, and service account for the runner.

```hcl
module "my_gke_runner_cluster" {
  source = "github.com/humanitec-tf-modules/k8s-runner-cluster-gke?ref=vX.Y.Z"
  providers = {
    google     = google
    kubernetes = kubernetes
  }

  gke_project_id = google_container_cluster.my_gke_cluster.project
}
```

If you omit `gke_project_id`, the module uses the project of the `google` provider.

### Assign roles to the runner identity

Use the `runner_principal` output of the present module to grant Google Cloud IAM roles to the runner identity.

```hcl
resource "google_project_iam_member" "runner_storage_admin" {
  project = "my-project"
  role    = "roles/storage.admin"
  member  = module.my_gke_runner_cluster.runner_principal
}
```

### Annotate the Kubernetes service account

```hcl
module "my_gke_runner_cluster" {
  source = "github.com/humanitec-tf-modules/k8s-runner-cluster-gke?ref=vX.Y.Z"
  providers = {
    google     = google
    kubernetes = kubernetes
  }

  gke_project_id = google_container_cluster.my_gke_cluster.project

  runner_serviceaccount_annotations = {
    "annotation1" = "value1"
    "annotation2" = "value2"
  }
}
```

### Set up a separate runner cluster

This configuration sets up the required permissions on the Kubernetes cluster to be a separate runner cluster.

```hcl
module "my_gke_runner_cluster" {
  source = "github.com/humanitec-tf-modules/k8s-runner-cluster-gke?ref=vX.Y.Z"
  providers = {
    google     = google
    kubernetes = kubernetes
  }

  gke_project_id = google_container_cluster.my_gke_cluster.project

  is_separate_runner_cluster = true
  separate_runner_cluster_subjects = [
    {
      kind      = "User"
      name      = "my-user@example.com"
      api_group = "rbac.authorization.k8s.io"
    },
  ]
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.0.0, < 8.0.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 3 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_k8s_runner_cluster"></a> [k8s\_runner\_cluster](#module\_k8s\_runner\_cluster) | github.com/humanitec-tf-modules/k8s-runner-cluster | add-runner-cluster |

## Resources

| Name | Type |
| ---- | ---- |
| [google_client_config.current](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config) | data source |
| [google_project.gke](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_gke_project_id"></a> [gke\_project\_id](#input\_gke\_project\_id) | ID of the Google Cloud project hosting the GKE cluster of the runner. The cluster must have Workload Identity Federation for GKE enabled. If not set, the project of the `google` provider that is passed in to the module is used. The module reads the project to obtain its number for the `runner_principal` output. | `string` | `null` | no |
| <a name="input_is_separate_runner_cluster"></a> [is\_separate\_runner\_cluster](#input\_is\_separate\_runner\_cluster) | Whether the target cluster is a separate runner cluster, i.e. not on the same cluster as an Operator. Setting this to `true` results in an additional role created and bound to the runner service account for managing Kubernetes Jobs and related resources. | `bool` | `false` | no |
| <a name="input_runner_namespace"></a> [runner\_namespace](#input\_runner\_namespace) | Name of the Kubernetes namespace for the runner. | `string` | `"humanitec-runner"` | no |
| <a name="input_runner_role"></a> [runner\_role](#input\_runner\_role) | Name of the Kubernetes role for the runner | `string` | `"humanitec-runner"` | no |
| <a name="input_runner_serviceaccount"></a> [runner\_serviceaccount](#input\_runner\_serviceaccount) | Name of the Kubernetes service account for the runner. | `string` | `"humanitec-runner"` | no |
| <a name="input_runner_serviceaccount_annotations"></a> [runner\_serviceaccount\_annotations](#input\_runner\_serviceaccount\_annotations) | Annotations to add to the runner Kubernetes service account. | `map(string)` | `{}` | no |
| <a name="input_separate_runner_cluster_subjects"></a> [separate\_runner\_cluster\_subjects](#input\_separate\_runner\_cluster\_subjects) | Subjects to bind to the additional role created if `is_separate_runner_cluster` is `true`. These are the identities accessing the separate runner cluster, which depend on the technology used for that kind of access. Required to contain at least one subject if `is_separate_runner_cluster` is `true`. | <pre>list(object({<br/>    kind      = string<br/>    name      = string<br/>    api_group = optional(string)<br/>    namespace = optional(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_support_kubernetes_tf_backend"></a> [support\_kubernetes\_tf\_backend](#input\_support\_kubernetes\_tf\_backend) | Whether to support a `kubernetes` OpenTofu/Terraform backend for the runner. Setting this to `true` adds extended permissions to the role for the runner service account. If not required, leave it at `false` to maintain least privilege. | `bool` | `false` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_gke_project_id"></a> [gke\_project\_id](#output\_gke\_project\_id) | ID of the Google Cloud project hosting the GKE cluster |
| <a name="output_gke_project_number"></a> [gke\_project\_number](#output\_gke\_project\_number) | Number of the Google Cloud project hosting the GKE cluster |
| <a name="output_runner_namespace"></a> [runner\_namespace](#output\_runner\_namespace) | Name of the Kubernetes namespace for the runner. |
| <a name="output_runner_principal"></a> [runner\_principal](#output\_runner\_principal) | IAM principal identifier of the runner Kubernetes service account for Workload Identity Federation for GKE, like `principal://iam.googleapis.com/projects/<project-number>/locations/global/workloadIdentityPools/<project-id>.svc.id.goog/subject/ns/<namespace>/sa/<serviceaccount>`. Use it as the member to grant Google Cloud IAM roles to the runner |
| <a name="output_runner_role_name"></a> [runner\_role\_name](#output\_runner\_role\_name) | Name of the Kubernetes role for the runner. |
| <a name="output_runner_rolebinding_name"></a> [runner\_rolebinding\_name](#output\_runner\_rolebinding\_name) | Name of the Kubernetes rolebinding for the runner. |
| <a name="output_runner_serviceaccount_name"></a> [runner\_serviceaccount\_name](#output\_runner\_serviceaccount\_name) | Name of the Kubernetes service account for the runner. |
| <a name="output_separate_runner_cluster_role_name"></a> [separate\_runner\_cluster\_role\_name](#output\_separate\_runner\_cluster\_role\_name) | Name of the Kubernetes role created if `is_separate_runner_cluster` is `true`. Returns `null` otherwise. |
| <a name="output_separate_runner_cluster_rolebinding_name"></a> [separate\_runner\_cluster\_rolebinding\_name](#output\_separate\_runner\_cluster\_rolebinding\_name) | Name of the Kubernetes rolebinding created if `is_separate_runner_cluster` is `true`. Returns `null` otherwise. |
| <a name="output_separate_runner_cluster_rolebinding_subjects"></a> [separate\_runner\_cluster\_rolebinding\_subjects](#output\_separate\_runner\_cluster\_rolebinding\_subjects) | Subjects of the Kubernetes rolebinding created if `is_separate_runner_cluster` is `true`, including any attributes filled in by the provider. Returns `null` otherwise. |
| <a name="output_workload_identity_pool"></a> [workload\_identity\_pool](#output\_workload\_identity\_pool) | Name of the Workload Identity pool of the GKE cluster project, like `<project-id>.svc.id.goog` |
<!-- END_TF_DOCS -->
