# Firestore
resource "google_firestore_database" "default" {
  project = data.google_project.project.project_id

  name                        = "(default)"
  location_id                 = var.region
  type                        = "FIRESTORE_NATIVE"
  concurrency_mode            = "OPTIMISTIC"
  app_engine_integration_mode = "DISABLED"
}

resource "google_firestore_field" "update_at_ttl" {
  project    = data.google_project.project.project_id
  database   = google_firestore_database.default.name
  collection = "messages"
  field      = "updateAt"

  # enables a TTL policy for the document based on the value of entries with this field
  ttl_config {}
}

resource "google_firebaserules_ruleset" "firestore" {
  project = data.google_project.project.project_id

  source {
    files {
      name    = "firestore.rules"
      content = <<EOF
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    function isValidCreated() {
      return
        request.resource.data.createdAt is timestamp &&
        request.resource.data.createdBy is string &&
        request.resource.data.createdBy.size() > 0 &&
        request.resource.data.updatedAt is timestamp &&
        request.resource.data.updatedBy.size() > 0
    }

    function isValidUpdated() {
      return
        request.resource.data.createdAt is timestamp &&
        request.resource.data.createdBy is string &&
        request.resource.data.createdBy.size() > 0 &&
        request.resource.data.updatedAt is timestamp &&
        request.resource.data.updatedBy.size() > 0
    }

    match /messages/{message=**} {
      allow read: if true
      allow create: if isValidCreated()
      allow update: if isValidUpdated()
    }
  }
}
EOF
    }
  }
}
