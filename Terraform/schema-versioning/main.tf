terraform {
  required_version = ">= 0.14.0"
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "1.42.0"
    }
  }
}

provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}

#create environment
resource "confluent_environment" "demo-env" {
  display_name = "demo-env"
}

# Stream Governance and Kafka clusters can be in different regions as well as different cloud providers,
# but you should to place both in the same cloud and region to restrict the fault isolation boundary.
data "confluent_schema_registry_region" "essentials" {
  cloud   = "AWS"
  region  = "us-east-1"
  package = "ADVANCED"
}

resource "confluent_schema_registry_cluster" "essentials" {
  package = data.confluent_schema_registry_region.essentials.package

  environment {
    id = confluent_environment.demo-env.id
  }

  region {
    # See https://docs.confluent.io/cloud/current/stream-governance/packages.html#stream-governance-regions
    id = data.confluent_schema_registry_region.essentials.id
  }
}
resource "confluent_service_account" "env-manager" {
  display_name = "rk-env-manager"
  description  = "Service Account for schema"
}

resource "confluent_role_binding" "environment-example-rb-2" {
  principal   = "User:${confluent_service_account.env-manager.id}"
  role_name   = "EnvironmentAdmin"
  crn_pattern = confluent_environment.demo-env.resource_name
}

resource "confluent_api_key" "env-manager-schema-registry-api-key" {
  display_name = "env-manager-schema-registry-api-key"
  description  = "Schema Registry API Key that is owned by 'env-manager' service account"
  owner {
    id          = confluent_service_account.env-manager.id
    api_version = confluent_service_account.env-manager.api_version
    kind        = confluent_service_account.env-manager.kind
  }

  managed_resource {
    id          = confluent_schema_registry_cluster.essentials.id
    api_version = confluent_schema_registry_cluster.essentials.api_version
    kind        = confluent_schema_registry_cluster.essentials.kind

    environment {
      id = confluent_environment.demo-env.id
    }
  }

#   lifecycle {
#     prevent_destroy = true
#   }
}

# Update the config to use a cloud provider and region of your choice.
# https://registry.terraform.io/providers/confluentinc/confluent/latest/docs/resources/confluent_kafka_cluster
resource "confluent_kafka_cluster" "basic" {
  display_name = "demo-cluster"
  availability = "SINGLE_ZONE"
  cloud        = "AWS"
  region       = "us-east-1"
  basic {}
  environment {
    id = confluent_environment.demo-env.id
  }
}

# Default Option #1: Manage the latest schema version only. The resource instance always points to the latest schema version by supporting in-place updates

# run terraform apply and we will see a schema is created
# version 1 of schema is created
# Evolve schema by updating schemas/avro/purchase.avsc.
# now again run terraform apply
# version 2 of schema is created
# comment the confluent_schema resource (line 105-118) to replicate destroy scenario
# run terraform apply
# we will see that the latest version is deleted but old version is still there

# Issue: we missed the ability to remove old schema versions in case you remove the terraform resource

# Note: after running 'terraform destroy' just v2 (the latest version) will
# be soft-deleted by default (set hard_delete=true for a hard deletion).

resource "confluent_schema" "avro-purchase" {
  schema_registry_cluster {
    id = confluent_schema_registry_cluster.essentials.id
  }
  rest_endpoint = confluent_schema_registry_cluster.essentials.rest_endpoint
  subject_name = "avro-purchase-values"
  format = "AVRO"
  schema = file("./schemas/avro/purchase.avsc")
  credentials {
    key    = confluent_api_key.env-manager-schema-registry-api-key.id
    secret = confluent_api_key.env-manager-schema-registry-api-key.secret
  }
  # hard_delete = true
}


# Option #2: Manage different schema versions using different resource instances
# Any schema version can be removed easily by removing that resource
# Comment out line 127-140 & 157 and run terraform apply
# Result the first version of the avro-sample-value schema is deleted whereas second version remains intact


#confluent_schema.avro-sample-v1 manages v1.
resource "confluent_schema" "avro-sample-v1" {
    schema_registry_cluster {
    id = confluent_schema_registry_cluster.essentials.id
  }
  rest_endpoint = confluent_schema_registry_cluster.essentials.rest_endpoint
  subject_name = "avro-sample-value"
  format = "AVRO"
  schema = file("./schemas/avro/sample_v1.avsc")
  credentials {
    key    = confluent_api_key.env-manager-schema-registry-api-key.id
    secret = confluent_api_key.env-manager-schema-registry-api-key.secret
  }
  recreate_on_update = true
}

# confluent_schema.avro-sample-v2 manages v2. 
resource "confluent_schema" "avro-sample-v2" {
 schema_registry_cluster {
    id = confluent_schema_registry_cluster.essentials.id
  }
  rest_endpoint = confluent_schema_registry_cluster.essentials.rest_endpoint
  subject_name = "avro-sample-value"
  format = "AVRO"
  schema = file("./schemas/avro/sample_v2.avsc")
  credentials {
    key    = confluent_api_key.env-manager-schema-registry-api-key.id
    secret = confluent_api_key.env-manager-schema-registry-api-key.secret
  }
  recreate_on_update = true
  depends_on = [ confluent_schema.avro-sample-v1 ]
}
