variable "aws_region" {
  type  = string
  default = "ap_southeast_2"
}

variable "pipeline_name" {
  type  = string
  default = "default_pipeline"
}

variable "pipeline_s3_bucket" {
  type  = string
  default = "s3_coderepo"
}

variable "pipeline_role_name" {
  type  = string
  default = "default_pipeline_role"
}

variable "pipeline_role_policy_name" {
  type = string
  default = "default_pipeline_role_policy"
}
