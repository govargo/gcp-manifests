variable "gcp_project_name" {
  description = "Google Cloud project name"
  type        = string
}

variable "env" {
  description = "environment(e.g. dev, stg, prod)"
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

variable "zones" {
  description = "The zones to host the cluster in (optional if regional cluster / required if zonal)"
  type        = list(string)
}

variable "node_locations" {
  description = "The list of zones in which the cluster's nodes are located"
  type        = string
}

variable "default_max_pods_per_node" {
  description = "The default maximum number of pods per node in this cluster"
  type        = number
  default     = 32
}

variable "enable_binary_authorization" {
  description = "Enable BinAuthZ Admission controller"
  type        = bool
  default     = false
}

variable "enable_cost_allocation" {
  description = "Enables Cost Allocation Feature and the cluster name and namespace of your GKE workloads appear in the labels field of the billing export to BigQuery"
  type        = bool
  default     = true
}

variable "enable_network_egress_export" {
  description = "Whether to enable network egress metering for this cluster. If enabled, a daemonset will be created in the cluster to meter network egress traffic"
  type        = bool
  default     = false
}

variable "enable_resource_consumption_export" {
  description = "Whether to enable resource consumption metering on this cluster. When enabled, a table will be created in the resource export BigQuery dataset to store resource consumption data. The resulting table can be joined with the resource usage table or with BigQuery billing export"
  type        = bool
  default     = true
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

variable "dns_cache" {
  description = "The status of the NodeLocal DNSCache addon"
  type        = bool
  default     = false
}

variable "initial_node_count" {
  description = "The initial number of nodes for the pool. In regional or multi-zonal clusters, this is the number of nodes per zone. Changing this will force recreation of the resource. Defaults to the value of min_count"
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

variable "identity_namespace" {
  description = "The workload pool to attach all Kubernetes service accounts to. (Default value of enabled automatically sets project-based pool [project_id].svc.id.goog)"
  type        = string
  default     = "enabled"
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

variable "http_load_balancing" {
  description = "Enable httpload balancer addon"
  type        = bool
  default     = true
}

variable "horizontal_pod_autoscaling" {
  description = "Enable horizontal pod autoscaling addon"
  type        = bool
  default     = true
}

variable "enable_vertical_pod_autoscaling" {
  description = "Vertical Pod Autoscaling automatically adjusts the resources of pods controlled by it"
  type        = bool
  default     = true
}

variable "filestore_csi_driver" {
  description = "Enable Filestore CSI driver addon"
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

variable "gke_backup_agent_config" {
  description = "Whether Backup for GKE agent is enabled for this cluster"
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

variable "enable_gcfs" {
  description = "Google Container File System (gcfs) has to be enabled for image streaming to be active"
  type        = bool
  default     = false
}

variable "enable_gvnic" {
  description = "gVNIC (GVE) is an alternative to the virtIO-based ethernet driver"
  type        = bool
  default     = false
}

variable "machine_type" {
  description = "The name of a Google Compute Engine machine type"
  type        = string
  default     = "e2-standard-2"
}

variable "auto_repair" {
  description = "Whether the nodes will be automatically repaired"
  type        = bool
  default     = true
}

variable "auto_upgrade" {
  description = "Whether the nodes will be automatically upgraded"
  type        = bool
  default     = true
}

variable "autoscaling" {
  description = "Configuration required by cluster autoscaler to adjust the size of the node pool to the current cluster usage"
  type        = bool
  default     = true
}

variable "strategy" {
  description = "The upgrade stragey to be used for upgrading the nodes"
  type        = string
  default     = "SURGE"
}

variable "max_surge" {
  description = "The number of additional nodes that can be added to the node pool during an upgrade. Increasing max_surge raises the number of nodes that can be upgraded simultaneously"
  type        = number
  default     = 3
}

variable "max_unavailable" {
  description = "The number of nodes that can be simultaneously unavailable during an upgrade. Increasing max_unavailable raises the number of nodes that can be upgraded in parallel"
  type        = number
  default     = 0
}

variable "min_count" {
  description = "Minimum number of nodes in the NodePool. Must be >=0 and <= max_count. Should be used when autoscaling is true"
  type        = number
  default     = 0
}

variable "max_count" {
  description = "Maximum number of nodes in the NodePool. Must be >= min_count"
  type        = number
  default     = 100
}

variable "total_min_count" {
  description = "Total minimum number of nodes in the NodePool. Must be >=0 and <= total_max_node_count"
  type        = number
  default     = 0
}

variable "total_max_count" {
  description = "Total maximum number of nodes in the NodePool. Must be >= total_min_node_count"
  type        = number
  default     = 100
}

variable "location_policy" {
  description = "Location policy specifies the algorithm used when scaling-up the node pool"
  type        = string
  default     = "BALANCED"
}

variable "local_ssd_count" {
  description = "The amount of local SSD disks that will be attached to each cluster node and may be used as a hostpath volume or a local PersistentVolume."
  type        = number
  default     = 0
}

variable "spot" {
  description = "A boolean that represents whether the underlying node VMs are spot"
  type        = bool
  default     = true
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

variable "node_metadata" {
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

variable "release_channel" {
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
