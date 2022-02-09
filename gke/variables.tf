variable "gcp_project_id" {
  description = "GCP project id"
  type        = string
}

variable "gcp_project_name" {
  description = "GCP project name"
  type        = string
}

variable "subnetwork" {
  description = "Subnetwork"
  type        = string
}

variable "region" {
  description = "Region"
  type        = string
  default     = "asia-northeast1"
}

variable "location" {
  description = "The location (region or zone) in which the cluster master will be created"
  type        = string
  default     = "asia-northeast1-a"
}

variable "node_locations" {
  description = "The list of zones in which the cluster's nodes are located"
  type        = list(string)
}

variable "default_max_pods_per_node" {
  description = "The default maximum number of pods per node in this cluster"
  type        = number
  default     = 32
}

variable "enable_binary_authorization" {
  description = "Enable Binary Authorization for this cluster"
  type        = bool
  default     = false
}

variable "enable_intranode_visibility" {
  description = "Whether Intra-node visibility is enabled for this cluster"
  type        = bool
  default     = false
}

variable "enable_kubernetes_alpha" {
  description = "enable_kubernetes_alpha"
  type        = bool
  default     = false
}

variable "enable_legacy_abac" {
  description = "Whether the ABAC authorizer is enabled for this cluster"
  type        = bool
  default     = false
}

variable "enable_shielded_nodes" {
  description = "Enable Shielded Nodes features on all nodes in this cluster"
  type        = bool
  default     = false
}

variable "enable_tpu" {
  description = "Whether to enable Cloud TPU resources in this cluster"
  type        = bool
  default     = false
}

variable "initial_node_count" {
  description = ""
  type        = number
  default     = 1
}

variable "networking_mode" {
  description = "Determines whether alias IPs or routes will be used for pod IPs in the cluster"
  type        = string
  default     = "VPC_NATIVE"
}

variable "cluster_secondary_range_name" {
  description = "The name of the existing secondary range in the cluster's subnetwork to use for pod"
  type        = string
  default     = "pod"
}

variable "services_secondary_range_name" {
  description = "The name of the existing secondary range in the cluster's subnetwork to use for service"
  type        = string
  default     = "service"
}

variable "logging_service" {
  description = "The logging service that the cluster should write logs to"
  type        = string
  default     = "logging.googleapis.com/kubernetes"
}

variable "monitoring_service" {
  description = "The monitoring service that the cluster should write metrics to"
  type        = string
  default     = "monitoring.googleapis.com/kubernetes"
}

variable "node_provisioning" {
  description = "Whether node auto-provisioning is enabled"
  type        = bool
  default     = false

}

variable "disabled_http_load_balancing" {
  description = "Addon http_load_balancing disabled"
  type        = bool
  default     = false
}

variable "disabled_horizontal_pod_autoscaling" {
  description = "Addon horizontal_pod_autoscaling disabled"
  type        = bool
  default     = false
}

variable "autoscaling_profile" {
  description = "Autoscaling Profile"
  type        = string
  default     = "BALANCED"
}

variable "remove_default_node_pool" {
  description = "If true, deletes the default node pool upon cluster creation"
  type        = bool
  default     = true
}

variable "network_policy" {
  description = "Network Policy"
  type        = bool
  default     = false
}

variable "disk_size_gb" {
  description = "Size of the disk attached to each node"
  type        = number
  default     = 10
}

variable "disk_type" {
  description = "Type of the disk attached to each node"
  type        = string
  default     = "pd-standard"
}

variable "image_type" {
  description = "The image type to use for this node"
  type        = string
  default     = "ubuntu_containerd"
}

variable "machine_type" {
  description = "The name of a Google Compute Engine machine type"
  type        = string
  default     = "n1-standard-2"
}

variable "min_cpu_platform" {
  description = "Minimum CPU platform to be used by this instance"
  type        = string
  default     = "Intel Skylake"
}

variable "oauth_scopes" {
  description = "The set of Google API scopes to be made available on all of the node VMs"
  type        = list(string)
  default     = ["https://www.googleapis.com/auth/cloud-platform"]
}

variable "preemptible" {
  description = "A boolean that represents whether or not the underlying node VMs are preemptible"
  type        = bool
  default     = false
}

variable "metadata_mode" {
  description = "How to expose the node metadata to the workload running on the node"
  type        = string
  default     = "GKE_METADATA"
}

variable "notification_config" {
  description = "Upgrade notification config"
  type        = bool
  default     = false
}

variable "pod_security_policy_config" {
  description = "Pod Security Policy config"
  type        = bool
  default     = false
}

variable "channel" {
  description = "Configuration options for the Release channel"
  type        = string
  default     = "STABLE"
}

variable "enable_integrity_monitoring" {
  description = "Defines if the instance has integrity monitoring enabled"
  type        = bool
  default     = false
}

variable "enable_secure_boot" {
  description = "Defines if the instance has Secure Boot enabled"
  type        = bool
  default     = false
}

variable "node_count" {
  description = "Node pool count"
  type        = number
  default     = 1
}

variable "max_surge" {
  description = "Max surge of nodepool upgrade"
  type        = number
  default     = 1
}

variable "max_unavailable" {
  description = "Max unavailable of nodepool upgrade"
  type        = number
  default     = 0
}
