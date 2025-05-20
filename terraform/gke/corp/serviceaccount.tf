# little-quest-realtime
module "little_quest_realtime_sa" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.5.3"
  project_id = data.google_project.project.project_id

  names        = ["little-quest-realtime"]
  display_name = "Little Quest Realtime ServiceAccount"
  project_roles = [
    "${data.google_project.project.project_id}=>roles/cloudprofiler.agent",
  ]
}

module "little_quest_realtime_workloadIdentity_binding" {
  source  = "terraform-google-modules/iam/google//modules/service_accounts_iam"
  version = "8.1.0"
  project = data.google_project.project.project_id

  service_accounts = [module.little_quest_realtime_sa.email]
  mode             = "additive"
  bindings = {
    "roles/iam.workloadIdentityUser" = [
      "serviceAccount:${data.google_project.project.project_id}.svc.id.goog[corp-0/little-quest-realtime]"
    ]
  }
  depends_on = [module.little_quest_realtime_sa, kubernetes_service_account.corp0_little_quest_realtime]
}

# little-quest-frontend
module "little_quest_frontend_sa" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.5.3"
  project_id = data.google_project.project.project_id

  names        = ["little-quest-frontend"]
  display_name = "Little Quest Frontend ServiceAccount"
  project_roles = [
    "${data.google_project.project.project_id}=>roles/cloudprofiler.agent",
    "${data.google_project.project.project_id}=>roles/cloudtrace.agent",
  ]
}

module "little_quest_frontend_workloadIdentity_binding" {
  source  = "terraform-google-modules/iam/google//modules/service_accounts_iam"
  version = "8.1.0"
  project = data.google_project.project.project_id

  service_accounts = [module.little_quest_frontend_sa.email]
  mode             = "additive"
  bindings = {
    "roles/iam.workloadIdentityUser" = [
      "serviceAccount:${data.google_project.project.project_id}.svc.id.goog[corp-0/little-quest-frontend]"
    ]
  }
  depends_on = [module.little_quest_frontend_sa, kubernetes_service_account.corp0_little_quest_frontend]
}

# little-quest-mmf
module "little_quest_mmf_sa" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.5.3"
  project_id = data.google_project.project.project_id

  names        = ["little-quest-mmf"]
  display_name = "Little Quest Match Function ServiceAccount"
  project_roles = [
    "${data.google_project.project.project_id}=>roles/cloudprofiler.agent",
    "${data.google_project.project.project_id}=>roles/cloudtrace.agent",
  ]
}

module "little_quest_mmf_workloadIdentity_binding" {
  source  = "terraform-google-modules/iam/google//modules/service_accounts_iam"
  version = "8.1.0"
  project = data.google_project.project.project_id

  service_accounts = [module.little_quest_mmf_sa.email]
  mode             = "additive"
  bindings = {
    "roles/iam.workloadIdentityUser" = [
      "serviceAccount:${data.google_project.project.project_id}.svc.id.goog[corp-0/little-quest-mmf]"
    ]
  }
  depends_on = [module.little_quest_mmf_sa, kubernetes_service_account.corp0_little_quest_mmf]
}

# little-quest-director
module "little_quest_director_sa" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.5.3"
  project_id = data.google_project.project.project_id

  names        = ["little-quest-director"]
  display_name = "Little Quest Director ServiceAccount"
  project_roles = [
    "${data.google_project.project.project_id}=>roles/cloudprofiler.agent",
    "${data.google_project.project.project_id}=>roles/cloudtrace.agent",
  ]
}

module "little_quest_director_workloadIdentity_binding" {
  source  = "terraform-google-modules/iam/google//modules/service_accounts_iam"
  version = "8.1.0"
  project = data.google_project.project.project_id

  service_accounts = [module.little_quest_director_sa.email]
  mode             = "additive"
  bindings = {
    "roles/iam.workloadIdentityUser" = [
      "serviceAccount:${data.google_project.project.project_id}.svc.id.goog[corp-0/little-quest-director]"
    ]
  }
  depends_on = [module.little_quest_director_sa, kubernetes_service_account.corp0_little_quest_director]
}

# agones-allocator
module "agones_allocator_sa" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.5.3"
  project_id = data.google_project.project.project_id

  names         = ["agones-allocator"]
  display_name  = "Agones Allocator ServiceAccount"
  project_roles = ["${data.google_project.project.project_id}=>roles/monitoring.metricWriter"]
}

module "agones_allocator_workloadIdentity_binding" {
  source  = "terraform-google-modules/iam/google//modules/service_accounts_iam"
  version = "8.1.0"
  project = data.google_project.project.project_id

  service_accounts = [module.agones_allocator_sa.email]
  mode             = "additive"
  bindings = {
    "roles/iam.workloadIdentityUser" = [
      "serviceAccount:${data.google_project.project.project_id}.svc.id.goog[agones-system/agones-allocator]"
    ]
  }
  depends_on = [module.agones_allocator_sa, kubernetes_service_account.corp0_agones_allocator]
}

# agones-controller
module "agones_controller_sa" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.5.3"
  project_id = data.google_project.project.project_id

  names         = ["agones-controller"]
  display_name  = "Agones Controller ServiceAccount"
  project_roles = ["${data.google_project.project.project_id}=>roles/monitoring.metricWriter"]
}

module "agones_controller_workloadIdentity_binding" {
  source  = "terraform-google-modules/iam/google//modules/service_accounts_iam"
  version = "8.1.0"
  project = data.google_project.project.project_id

  service_accounts = [module.agones_controller_sa.email]
  mode             = "additive"
  bindings = {
    "roles/iam.workloadIdentityUser" = [
      "serviceAccount:${data.google_project.project.project_id}.svc.id.goog[agones-system/agones-controller]"
    ]
  }
  depends_on = [module.agones_controller_sa, kubernetes_service_account.corp0_agones_controller]
}

# open-match
module "openmatch_sa" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.5.3"
  project_id = data.google_project.project.project_id

  names        = ["open-match-service"]
  display_name = "Open Match ServiceAccount"
  project_roles = [
    "${data.google_project.project.project_id}=>roles/monitoring.metricWriter",
    "${data.google_project.project.project_id}=>roles/cloudtrace.agent",
  ]
}

module "openmatch_workloadIdentity_binding" {
  source  = "terraform-google-modules/iam/google//modules/service_accounts_iam"
  version = "8.1.0"
  project = data.google_project.project.project_id

  service_accounts = [module.openmatch_sa.email]
  mode             = "additive"
  bindings = {
    "roles/iam.workloadIdentityUser" = [
      "serviceAccount:${data.google_project.project.project_id}.svc.id.goog[open-match/open-match-service]"
    ]
  }
  depends_on = [module.openmatch_sa, kubernetes_service_account.corp0_open_match_service]
}

