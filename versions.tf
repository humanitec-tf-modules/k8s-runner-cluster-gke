terraform {
  required_version = ">= 1.11.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3"
    }
    google = {
      source  = "hashicorp/google"
      version = ">= 7.0.0, < 9.0.0"
    }
  }
}
