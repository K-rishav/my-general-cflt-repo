------------------------------------------------------------------------------------------------------------------------------------------------
Create a datapipeline end to end using terraform. 

This example creates a Basic Cluster in GCP and two connectors DatagenSourceConnector and BigQuerySinkConnector.

Pipeline : DatagenSourceConnector  ------ Orders (topic) -------- BigQuerySinkConnector
------------------------------------------------------------------------------------------------------------------------------------------------
PreReq : 

1. Must have a Cloud Api key and secret to access Confluent Cloud 
2. Must have gcp service account keys to access gcp
3. Must have terraform installed on local machine
4. Must create a gcp bigquery dataset

------------------------------------------------------------------------------------------------------------------------------------------------
Step 1: Clone the github repo

> git clone https://github.com/rishavkumarSE/customer-tf.git

Step 2 : Move to desired folder

> cd customer-tf/terraform_code_cc_datagen_BigQuery

    #key-value that needs to be modified as per your setup
    2.1 Create a stringify of gcp service account key that you downloaded and add it to file main.tf -> section "confluent-bigquery-sink" -> set "keyfile"                  = "<stringify-gcp-key>"
    ...
    "project"                  = "<gcp-project-id>"
    "datasets"                 = "<dataset-name>"

    2.2 Set region name for confluent schema registry (Refer file : main.tf)

    data "confluent_schema_registry_region" "example" {
    ...
    region  = "<region-name>"
    ...
    }

    2.3 set region name for cluster (Refer file : main.tf)

    resource "confluent_kafka_cluster" "basic" {
    ...
    region  = "<region-name>"
    ...
    }

Step 3: Intialize working directory

> terraform init

Step 4: Execute the actions proposed in a Terraform plan.

> terraform plan

> terraform apply

Result : All the resources in confluent cloud will be created and pipeline will start working

------------------------------------------------------------------------------------------------------------------------------------------------

References :

Confluent Provider : https://registry.terraform.io/providers/confluentinc/confluent/latest/docs
Confluent Provider terraform sample project : https://registry.terraform.io/providers/confluentinc/confluent/latest/docs/guides/sample-project
RBAC: https://docs.confluent.io/cloud/current/access-management/access-control/cloud-rbac.html
BigQuerySinkConnector : https://docs.confluent.io/cloud/current/connectors/cc-gcp-bigquery-sink.html#cc-bigquery-json-config-format

------------------------------------------------------------------------------------------------------------------------------------------------

