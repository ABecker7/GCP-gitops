terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    flux = {
      source  = "fluxcd/flux"
      version = "~> 1.2"
    }
  }
}
provider "google" {
  project     = var.project_id
  region      = var.region
  credentials = file("~/gitops-480517-3e50440109d1.json")
}

data "google_client_config" "default" {}

provider "kubernetes" {
  load_config_file = false
  host             = "https://${google_container_cluster.primary.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
  #exec {
  #  api_version = "client.authentication.k8s.io/v1beta1"
  #  command     = "gke-cloud-auth-plugin"
  #  args = [
  #    "get-token",
  #    "--cluster", google_container_cluster.primary.name,
  #    "--location", google_container_cluster.primary.location,
  #  ]
  #}
}

provider "helm" {
  kubernetes {
    host                   = "https://${google_container_cluster.primary.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
  }
}


provider "flux" {
  
  kubernetes = {
    host                   = "https://${google_container_cluster.primary.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
  }
  #  kubernetes = {
  #    host                   = "https://${google_container_cluster.primary.endpoint}"
  #    cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
  #    exec = {
  #      api_version = "client.authentication.k8s.io/v1beta1"
  #      command     = "gke-gcloud-auth-plugin"
  #      args = [
  #        "get-token",
  #        "--cluster", google_container_cluster.primary.name,
  #        "--location", google_container_cluster.primary.location,
  #      ]
  #    }
  #  }
  git = {
    url = "https://github.com/${var.github_owner}/${var.repository_name}.git"
    http = {
      username = "git"
      password = var.github_token
    }
  }
}

