# Mock all providers so the tests run without access to Google Cloud or a Kubernetes cluster
mock_provider "kubernetes" {}
mock_provider "google" {
  # Default project of the provider, used if gke_project_id is not set
  mock_data "google_client_config" {
    defaults = {
      project = "provider-project"
    }
  }
  mock_data "google_project" {
    defaults = {
      number = "123456789012"
    }
  }
}

# Default case

run "defaults" {
  command = apply

  # Project
  assert {
    condition     = data.google_project.gke.project_id == "provider-project"
    error_message = "Project should default to the project of the google provider"
  }
  assert {
    condition     = output.runner_principal == "principal://iam.googleapis.com/projects/123456789012/locations/global/workloadIdentityPools/provider-project.svc.id.goog/subject/ns/humanitec-runner/sa/humanitec-runner"
    error_message = "Runner principal output should identify the default runner service account, got ${output.runner_principal}"
  }

  # Outputs
  assert {
    condition = (
      output.runner_namespace == "humanitec-runner" &&
      output.runner_serviceaccount_name == "humanitec-runner" &&
      output.runner_role_name == "humanitec-runner" &&
      output.runner_rolebinding_name == "humanitec-runner"
    )
    error_message = "Kubernetes namespace, service account, role and rolebinding outputs should use the default names"
  }
  assert {
    condition = (
      output.separate_runner_cluster_role_name == null &&
      output.separate_runner_cluster_rolebinding_name == null &&
      output.separate_runner_cluster_rolebinding_subjects == null
    )
    error_message = "Separate runner cluster role, rolebinding and subjects outputs should be null by default"
  }
  assert {
    condition     = length(module.k8s_runner_cluster.runner_serviceaccount_annotations) == 0
    error_message = "Runner service account should have no annotations by default"
  }
  assert {
    condition     = output.gke_project_id == "provider-project" && output.gke_project_number == "123456789012"
    error_message = "Project ID and number outputs should be those of the google provider project"
  }
  assert {
    condition     = output.workload_identity_pool == "provider-project.svc.id.goog"
    error_message = "Workload Identity pool output should be <project-id>.svc.id.goog, got ${output.workload_identity_pool}"
  }
}

# Complete case

run "complete" {
  command = apply

  variables {
    runner_namespace                  = "platform-runner"
    runner_serviceaccount             = "runner-sa"
    runner_serviceaccount_annotations = { "example.com/team" = "platform" }
    runner_role                       = "runner-role"
    support_kubernetes_tf_backend     = true
    is_separate_runner_cluster        = true
    separate_runner_cluster_subjects = [
      {
        kind      = "ServiceAccount"
        name      = "my-serviceaccount"
        namespace = "my-namespace"
      },
      {
        kind      = "Group"
        name      = "my-group"
        api_group = "rbac.authorization.k8s.io"
      },
      {
        kind = "User"
        name = "my-user"
      },
    ]
    gke_project_id = "my-gke-project"
  }

  # Project
  assert {
    condition     = data.google_project.gke.project_id == "my-gke-project"
    error_message = "Project should be read by gke_project_id"
  }

  # Outputs
  assert {
    condition = (
      output.runner_namespace == "platform-runner" &&
      output.runner_serviceaccount_name == "runner-sa" &&
      output.runner_role_name == "runner-role" &&
      output.runner_rolebinding_name == "runner-role"
    )
    error_message = "Kubernetes namespace, service account, role and rolebinding outputs should use the custom names"
  }
  assert {
    condition     = output.separate_runner_cluster_role_name == "runner-role-separate-cluster" && output.separate_runner_cluster_rolebinding_name == "runner-role-separate-cluster"
    error_message = "Separate runner cluster role and rolebinding should be created if is_separate_runner_cluster is true"
  }
  assert {
    condition = [for s in output.separate_runner_cluster_rolebinding_subjects : { kind = s.kind, name = s.name }] == [
      { kind = "ServiceAccount", name = "my-serviceaccount" },
      { kind = "Group", name = "my-group" },
      { kind = "User", name = "my-user" },
    ]
    error_message = "Separate runner cluster rolebinding should bind exactly the separate_runner_cluster_subjects, in order"
  }
  assert {
    condition     = output.separate_runner_cluster_rolebinding_subjects[0].namespace == "my-namespace"
    error_message = "Separate runner cluster rolebinding should pass on the namespace of a subject"
  }
  assert {
    condition     = output.separate_runner_cluster_rolebinding_subjects[1].api_group == "rbac.authorization.k8s.io"
    error_message = "Separate runner cluster rolebinding should pass on the api_group of a subject"
  }
  assert {
    condition     = module.k8s_runner_cluster.runner_serviceaccount_annotations == tomap({ "example.com/team" = "platform" })
    error_message = "Runner service account should use runner_serviceaccount_annotations"
  }
  assert {
    condition     = output.gke_project_id == "my-gke-project" && output.gke_project_number == "123456789012"
    error_message = "Project ID and number outputs should be those of gke_project_id"
  }
  assert {
    condition     = output.workload_identity_pool == "my-gke-project.svc.id.goog"
    error_message = "Workload Identity pool output should use gke_project_id, got ${output.workload_identity_pool}"
  }
  assert {
    condition     = output.runner_principal == "principal://iam.googleapis.com/projects/123456789012/locations/global/workloadIdentityPools/my-gke-project.svc.id.goog/subject/ns/platform-runner/sa/runner-sa"
    error_message = "Runner principal output should use gke_project_id and the custom namespace and service account, got ${output.runner_principal}"
  }
}

# Validation failures

run "requires_project_without_provider_default" {
  command = plan

  override_data {
    target = data.google_client_config.current
    values = {
      project = ""
    }
  }

  expect_failures = [data.google_project.gke]
}

run "separate_runner_cluster_requires_subjects" {
  command = plan

  variables {
    is_separate_runner_cluster = true
  }

  expect_failures = [var.separate_runner_cluster_subjects]
}

run "rejects_invalid_gke_project_id" {
  command = plan

  variables {
    gke_project_id = "My_Project"
  }

  expect_failures = [var.gke_project_id]
}

run "rejects_too_short_gke_project_id" {
  command = plan

  variables {
    gke_project_id = "abc"
  }

  expect_failures = [var.gke_project_id]
}

run "rejects_gke_project_id_ending_with_hyphen" {
  command = plan

  variables {
    gke_project_id = "my-project-"
  }

  expect_failures = [var.gke_project_id]
}
