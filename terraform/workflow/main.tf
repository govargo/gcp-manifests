data "google_project" "project" {
}

module "dataform_workflow_sa" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.3.0"
  project_id = data.google_project.project.project_id

  names        = ["workflow-dataform"]
  display_name = "Cloud Workflows for Dataform ServiceAccount"
  project_roles = [
    "${data.google_project.project.project_id}=>roles/dataform.editor",
  ]
}

module "gke_node_scaler_workflow_sa" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.3.0"
  project_id = data.google_project.project.project_id

  names        = ["workflow-gke-node-scaler"]
  display_name = "Cloud Workflows for GKE NodePool Scaler ServiceAccount"
  project_roles = [
    "${data.google_project.project.project_id}=>roles/container.clusterAdmin",
    "${data.google_project.project.project_id}=>roles/container.developer",
  ]
}

module "workflow_scheduler_sa" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.3.0"
  project_id = data.google_project.project.project_id

  names        = ["workflow-scheduler"]
  display_name = "Cloud Schedulers trigger for Cloud Workflows ServiceAccount"
  project_roles = [
    "${data.google_project.project.project_id}=>roles/cloudscheduler.jobRunner",
    "${data.google_project.project.project_id}=>roles/workflows.invoker",
  ]
}

resource "google_workflows_workflow" "daily_dataform_workflow" {
  project = data.google_project.project.project_id
  name    = "${var.env}-little-quest-daily-dataform"
  region  = var.region

  description = "Daily Dataform intermediate/output workflow"
  labels = {
    "role"      = "dataform_workflow",
    "frequency" = "daily"
  }

  service_account = module.dataform_workflow_sa.email
  source_contents = templatefile("${path.module}/files/daily_dataform.yaml", {
    projectId = data.google_project.project.project_id
    region    = var.region
  })

  depends_on = [module.dataform_workflow_sa]
}

resource "google_workflows_workflow" "scale_down_gke_workloads_workflow" {
  project = data.google_project.project.project_id
  name    = "${var.env}-little-quest-scaledown-gke-workloads"
  region  = var.region

  description = "little-quest GKE workloads scale down workflow"
  labels = {
    "role"      = "gke_scaledown_workflow",
    "frequency" = "daily"
  }

  service_account = module.gke_node_scaler_workflow_sa.email
  source_contents = templatefile("${path.module}/files/gke_scaledown.yaml", {
    projectId = data.google_project.project.project_id
    region    = var.region
  })

  depends_on = [module.gke_node_scaler_workflow_sa]
}

resource "google_workflows_workflow" "scale_up_gke_workloads_workflow" {
  project = data.google_project.project.project_id
  name    = "${var.env}-little-quest-scaleup-gke-workloads"
  region  = var.region

  description = "little-quest GKE workloads scale up workflow"
  labels = {
    "role"      = "gke_scaleup_workflow",
    "frequency" = "daily"
  }

  service_account = module.gke_node_scaler_workflow_sa.email
  source_contents = templatefile("${path.module}/files/gke_scaleup.yaml", {
    projectId = data.google_project.project.project_id
    region    = var.region
  })

  depends_on = [module.gke_node_scaler_workflow_sa]
}

resource "google_cloud_scheduler_job" "dataform_workflow_job" {
  project = data.google_project.project.project_id
  name    = "${var.env}-little-quest-dataform-workflow-scheduler"
  region  = var.region

  description      = "Trigger Little Quest Dataform Workflow Scheduler"
  schedule         = "0 0 * * *"
  time_zone        = "Asia/Tokyo"
  attempt_deadline = "360s"

  retry_config {
    retry_count          = 1
    max_backoff_duration = "3600s"
    max_doublings        = 5
    max_retry_duration   = "0s"
    min_backoff_duration = "5s"
  }

  http_target {
    http_method = "POST"
    headers = {
      "Content-Type" = "application/json"
    }
    uri = "https://workflowexecutions.googleapis.com/v1/projects/${data.google_project.project.project_id}/locations/${var.region}/workflows/${google_workflows_workflow.daily_dataform_workflow.name}/executions"

    oauth_token {
      scope                 = "https://www.googleapis.com/auth/cloud-platform"
      service_account_email = module.workflow_scheduler_sa.email
    }
  }

  depends_on = [module.workflow_scheduler_sa, google_workflows_workflow.daily_dataform_workflow]
}

resource "google_cloud_scheduler_job" "gke_scaledown_workflow_job" {
  project = data.google_project.project.project_id
  name    = "${var.env}-little-quest-scaledown-gke-workloads-workflow-scheduler"
  region  = var.region

  description      = "Trigger Little Quest GKE Workflows Scale Down Workflow Scheduler"
  schedule         = "0 19 * * MON-FRI"
  time_zone        = "Asia/Tokyo"
  attempt_deadline = "360s"

  retry_config {
    retry_count          = 1
    max_backoff_duration = "3600s"
    max_doublings        = 5
    max_retry_duration   = "0s"
    min_backoff_duration = "5s"
  }

  http_target {
    http_method = "POST"
    headers = {
      "Content-Type" = "application/json"
    }
    uri = "https://workflowexecutions.googleapis.com/v1/projects/${data.google_project.project.project_id}/locations/${var.region}/workflows/${google_workflows_workflow.scale_down_gke_workloads_workflow.name}/executions"

    oauth_token {
      scope                 = "https://www.googleapis.com/auth/cloud-platform"
      service_account_email = module.workflow_scheduler_sa.email
    }
  }

  depends_on = [module.workflow_scheduler_sa, google_workflows_workflow.scale_down_gke_workloads_workflow]
}

resource "google_cloud_scheduler_job" "gke_scaleup_workflow_job" {
  project = data.google_project.project.project_id
  name    = "${var.env}-little-quest-scaleup-gke-workloads-workflow-scheduler"
  region  = var.region

  description      = "Trigger Little Quest GKE Workflows Scale Up Workflow Scheduler"
  schedule         = "30 8 * * MON-FRI"
  time_zone        = "Asia/Tokyo"
  attempt_deadline = "360s"

  retry_config {
    retry_count          = 1
    max_backoff_duration = "3600s"
    max_doublings        = 5
    max_retry_duration   = "0s"
    min_backoff_duration = "5s"
  }

  http_target {
    http_method = "POST"
    headers = {
      "Content-Type" = "application/json"
    }
    uri = "https://workflowexecutions.googleapis.com/v1/projects/${data.google_project.project.project_id}/locations/${var.region}/workflows/${google_workflows_workflow.scale_up_gke_workloads_workflow.name}/executions"

    oauth_token {
      scope                 = "https://www.googleapis.com/auth/cloud-platform"
      service_account_email = module.workflow_scheduler_sa.email
    }
  }

  depends_on = [module.workflow_scheduler_sa, google_workflows_workflow.scale_up_gke_workloads_workflow]
}
