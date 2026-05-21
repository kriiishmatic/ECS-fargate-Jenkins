variable "project_name" {
  default = "stackly"
}
variable "environment" {
  default = "dev"
}

variable "region" {
  default = "us-east-1"
}

variable "frontend_image" {
  default = "854481201869.dkr.ecr.us-east-1.amazonaws.com/stackly/frontend:1.0.0"
  
}

variable "catalogue_image" {
  default = "854481201869.dkr.ecr.us-east-1.amazonaws.com/stackly/catalogue:1.0.0"
}
variable "cart_image" {
  default =  ""
}
variable "user_image" {
  default =  "854481201869.dkr.ecr.us-east-1.amazonaws.com/stackly/user:1.0.0"
}
variable "shipping_image" {
  default =  "854481201869.dkr.ecr.us-east-1.amazonaws.com/stackly/shipping:1.0.0"
}
variable "payment_image" {
  default =  "854481201869.dkr.ecr.us-east-1.amazonaws.com/stackly/payment:1.0.0"
}

variable "mongodb_image" {
  default = "854481201869.dkr.ecr.us-east-1.amazonaws.com/stackly/mongodb:1.0.0"
}
variable "redis_image" {
  default = "854481201869.dkr.ecr.us-east-1.amazonaws.com/stackly/redis:1.0.0"
}
variable "mysql_image" {
  default = "854481201869.dkr.ecr.us-east-1.amazonaws.com/stackly/mysql:1.0.0"
}
variable "rabbitmq_image" {
  default = "854481201869.dkr.ecr.us-east-1.amazonaws.com/stackly/rabbitmq:1.0.0"
}