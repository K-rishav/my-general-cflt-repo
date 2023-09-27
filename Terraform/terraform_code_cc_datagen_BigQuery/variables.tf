variable "confluent_cloud_api_key" {
  description = "Confluent Cloud API Key (also referred as Cloud API ID)"
  type        = string
}

variable "confluent_cloud_api_secret" {
  description = "Confluent Cloud API Secret"
  type        = string
  sensitive   = true
}

variable "customer_region" {
  description = "The region of the GCP BigQuery"
  type        = string
  #default =  "us-central1"
}

variable "customer_project_id" {
  description = "The GCP Project ID"
  type        = string
}