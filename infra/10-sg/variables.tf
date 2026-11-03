variable "project_name" {
    default = "project-k"
}

variable "environment" {
    default = "dev"
}



variable "sg_names" {

  default = [

    # =========================
    # Load Balancers
    # =========================

    "frontend_alb",

    # optional internal ALB
    "backend_alb",

    # =========================
    # ECS Application Services
    # =========================

    "frontend",

    "catalogue",
    "user",
    "cart",
    "shipping",
    "payment",

    # =========================
    # Databases / Middleware
    # =========================

    "mongodb",
    "redis",
    "mysql",
    "rabbitmq",

    # =========================
    # Management / Access
    # =========================

    "bastion"

  ]
}