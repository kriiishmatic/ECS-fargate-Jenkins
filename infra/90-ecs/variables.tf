variable "project_name" {
  default = "project-k"
}
variable "environment" {
  default = "dev"
}

variable "region" {
  default = "us-east-1"
}

variable "frontend_image" {
  default = "392401698561.dkr.ecr.us-east-1.amazonaws.com/project-k/frontend:1.0.0"
  
}

variable "catalogue_image" {
  default = "392401698561.dkr.ecr.us-east-1.amazonaws.com/project-k/catalogue:1.0.0"
}
variable "cart_image" {
  default =  "392401698561.dkr.ecr.us-east-1.amazonaws.com/project-k/cart:1.0.0"
}
variable "user_image" {
  default =  "392401698561.dkr.ecr.us-east-1.amazonaws.com/project-k/user:1.0.0"
}
variable "shipping_image" {
  default =  "392401698561.dkr.ecr.us-east-1.amazonaws.com/project-k/shipping:1.0.0"
}
variable "payment_image" {
  default =  "392401698561.dkr.ecr.us-east-1.amazonaws.com/project-k/payment:1.0.0"
}

variable "mongodb_image" {
  default = "392401698561.dkr.ecr.us-east-1.amazonaws.com/project-k/mongodb:1.0.0"
}
variable "redis_image" {
  default = "392401698561.dkr.ecr.us-east-1.amazonaws.com/project-k/redis:1.0.0"
}
variable "mysql_image" {
  default = "392401698561.dkr.ecr.us-east-1.amazonaws.com/project-k/mysql:1.0.0"
}
variable "rabbitmq_image" {
  default = "392401698561.dkr.ecr.us-east-1.amazonaws.com/project-k/rabbitmq:1.0.0"
}