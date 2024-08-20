data "google_project" "project" {
}

## BigQuery dataset
resource "google_bigquery_dataset" "billing_export" {
  project = data.google_project.project.project_id

  dataset_id            = "all_billing_data"
  friendly_name         = "cloud_billing_billing_export"
  description           = "Cloud Billing data export to BigQuery"
  location              = var.region
  storage_billing_model = "PHYSICAL"

  labels = {
    role = "billing"
  }
}

resource "google_bigquery_dataset" "billing_board" {
  project = data.google_project.project.project_id

  dataset_id    = "billing_board"
  friendly_name = "Cloud Billing Dashboard"
  description   = "BigQuery dataset where the BigQuery views for the billing dashboard"
  location      = var.region

  labels = {
    role = "billing"
  }
}

# BigQuery dataset and tables
module "little_quest_datalake" {
  source     = "terraform-google-modules/bigquery/google"
  version    = "8.1.0"
  project_id = data.google_project.project.project_id

  dataset_id   = "${var.env}_little_quest_datalake"
  dataset_name = "${var.env}_little_quest_datalake"
  description  = "Little Quest DataLake dataset"
  location     = var.region

  dataset_labels = {
    env      = "production"
    billable = "true"
    role     = "datalake"
  }

  tables = [
    {
      table_id    = "realtime_gacha",
      description = "Streaming data for Gacha",
      schema      = file("files/gacha_bq_schema.json"),
      time_partitioning = {
        type                     = "DAY",
        field                    = "publish_time",
        require_partition_filter = false,
        expiration_ms            = null,
      },
      range_partitioning = null,
      expiration_time    = null,
      clustering         = [],
      labels = {
        env      = "production"
        billable = "true"
        function = "gacha"
        realtime = "true"
      },
    },
    {
      table_id    = "realtime_quest_status",
      description = "Streaming data for Quest status",
      schema      = file("files/quest_status_bq_schema.json"),
      time_partitioning = {
        type                     = "DAY",
        field                    = "publish_time",
        require_partition_filter = false,
        expiration_ms            = null,
      },
      range_partitioning = null,
      expiration_time    = null,
      clustering         = [],
      labels = {
        env      = "production"
        billable = "true"
        function = "quest_status"
        realtime = "true"
      },
    },
    {
      table_id    = "realtime_quest_award",
      description = "Streaming data for Quest award",
      schema      = file("files/quest_award_bq_schema.json"),
      time_partitioning = {
        type                     = "DAY",
        field                    = "publish_time",
        require_partition_filter = false,
        expiration_ms            = null,
      },
      range_partitioning = null,
      expiration_time    = null,
      clustering         = [],
      labels = {
        env      = "production"
        billable = "true"
        function = "quest_award"
        realtime = "true"
      },
    },
    {
      table_id    = "realtime_revenue",
      description = "Streaming data for Revenue",
      schema      = file("files/revenue_bq_schema.json"),
      time_partitioning = {
        type                     = "DAY",
        field                    = "publish_time",
        require_partition_filter = false,
        expiration_ms            = null,
      },
      range_partitioning = null,
      expiration_time    = null,
      clustering         = [],
      labels = {
        env      = "production"
        billable = "true"
        function = "revenue"
        realtime = "true"
      }
    }
  ]
}

# ELT and table definitions are done by Dataform
module "little_quest_datawarehouse" {
  source     = "terraform-google-modules/bigquery/google"
  version    = "8.1.0"
  project_id = data.google_project.project.project_id

  dataset_id   = "${var.env}_little_quest_datawarehouse"
  dataset_name = "${var.env}_little_quest_datawarehouse"
  description  = "Little Quest DataWarehouse dataset"
  location     = var.region

  dataset_labels = {
    env      = "production"
    billable = "true"
    role     = "datawarehouse"
  }
}

# ELT and table definitions are done by Dataform
module "little_quest_datamart" {
  source     = "terraform-google-modules/bigquery/google"
  version    = "8.1.0"
  project_id = data.google_project.project.project_id

  dataset_id   = "${var.env}_little_quest_datamart"
  dataset_name = "${var.env}_little_quest_datamart"
  description  = "Little Quest DataMart dataset"
  location     = var.region

  dataset_labels = {
    env      = "production"
    billable = "true"
    role     = "datamart"
  }
}

# BigQuery cost analysis dataset
module "bigquery_cost_analysis" {
  source     = "terraform-google-modules/bigquery/google"
  version    = "8.1.0"
  project_id = data.google_project.project.project_id

  dataset_id   = "bigquery_cost_analysis"
  dataset_name = "bigquery_cost_analysis"
  description  = "BigQuery Cost Analysis"
  location     = var.region

  dataset_labels = {
    billable = "true"
  }
}

module "scheduled_query_sa" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.3.0"
  project_id = data.google_project.project.project_id

  names        = ["bigquery-scheduled-query"]
  display_name = "BigQuery Sceduled Query ServiceAccount"
  project_roles = [
    "${data.google_project.project.project_id}=>roles/bigquery.jobUser",
    "${data.google_project.project.project_id}=>roles/bigquery.dataEditor",
  ]
}

# Scheduled query for GKE Metering
resource "google_bigquery_data_transfer_config" "gke_metering_scheduled_query" {
  project                = data.google_project.project.project_id
  location               = var.region
  data_source_id         = "scheduled_query"
  destination_dataset_id = "all_billing_data"
  schedule               = "every 24 hours"
  display_name           = "GKE Usage Metering Cost Breakdown Scheduled Query"
  params = {
    destination_table_name_template = "gke_metering_cost_breakdown"
    write_disposition               = "WRITE_TRUNCATE"
    query                           = file("files/gke_cost_breakdown_query.sql")
  }
  service_account_name = module.scheduled_query_sa.email

  depends_on = [module.scheduled_query_sa]
}
