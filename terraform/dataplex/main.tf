data "google_project" "project" {
}

## DataCatalog
resource "google_data_catalog_tag_template" "resource_usage_info" {
  project = data.google_project.project.project_id

  tag_template_id = "resource_usage_info"
  region          = var.region
  display_name    = "Resource Usage Info"

  fields {
    field_id     = "last_queried_person"
    display_name = "Last queried person"
    description  = "Laste queried person in BigQuery"
    type {
      primitive_type = "STRING"
    }
    is_required = false
    order       = 1
  }

  fields {
    field_id     = "queries_counts"
    display_name = "Queries count"
    description  = "Query count in BigQuery"
    type {
      primitive_type = "DOUBLE"
    }
    is_required = false
    order       = 2
  }

  fields {
    field_id     = "last_queried_at"
    display_name = "Last queried timestamp"
    description  = "Last queried timestamp in BigQuery"
    type {
      primitive_type = "TIMESTAMP"
    }
    is_required = false
    order       = 3
  }

  force_delete = "false"
}

## Sample Data Profile for Dataplex
resource "google_dataplex_datascan" "little_quest_datamart_revenue_summary_profile" {
  project      = data.google_project.project.project_id
  location     = var.region
  data_scan_id = "datamart-revenues-summary"

  data {
    resource = "//bigquery.googleapis.com/projects/${data.google_project.project.project_id}/datasets/${var.env}_little_quest_datamart/tables/daily_revenues_summary"
  }

  execution_spec {
    trigger {
      on_demand {}
    }
  }

  data_profile_spec {
    sampling_percent = 10
  }
}
