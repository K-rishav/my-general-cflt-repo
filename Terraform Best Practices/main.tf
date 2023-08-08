# Create and set up topics via a centralized script, and restrict access based on certain rules
# How to create API Keys per domain (automatically or one-off setup)
# How to restrict service account access to topic, monitoring and logging based on specific RBAC rules
# How to restrict human user access to topics, schemas and consumer groups based on specific RBAC rules
# Ensure that all topics much supply a schema, using Schema registry - depending on details here, this is either standard use of Schema Registry or something that needs to be set-up and maintained programmatically, differences of which can be discussed in the workshop
# Uploading and upgrade schemas automatically via a centralized script


# ------------------------------------------------------------------------------------------------------------------------------------------------ #
# Data Sources
# Fetch organization information
data "confluent_organization" "sts_org" {}

# Fetch environment information
#https://registry.terraform.io/providers/confluentinc/confluent/latest/docs/data-sources/confluent_environment
data "confluent_environment" "env" {
  id = "env-prp8zm"
}

# Fetch Kafka cluster information
#https://registry.terraform.io/providers/confluentinc/confluent/latest/docs/data-sources/confluent_kafka_cluster
data "confluent_kafka_cluster" "standard-1" {
  id = "lkc-o2vxpo"
  environment {
    id = "env-prp8zm"
  }
}

# ------------------------------------------------------------------------------------------------------------------------------------------------ #
// 'app-manager' service account is required in this configuration to create 'orders' topic and grant ACLs
// to 'app-producer' and 'app-consumer' service accounts.
# Create a service account named 'app-manager' and grant it administrative privileges
resource "confluent_service_account" "app-manager" {
  display_name = "app-manager"
  description  = "Service account to manage 'inventory' Kafka cluster"
}

# Assign the 'CloudClusterAdmin' role to the 'app-manager' service account
resource "confluent_role_binding" "app-manager-kafka-cluster-admin" {
  principal   = "User:${confluent_service_account.app-manager.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = data.confluent_kafka_cluster.standard-1.rbac_crn
}

# Create an API key for the 'app-manager' service account
#https://registry.terraform.io/providers/confluentinc/confluent/latest/docs/resources/confluent_api_key
resource "confluent_api_key" "app-manager-kafka-api-key" {
  display_name = "app-manager-kafka-api-key"
  description  = "Kafka API Key that is owned by 'app-manager' service account"
  owner {
    id          = confluent_service_account.app-manager.id
    api_version = confluent_service_account.app-manager.api_version
    kind        = confluent_service_account.app-manager.kind
  }

  managed_resource {
    id          = data.confluent_kafka_cluster.standard-1.id
    api_version = data.confluent_kafka_cluster.standard-1.api_version
    kind        = data.confluent_kafka_cluster.standard-1.kind

    environment {
      id = data.confluent_environment.env.id
    }
  }
  depends_on = [
    confluent_role_binding.app-manager-kafka-cluster-admin
  ]
}

# Create a Kafka topic named 'orders'
resource "confluent_kafka_topic" "orders" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.standard-1.id
  }
  topic_name         = "orders"
  rest_endpoint      = data.confluent_kafka_cluster.standard-1.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}
# ------------------------------------------------------------------------------------------------------------------------------------------------ #
# Create a service account named 'app-consumer' for consuming from the 'orders' topic
resource "confluent_service_account" "app-consumer" {
  display_name = "app-consumer"
  description  = "Service account to consume from 'orders' topic of 'inventory' Kafka cluster"
}

# Create an API key for the 'app-consumer' service account
resource "confluent_api_key" "app-consumer-kafka-api-key" {
  display_name = "app-consumer-kafka-api-key"
  description  = "Kafka API Key that is owned by 'app-consumer' service account"
  owner {
    id          = confluent_service_account.app-consumer.id
    api_version = confluent_service_account.app-consumer.api_version
    kind        = confluent_service_account.app-consumer.kind
  }

  managed_resource {
    id          = data.confluent_kafka_cluster.standard-1.id
    api_version = data.confluent_kafka_cluster.standard-1.api_version
    kind        = data.confluent_kafka_cluster.standard-1.kind

    environment {
      id = data.confluent_environment.env.id
    }
  }
}


# Set up ACLs for consumer access to the 'orders' topic
resource "confluent_kafka_acl" "app-consumer-read-on-group" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.standard-1.id
  }
  resource_type = "GROUP"
  // The existing values of resource_name, pattern_type attributes are set up to match Confluent CLI's default consumer group ID ("confluent_cli_consumer_<uuid>").
  // https://docs.confluent.io/confluent-cli/current/command-reference/kafka/topic/confluent_kafka_topic_consume.html
  // Update the values of resource_name, pattern_type attributes to match your target consumer group ID.
  // https://docs.confluent.io/platform/current/kafka/authorization.html#prefixed-acls
  resource_name = "confluent_cli_consumer_"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.app-consumer.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
  rest_endpoint = data.confluent_kafka_cluster.standard-1.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}
// Note that in order to consume from a topic, the principal of the consumer ('app-consumer' service account)
// needs to be authorized to perform 'READ' operation on both Topic and Group resources:
// confluent_kafka_acl.app-consumer-read-on-topic, confluent_kafka_acl.app-consumer-read-on-group.
// https://docs.confluent.io/platform/current/kafka/authorization.html#using-acls
resource "confluent_kafka_acl" "app-consumer-read-on-topic" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.standard-1.id
  }
  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.orders.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.app-consumer.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
  rest_endpoint = data.confluent_kafka_cluster.standard-1.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

# ------------------------------------------------------------------------------------------------------------------------------------------------ #
# Create a service account named 'app-producer' for producing to the 'orders' topic
resource "confluent_service_account" "app-producer" {
  display_name = "app-producer"
  description  = "Service account to produce to 'orders' topic of 'inventory' Kafka cluster"
}

# Create an API key for the 'app-producer' service account
resource "confluent_api_key" "app-producer-kafka-api-key" {
  display_name = "app-producer-kafka-api-key"
  description  = "Kafka API Key that is owned by 'app-producer' service account"
  owner {
    id          = confluent_service_account.app-producer.id
    api_version = confluent_service_account.app-producer.api_version
    kind        = confluent_service_account.app-producer.kind
  }

  managed_resource {
    id          = data.confluent_kafka_cluster.standard-1.id
    api_version = data.confluent_kafka_cluster.standard-1.api_version
    kind        = data.confluent_kafka_cluster.standard-1.kind

    environment {
      id = data.confluent_environment.env.id
    }
  }
}

# Set up ACLs for producer access to the 'orders' topic
resource "confluent_kafka_acl" "app-producer-write-on-topic" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.standard-1.id
  }
  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.orders.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.app-producer.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
  rest_endpoint = data.confluent_kafka_cluster.standard-1.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}
# ------------------------------------------------------------------------------------------------------------------------------------------------ #
# Users given DeveloperRead access on resources like topics , Consumer Groups,Connectors, pipelines 


# Ouptut :  "crn://confluent.cloud/organization=5f242057-6c74-4ba5-9942-60d363203b93"
output "org-arn"{
    value = data.confluent_organization.sts_org.resource_name
}

#Output : "crn://confluent.cloud/organization=5f242057-6c74-4ba5-9942-60d363203b93/environment=env-prp8zm"
output "env-arn"{
    value = data.confluent_environment.env
}

#Output : "crn://confluent.cloud/organization=5f242057-6c74-4ba5-9942-60d363203b93/environment=env-prp8zm/cloud-cluster=lkc-5mqryn"
output "cluster-arn"{
    value = data.confluent_kafka_cluster.standard-1.rbac_crn
}

#  1. Topics
# assigning two users DeveloperRead for all the topics in a single cluster

# crn_pattern (for Kafka Topic ) : "crn://confluent.cloud/organization=5f242057-6c74-4ba5-9942-60d363203b93/environment=env-prp8zm/cloud-cluster=lkc-5mqryn/kafka=lkc-5mqryn/topic=*"
# CRN https://docs.confluent.io/cloud/current/api.html#section/Identifiers-and-URLs/Confluent-Resource-Names-(CRNs)
resource "confluent_role_binding" "confluent_role_binding_topic" {
  
  for_each = var.users 
  role_name   = "DeveloperRead"
  principal   = "User:${each.value.id}"
  crn_pattern = "${data.confluent_kafka_cluster.standard-1.rbac_crn}/kafka=${data.confluent_kafka_cluster.standard-1.id}/topic=*"
}

#   2. Consumer Groups
# Grant Permission to all Consumer groups
resource "confluent_role_binding" "confluent_role_binding_consumergroups" {
  for_each = var.users 
  principal = "User:${each.value.id}"
  role_name = "DeveloperRead"
  crn_pattern = "${data.confluent_kafka_cluster.standard-1.rbac_crn}/kafka=${data.confluent_kafka_cluster.standard-1.id}/group=*"
}

#   3. Connectors
# Grant Permission to all Connectos within a cluster 
resource "confluent_role_binding" "confluent_role_binding_connectors" {
  
  for_each = var.users 
  role_name   = "DeveloperRead"
  principal   = "User:${each.value.id}"
  crn_pattern = "${data.confluent_kafka_cluster.standard-1.rbac_crn}/connector=*"
  #crn_pattern = "${data.confluent_kafka_cluster.standard-1.rbac_crn}/connector=DatagenSourceConnector_1"
}

#4. Pipeline
resource "confluent_role_binding" "confluent_role_binding_pipeline" {
  
  for_each = var.users 
  role_name   = "DeveloperRead"
  principal   = "User:${each.value.id}"
  crn_pattern = "${data.confluent_kafka_cluster.standard-1.rbac_crn}/pipeline=*"
  #crn_pattern = "${data.confluent_kafka_cluster.standard-1.rbac_crn}/connector=DatagenSourceConnector_1"
}