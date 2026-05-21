locals {
  common_name_suffix = "${var.project_name}-${var.environment}" # stackly-dev
  common_tags = {
      Project = var.project_name
      Environment = var.environment
      Terraform = "true"
  }
}
