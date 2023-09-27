terraform {
  required_version = ">= 0.14.0"
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "1.42.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "4.18.0"
    }
  }
}

provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}

# Set GOOGLE_APPLICATION_CREDENTIALS environment variable to a path to a key file
# for Google TF Provider to work: https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/getting_started#adding-credentials
provider "google" {
  project = var.customer_project_id
  region  = var.customer_region
}
