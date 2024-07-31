data "google_project" "project" {
}

## Cloud Pub/Sub
module "gke_cluster_upgrade_notification" {
  source     = "terraform-google-modules/pubsub/google"
  version    = "6.0.0"
  project_id = data.google_project.project.project_id

  topic                            = "gke-cluster-upgrade-notification"
  create_topic                     = true
  grant_token_creator              = true
  topic_message_retention_duration = "604800s"
  topic_labels = {
    env  = "production",
    case = "gke-cluster-upgrade-notification"
  }
}

module "pubsub_gacha" {
  source     = "terraform-google-modules/pubsub/google"
  version    = "6.0.0"
  project_id = data.google_project.project.project_id

  topic                            = "${var.env}-realtime-da-gacha"
  create_topic                     = true
  grant_token_creator              = true
  topic_message_retention_duration = "604800s"
  topic_labels = {
    env  = "production",
    case = "realtime-da-gacha"
  }

  bigquery_subscriptions = [
    {
      name                = "${var.env}-gacha-subscription"
      table               = "${data.google_project.project.project_id}.${var.env}_little_quest_datalake.realtime_gacha"
      use_topic_schema    = true
      write_metadata      = true
      drop_unknown_fields = false

      ack_deadline_seconds         = 20
      expiration_policy            = ""
      dead_letter_topic            = "${data.google_project.project.id}/topics/${var.env}-dead-letter"
      max_delivery_attempts        = 5
      maximum_backoff              = "600s"
      minimum_backoff              = "10s"
      enable_message_ordering      = false
      enable_exactly_once_delivery = false
    }
  ]

  schema = {
    name       = "gacha-schema"
    type       = "AVRO"
    encoding   = "JSON"
    definition = file("files/gacha_pubsub_schema.json")
  }

  depends_on = [module.dead_letter]
}

module "pubsub_quest_status" {
  source     = "terraform-google-modules/pubsub/google"
  version    = "6.0.0"
  project_id = data.google_project.project.project_id

  topic                            = "${var.env}-realtime-da-quest-status"
  create_topic                     = true
  grant_token_creator              = true
  topic_message_retention_duration = "604800s"
  topic_labels = {
    env  = "production",
    case = "realtime-da-quest-status"
  }

  bigquery_subscriptions = [
    {
      name                = "${var.env}-quest-status-subscription"
      table               = "${data.google_project.project.project_id}.${var.env}_little_quest_datalake.realtime_quest_status"
      use_topic_schema    = true
      write_metadata      = true
      drop_unknown_fields = false

      ack_deadline_seconds         = 20
      expiration_policy            = ""
      dead_letter_topic            = "${data.google_project.project.id}/topics/${var.env}-dead-letter"
      max_delivery_attempts        = 5
      maximum_backoff              = "600s"
      minimum_backoff              = "10s"
      enable_message_ordering      = false
      enable_exactly_once_delivery = false
    }
  ]

  schema = {
    name       = "quest-status-schema"
    type       = "AVRO"
    encoding   = "JSON"
    definition = file("files/quest_status_pubsub_schema.json")
  }

  depends_on = [module.dead_letter]
}

module "pubsub_quest_award" {
  source     = "terraform-google-modules/pubsub/google"
  version    = "6.0.0"
  project_id = data.google_project.project.project_id

  topic                            = "${var.env}-realtime-da-quest-award"
  create_topic                     = true
  grant_token_creator              = true
  topic_message_retention_duration = "604800s"
  topic_labels = {
    env  = "production",
    case = "realtime-da-quest-award"
  }

  bigquery_subscriptions = [
    {
      name                = "${var.env}-quest-award-subscription"
      table               = "${data.google_project.project.project_id}.${var.env}_little_quest_datalake.realtime_quest_award"
      use_topic_schema    = true
      write_metadata      = true
      drop_unknown_fields = false

      ack_deadline_seconds         = 20
      expiration_policy            = ""
      dead_letter_topic            = "${data.google_project.project.id}/topics/${var.env}-dead-letter"
      max_delivery_attempts        = 5
      maximum_backoff              = "600s"
      minimum_backoff              = "10s"
      enable_message_ordering      = false
      enable_exactly_once_delivery = false
    }
  ]

  schema = {
    name       = "quest-award-schema"
    type       = "AVRO"
    encoding   = "JSON"
    definition = file("files/quest_award_pubsub_schema.json")
  }

  depends_on = [module.dead_letter]
}

module "pubsub_revenue" {
  source     = "terraform-google-modules/pubsub/google"
  version    = "6.0.0"
  project_id = data.google_project.project.project_id

  topic                            = "${var.env}-realtime-da-revenue"
  create_topic                     = true
  grant_token_creator              = true
  topic_message_retention_duration = "604800s"
  topic_labels = {
    env  = "production",
    case = "realtime-da-revenue"
  }

  bigquery_subscriptions = [
    {
      name                = "${var.env}-revenue-subscription"
      table               = "${data.google_project.project.project_id}.${var.env}_little_quest_datalake.realtime_revenue"
      use_topic_schema    = true
      write_metadata      = true
      drop_unknown_fields = false

      ack_deadline_seconds         = 20
      expiration_policy            = ""
      dead_letter_topic            = "${data.google_project.project.id}/topics/${var.env}-dead-letter"
      max_delivery_attempts        = 5
      maximum_backoff              = "600s"
      minimum_backoff              = "10s"
      enable_message_ordering      = false
      enable_exactly_once_delivery = false
    }
  ]

  schema = {
    name       = "revenue-schema"
    type       = "AVRO"
    encoding   = "JSON"
    definition = file("files/revenue_pubsub_schema.json")
  }

  depends_on = [module.dead_letter]
}

module "dead_letter" {
  source     = "terraform-google-modules/pubsub/google"
  version    = "6.0.0"
  project_id = data.google_project.project.project_id

  topic                            = "${var.env}-dead-letter"
  create_topic                     = true
  grant_token_creator              = true
  topic_message_retention_duration = "604800s"
  topic_labels = {
    env  = "production",
    case = "dead-letter"
  }

  pull_subscriptions = [
    {
      name                         = "${var.env}-dead-letter-subscription"
      ack_deadline_seconds         = 20
      expiration_policy            = ""
      max_delivery_attempts        = 5
      maximum_backoff              = "600s"
      minimum_backoff              = "10s"
      enable_message_ordering      = false
      enable_exactly_once_delivery = false
    }
  ]
}

resource "google_project_iam_member" "allow_publisher_deadletter" {
  project = data.google_project.project.id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "allow_subscriber_deadletter" {
  project = data.google_project.project.id
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}
