variable "project_id" {
  description = "GCP Project ID where resources will be created"
  type        = string
  default     = "gitops-480517"
}

variable "region" {
  description = "GCP region for GKE cluster"
  type        = string
  default     = "us-central1"
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "secure-gke-cluster"
}

variable "network_name" {
  description = "Name of the VPC network"
  type        = string
  default     = "gke-network"
}

variable "subnet_name" {
  description = "Name of the subnet for GKE nodes"
  type        = string
  default     = "gke-subnet"
}

variable "master_ipv4_cidr_block" {
  description = "CIDR block for GKE master (control plane)"
  type        = string
  default     = "172.16.0.0/28"
}

variable "pods_ipv4_cidr_block" {
  description = "CIDR block for Kubernetes pods"
  type        = string
  default     = "10.4.0.0/14"
}

variable "services_ipv4_cidr_block" {
  description = "CIDR block for Kubernetes services"
  type        = string
  default     = "10.8.0.0/20"
}

variable "node_count" {
  description = "Number of nodes per zone in the node pool"
  type        = number
  default     = 1
}

variable "machine_type" {
  description = "GCE machine type for nodes"
  type        = string
  default     = "e2-medium"
}

variable "disk_size_gb" {
  description = "Disk size for each node in GB"
  type        = number
  default     = 100
}

variable "disk_type" {
  description = "Disk type for nodes"
  type        = string
  default     = "pd-standard"
}

variable "enable_private_nodes" {
  description = "Enable private endpoint for GKE master"
  type        = bool
  default     = true
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint for GKE master"
  type        = bool
  default     = false
}

variable "authorized_networks" {
  description = "CIDR blocks allowed to access GKE master"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = [
    {
      cidr_block   = "0.0.0.0/0"
      display_name = "All networks"
    }
  ]
}


variable "github_owner" {
  description = "Github username or organization"
  type        = string
}

variable "github_token" {
  description = "Github PAT"
  type        = string
  sensitive   = true
}

variable "repository_name" {
  description = "Name of the github repo"
  type        = string
}

variable "repository_visibility" {
  description = "Visibility of the github repo"
  type        = string
  default     = "public"
}

variable "branch" {
  description = "Branch to sync flux with"
  type        = string
  default     = "main"
}

variable "target_path" {
  description = "Path within the repo to sync cluster state"
  type        = string
  default     = "clusters/production"
}
