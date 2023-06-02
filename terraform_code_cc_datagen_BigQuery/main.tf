#create environment 
resource "confluent_environment" "development" {
  display_name = "dev-env"
}

data "confluent_schema_registry_region" "example" {
  cloud   = "GCP"
  region  = "us-central1"
  package = "ESSENTIALS"
}

#enable schema registry essential package
resource "confluent_schema_registry_cluster" "essentials" {
  package = data.confluent_schema_registry_region.example.package

  environment {
    id = confluent_environment.development.id
  }

  region {
    # See https://docs.confluent.io/cloud/current/stream-governance/packages.html#stream-governance-regions
    # Stream Governance and Kafka clusters can be in different regions as well as different cloud providers,
    # but you should to place both in the same cloud and region to restrict the fault isolation boundary.
    id = data.confluent_schema_registry_region.example.id
  }
}

#create basic cluster
resource "confluent_kafka_cluster" "basic" {
  display_name = "basic_kafka_cluster_gcp"
  availability = "SINGLE_ZONE"
  cloud        = "GCP"
  region       = "us-central1"
  basic {}

  environment {
    id = confluent_environment.development.id
  }
}

#create service account for Kakfa cluster
resource "confluent_service_account" "app-manager" {
  display_name = "app-manager-sa"
  description  = "Service Account for orders app"
}

#attach role to service account
resource "confluent_role_binding" "app-manager-kafka-cluster-admin" {
  principal   = "User:${confluent_service_account.app-manager.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.basic.rbac_crn
}

#create api key to access
resource "confluent_api_key" "app-manager-kafka-api-key" {
  display_name = "app-manager-kafka-api-key"
  description  = "Kafka API Key that is owned by 'app-manager' service account"
  owner {
    id          = confluent_service_account.app-manager.id
    api_version = confluent_service_account.app-manager.api_version
    kind        = confluent_service_account.app-manager.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.basic.id
    api_version = confluent_kafka_cluster.basic.api_version
    kind        = confluent_kafka_cluster.basic.kind

    environment {
      id = confluent_environment.development.id
    }
  }
 depends_on = [
    confluent_role_binding.app-manager-kafka-cluster-admin,
  ]
}

#create a topic
resource "confluent_kafka_topic" "orders" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }
  topic_name    = "orders"
  rest_endpoint      = confluent_kafka_cluster.basic.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

#creating datagen source connector
resource "confluent_connector" "datagen-source" {
  environment {
    id = confluent_environment.development.id
  }
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }
  config_sensitive = {}

  config_nonsensitive = {
    "connector.class"          = "DatagenSource"
    "name"                     = "DatagenSourceConnector_0"
    "kafka.auth.mode"          = "SERVICE_ACCOUNT"
    "kafka.service.account.id" = confluent_service_account.app-manager.id
    "kafka.topic"              = confluent_kafka_topic.orders.topic_name
    "output.data.format"       = "AVRO"
    "quickstart"               = "ORDERS"
    "tasks.max"                = "1"
  }


  depends_on = [
    #confluent_kafka_acl.describe-basic-cluster,
    confluent_api_key.app-manager-kafka-api-key,
  ]
}

############################### BQ Sink Connector Service Account ####################

#create another service account for BQ consumer
resource "confluent_service_account" "app-connector-sink-BQ" {
  display_name = "app-connector-sink-BQ"
  description  = "Service account of BQ Sink Connector to consume from 'orders' topic "
}

resource "confluent_kafka_acl" "app-connector-sink-BQ-describe-on-cluster" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }
  resource_type = "CLUSTER"
  resource_name = "kafka-cluster"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.app-connector-sink-BQ.id}"
  host          = "*"
  operation     = "DESCRIBE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.basic.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }

}

resource "confluent_kafka_acl" "app-connector-sink-BQ-read-on-target-topic" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }
  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.orders.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.app-connector-sink-BQ.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.basic.rest_endpoint
 credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "app-connector-sink-BQ-create-on-dlq-lcc-topics" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }
  resource_type = "TOPIC"
  resource_name = "dlq-lcc"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.app-connector-sink-BQ.id}"
  host          = "*"
  operation     = "CREATE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.basic.rest_endpoint
   credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "app-connector-sink-BQ-write-on-dlq-lcc-topics" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }
  resource_type = "TOPIC"
  resource_name = "dlq-lcc"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.app-connector-sink-BQ.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.basic.rest_endpoint
   credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "app-connector-sink-BQ-create-on-success-lcc-topics" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }
  resource_type = "TOPIC"
  resource_name = "success-lcc"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.app-connector-sink-BQ.id}"
  host          = "*"
  operation     = "CREATE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.basic.rest_endpoint
   credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "app-connector-sink-BQ-write-on-success-lcc-topics" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }
  resource_type = "TOPIC"
  resource_name = "success-lcc"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.app-connector-sink-BQ.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.basic.rest_endpoint
   credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "app-connector-sink-BQ-create-on-error-lcc-topics" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }
  resource_type = "TOPIC"
  resource_name = "error-lcc"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.app-connector-sink-BQ.id}"
  host          = "*"
  operation     = "CREATE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.basic.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "app-connector-sink-BQ-write-on-error-lcc-topics" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }
  resource_type = "TOPIC"
  resource_name = "error-lcc"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.app-connector-sink-BQ.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.basic.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "app-connector-sink-BQ-read-on-connect-lcc-group" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }
  resource_type = "GROUP"
  resource_name = "connect-lcc"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.app-connector-sink-BQ.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.basic.rest_endpoint
   credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

######################## BigQuery Sink Connector ###########################################

resource "confluent_connector" "confluent-bigquery-sink" {
  environment {
    id = confluent_environment.development.id
  }
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }
  
  // Block for custom *nonsensitive* configuration properties that are *not* labelled with "Type: password" under "Configuration Properties" section in the docs:
  // https://docs.confluent.io/cloud/current/connectors/cc-gcp-bigquery-sink.html
  config_nonsensitive = {
    "topics"                   = confluent_kafka_topic.orders.topic_name
    "input.data.format"        = "AVRO"
    "connector.class"          = "BigQuerySink"
    "name"                     = "BQ_SINKConnector_0"
    "kafka.auth.mode"          = "SERVICE_ACCOUNT"
    "kafka.service.account.id" = confluent_service_account.app-connector-sink-BQ.id
    "project"                  = "sales-engineering-206314"
    "datasets"                 = "rishav_dataset"
    "sanitizeTopics"           = "true"
    "autoUpdateSchemas"        = "true"
    "sanitizeFieldNames"       = "true"
    "tasks.max"                = "1"
    "auto.create.tables"       = "true"
    "keyfile"                  = "<stringify-gcp-key>" #use stringify-gcp-credentials.py to convert json to stringify output Ref https://github.com/NathanNam/stringify-gcp-credentials/blob/master/README.md
  }
  depends_on = [
    confluent_kafka_acl.app-connector-sink-BQ-describe-on-cluster,
    confluent_kafka_acl.app-connector-sink-BQ-read-on-target-topic,
    confluent_kafka_acl.app-connector-sink-BQ-create-on-dlq-lcc-topics,
    confluent_kafka_acl.app-connector-sink-BQ-write-on-dlq-lcc-topics,
    confluent_kafka_acl.app-connector-sink-BQ-create-on-success-lcc-topics,
    confluent_kafka_acl.app-connector-sink-BQ-write-on-success-lcc-topics,
    confluent_kafka_acl.app-connector-sink-BQ-create-on-error-lcc-topics,
    confluent_kafka_acl.app-connector-sink-BQ-write-on-error-lcc-topics,
    confluent_kafka_acl.app-connector-sink-BQ-read-on-connect-lcc-group,
  ]
}