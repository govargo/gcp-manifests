data "google_project" "project" {
}

resource "google_compute_security_policy" "little_quest_server_agent_restrict_policy" {
  name    = "${var.env}-little-quest-server-agent-restrict-policy"
  project = data.google_project.project.project_id

  type        = "CLOUD_ARMOR"
  description = "Security Policy for Little Quest Server with specific agent restrict"

  rule {
    action      = "allow"
    description = "Unity application can access to the backend"
    preview     = false
    priority    = 1000

    match {
      expr {
        expression = "request.headers['user-agent'].contains('UnityPlayer')"
      }
    }
  }

  ## Default Rule
  rule {
    action      = "deny(403)"
    description = "Default rule, higher priority overrides it"
    preview     = false
    priority    = 2147483647

    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
  }
}

resource "google_compute_security_policy" "argocd_restrict_policy" {
  name    = "${var.env}-argocd-agent-restrict-policy"
  project = data.google_project.project.project_id

  type        = "CLOUD_ARMOR"
  description = "Security Policy for ArgoCD with specific agent restrict"

  rule {
    action      = "allow"
    description = "Chrome can access to the backend"
    preview     = false
    priority    = 1000

    match {
      expr {
        expression = "request.headers['user-agent'].contains('Chrome')"
      }
    }
  }

  ## Default Rule
  rule {
    action      = "deny(403)"
    description = "Default rule, higher priority overrides it"
    preview     = false
    priority    = 2147483647

    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
  }
}
