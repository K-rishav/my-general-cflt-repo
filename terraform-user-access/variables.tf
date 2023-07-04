variable "confluent_cloud_api_key" {
  description = "Confluent Cloud API Key (also referred as Cloud API ID)"
  type        = string
}

variable "confluent_cloud_api_secret" {
  description = "Confluent Cloud API Secret"
  type        = string
  sensitive   = true
}

variable "users" {
  type = map(object({
    name  = string
    id = string
  }))
  default = {
    "user1" = {
      name  = "Dinesh"
      id = "u-mzg9ab"
    },
    "user2" = {
      name  = "Aman"
      id = "u-d1oabc"
    }
  }
}