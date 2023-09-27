data "confluent_organization" "sts_org" {}

data "confluent_environment" "env" {
  id = "env-abc8zm"
}

data "confluent_kafka_cluster" "standard-1" {
  id = "lkc-5mqabc"
  environment {
    id = "env-abc8zm"
  }
}
# Ouptut :  "crn://confluent.cloud/organization=5f242057-6c74-4ba5-9942-123453203b93"
output "org-arn"{
    value = data.confluent_organization.sts_org.resource_name
}

#Output : "crn://confluent.cloud/organization=5f242057-6c74-4ba5-9942-123453203b93/environment=env-abc8zm"
output "env-arn"{
    value = data.confluent_environment.env.resource_name
}

#Output : "crn://confluent.cloud/organization=5f242057-6c74-4ba5-9942-123453203b93/environment=env-abc8zm/cloud-cluster=lkc-5mqabc"
output "cluster-arn"{
    value = data.confluent_kafka_cluster.standard-1.rbac_crn
}

#  1. Topics
# assigning two users DeveloperRead for all the topics in a single cluster
# crn_pattern (for Kafka Topic ) : "crn://confluent.cloud/organization=5f242057-6c74-4ba5-9942-123453203b93/environment=env-abc8zm/cloud-cluster=lkc-5mqabc/kafka=lkc-5mqabc/topic=*"
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
}

#Schema Registry Cluster data source
#Method 1 : using name
#https://registry.terraform.io/providers/confluentinc/confluent/latest/docs/data-sources/confluent_schema_registry_cluster
data "confluent_schema_registry_cluster" "sr_example_using_name" {
  display_name = "Stream Governance Package"
  environment {
    id = data.confluent_environment.env.id
  }
}

#Schema Registry Cluster data source
#Method 2 : using id
#https://registry.terraform.io/providers/confluentinc/confluent/latest/docs/data-sources/confluent_schema_registry_cluster
data "confluent_schema_registry_cluster" "sr_example_using_id" {
  id = "lsrc-v1ny1n"
  environment {
    id = data.confluent_environment.env.id
  }
}






