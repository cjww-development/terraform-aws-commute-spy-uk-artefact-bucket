variable "region" {
  type        = string
  description = "The AWS region IaC will be deployed into"
}

variable "trust_bucket_access_arn" {
  type        = string
  description = "ARN for role to access bucket"
}

variable "bucket_name" {
  type        = string
  description = "Name of bucket holding the artefacts"
}

variable "read_only_account_arns" {
  type        = list(string)
  description = "List of account arns that are allowed to read artefacts"
}

variable "force_destroy" {
  type        = bool
  description = "Force the destruction of bucket and ALL data therein"
  default     = false
}
