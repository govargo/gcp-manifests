data "google_project" "project" {
}

resource "google_compute_security_policy" "owasp_top10_policy" {
  name    = "${var.env}-owasp10-policy"
  project = data.google_project.project.project_id

  type        = "CLOUD_ARMOR"
  description = "Security Policy for OWASP Top 10 risks"

  rule {
    action      = "deny(403)"
    description = "OWASP TOP10 Risk (1)"
    preview     = false
    priority    = 1100

    match {
      expr {
        expression = <<-EOT
                        evaluatePreconfiguredExpr("sqli-v33-stable")
                        || evaluatePreconfiguredExpr("xss-v33-stable")
                        || evaluatePreconfiguredExpr("lfi-v33-stable")
                        || evaluatePreconfiguredExpr("rfi-v33-stable")
                        || evaluatePreconfiguredExpr("rce-v33-stable")
        EOT
      }
    }
  }

  rule {
    action      = "deny(403)"
    description = "OWASP TOP10 Risk (2)"
    preview     = false
    priority    = 1200

    match {
      expr {
        expression = <<-EOT
                        evaluatePreconfiguredExpr("methodenforcement-v33-stable")
                        || evaluatePreconfiguredExpr("scannerdetection-v33-stable")
                        || evaluatePreconfiguredExpr("protocolattack-v33-stable")
                        || evaluatePreconfiguredExpr("php-v33-stable")
                        || evaluatePreconfiguredExpr("sessionfixation-v33-stable")
        EOT
      }
    }
  }

  # Default
  rule {
    action      = "allow"
    description = "default rule"
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

