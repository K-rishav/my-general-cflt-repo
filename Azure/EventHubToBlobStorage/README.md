# Step-by-Step Setup of Confluent Platform using Confluent for Kubernetes and data pipeline from Azure EventHub to Azure Blob Storage

## Prerequisites
- A Kubernetes cluster conforming to one of the supported versions.
- kubectl installed, initialized, with the context set. You also must have the kubeconfig file configured for your cluster.
- Helm 3 installed.

## Clone the Repository
```bash
git clone [<repository_url>]
```

## Confluent Platform Setup
kubectl apply -f confluent-platform.yaml

## Port forwarding
kubectl port-forward pod/controlcenter-0 9021:9021

## Access the control Center from local system
URL : http://localhost:9021/

## Create a topic name "test" in Control Center

## Create Azure EventHub Source Connector
kubectl apply -f eventhub-connector.yaml

## Load some data in Azure EventHub using Azure Portal

## Create Azure Blob Storage Sink Connector
kubectl apply -f blob-connector.yaml

## References

1. https://docs.confluent.io/operator/current/overview.html
1. https://docs.confluent.io/kafka-connectors/azure-event-hubs/current/overview.html
1. https://docs.confluent.io/kafka-connectors/azure-blob-storage-sink/current/overview.html

