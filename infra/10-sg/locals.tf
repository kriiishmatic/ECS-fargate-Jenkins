locals {
  common_name_suffix = "${var.project_name}-${var.environment}" # stackly-dev
  vpc_id = data.aws_ssm_parameter.vpc_id.value
}