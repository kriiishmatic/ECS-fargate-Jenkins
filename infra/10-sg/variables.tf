variable "project_name" {
    default = "stackly"
}

variable "environment" {
    default = "dev"
}

# variable "sg_names" {
#     default = [
#         # databases
#         "mongodb", "redis", "mysql", "rabbitmq",
#         # backend
#         # "catalogue", "user", "cart", "shipping", "payment",
#         # frontend
#         # "frontend",
#         # bastion
#         "bastion",
#         # frontend load balancer
#         "ingress_alb",
#         # Backend ALB
#         # "backend_alb",
#         "open_vpn",
#         "eks_control_plane",
#         "eks_node"
#     ]
# }

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