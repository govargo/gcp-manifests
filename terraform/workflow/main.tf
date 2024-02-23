data "google_project" "project" {
}

module "dataform_workflow_sa" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.1.1"
  project_id = data.google_project.project.project_id

  names        = ["workflow-dataform"]
  display_name = "Cloud Workflows for Dataform ServiceAccount"
  project_roles = [
    "${data.google_project.project.project_id}=>roles/dataform.editor",
  ]
}

module "workflow_scheduler_sa" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.1.1"
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

  depends_on = [module.workflow_scheduler_sa]
}
