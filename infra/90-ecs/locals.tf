locals {
  common_name_suffix = "${var.project_name}-${var.environment}" # stackly-dev
  vpc_id = data.aws_ssm_parameter.vpc_id.value
  private_subnet_ids = split("," , data.aws_ssm_parameter.private_subnet_ids.value)
  frontend_alb_sg_id = data.aws_ssm_parameter.frontend_alb_sg_id.value
  public_subnet_ids = split("," , data.aws_ssm_parameter.public_subnet_ids.value)
  frontend_alb_certificate_arn = data.aws_ssm_parameter.frontend_alb_certificate_arn.value
  frontend_sg_id = data.aws_ssm_parameter.frontend_sg_id.value
  catalogue_sg_id = data.aws_ssm_parameter.catalogue_sg_id.value
  user_sg_id = data.aws_ssm_parameter.user_sg_id.value
  cart_sg_id = data.aws_ssm_parameter.cart_sg_id.value
  shipping_sg_id = data.aws_ssm_parameter.shipping_sg_id.value
  payment_sg_id = data.aws_ssm_parameter.payment_sg_id.value
  mongodb_sg_id = data.aws_ssm_parameter.mongodb_sg_id.value
  mysql_sg_id = data.aws_ssm_parameter.mysql_sg_id.value
  redis_sg_id = data.aws_ssm_parameter.redis_sg_id.value
  rabbitmq_sg_id = data.aws_ssm_parameter.rabbitmq_sg_id.value
  
  common_tags = {
    Project = var.project_name
    Environment = var.environment
    Terraform = "true"
  }
 
  cloudmap_services = [
    "frontend",
    "catalogue",
    "user",
    "cart",
    "shipping",
    "payment",
    "mongodb",
    "redis",
    "mysql",
    "rabbitmq"
  ]
}
