variable "aws_region" {
  type  = string
  default = "ap-southeast-2"
}

variable "pipeline_name" {
  type  = string
  default = "default_pipeline"
}

variable "pipeline_s3_bucket" {
  type  = string
  default = "s3-coderepo"
}

variable "pipeline_role_name" {
  type  = string
  default = "default_pipeline_role"
}

variable "pipeline_role_policy_name" {
  type = string
  default = "default_pipeline_role_policy"
}

variable "codebuild_project_name" {
  type = string
  default = "default_codebuild_project"
}
