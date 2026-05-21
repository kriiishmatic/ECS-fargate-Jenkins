# ############################################
# ############ FRONTEND ALB ##################
# ############################################

# resource "aws_security_group_rule" "frontend_alb_https" {

#   type = "ingress"

#   security_group_id = local.frontend_alb_sg_id

#   cidr_blocks = ["0.0.0.0/0"]

#   from_port = 443
#   to_port   = 443

#   protocol = "tcp"
# }

# resource "aws_security_group_rule" "frontend_alb_http" {

#   type = "ingress"

#   security_group_id = local.frontend_alb_sg_id

#   cidr_blocks = ["0.0.0.0/0"]

#   from_port = 80
#   to_port   = 80

#   protocol = "tcp"
# }


# ############################################
# ################ FRONTEND ##################
# ############################################

# resource "aws_security_group_rule" "frontend_from_alb" {

#   type = "ingress"

#   security_group_id = local.frontend_sg_id

#   source_security_group_id = local.frontend_alb_sg_id

#   from_port = 8080
#   to_port   = 8080

#   protocol = "tcp"
# }

# resource "aws_security_group_rule" "frontend_from_bastion" {

#   type = "ingress"

#   security_group_id = local.frontend_sg_id

#   source_security_group_id = local.bastion_sg_id

#   from_port = 8080
#   to_port   = 8080

#   protocol = "tcp"
# }


# ############################################
# ############### BACKEND ALB ################
# ############################################

# resource "aws_security_group_rule" "backend_alb_from_frontend" {

#   type = "ingress"

#   security_group_id = local.backend_alb_sg_id

#   source_security_group_id = local.frontend_sg_id

#   from_port = 80
#   to_port   = 80

#   protocol = "tcp"
# }

# resource "aws_security_group_rule" "backend_alb_from_cart" {

#   type = "ingress"

#   security_group_id = local.backend_alb_sg_id

#   source_security_group_id = local.cart_sg_id

#   from_port = 80
#   to_port   = 80

#   protocol = "tcp"
# }

# resource "aws_security_group_rule" "backend_alb_from_shipping" {

#   type = "ingress"

#   security_group_id = local.backend_alb_sg_id

#   source_security_group_id = local.shipping_sg_id

#   from_port = 80
#   to_port   = 80

#   protocol = "tcp"
# }

# resource "aws_security_group_rule" "backend_alb_from_payment" {

#   type = "ingress"

#   security_group_id = local.backend_alb_sg_id

#   source_security_group_id = local.payment_sg_id

#   from_port = 80
#   to_port   = 80

#   protocol = "tcp"
# }

# resource "aws_security_group_rule" "backend_alb_from_bastion" {

#   type = "ingress"

#   security_group_id = local.backend_alb_sg_id

#   source_security_group_id = local.bastion_sg_id

#   from_port = 80
#   to_port   = 80

#   protocol = "tcp"
# }


# ############################################
# ############### CATALOGUE ##################
# ############################################

# resource "aws_security_group_rule" "catalogue_from_backend_alb" {

#   type = "ingress"

#   security_group_id = local.catalogue_sg_id

#   source_security_group_id = local.backend_alb_sg_id

#   from_port = 8080
#   to_port   = 8080

#   protocol = "tcp"
# }

# resource "aws_security_group_rule" "catalogue_from_bastion" {

#   type = "ingress"

#   security_group_id = local.catalogue_sg_id

#   source_security_group_id = local.bastion_sg_id

#   from_port = 8080
#   to_port   = 8080

#   protocol = "tcp"
# }


# ############################################
# ################## USER ####################
# ############################################

# resource "aws_security_group_rule" "user_from_backend_alb" {

#   type = "ingress"

#   security_group_id = local.user_sg_id

#   source_security_group_id = local.backend_alb_sg_id

#   from_port = 8080
#   to_port   = 8080

#   protocol = "tcp"
# }

# resource "aws_security_group_rule" "user_from_bastion" {

#   type = "ingress"

#   security_group_id = local.user_sg_id

#   source_security_group_id = local.bastion_sg_id

#   from_port = 8080
#   to_port   = 8080

#   protocol = "tcp"
# }


# ############################################
# ################## CART ####################
# ############################################

# resource "aws_security_group_rule" "cart_from_backend_alb" {

#   type = "ingress"

#   security_group_id = local.cart_sg_id

#   source_security_group_id = local.backend_alb_sg_id

#   from_port = 8080
#   to_port   = 8080

#   protocol = "tcp"
# }

# resource "aws_security_group_rule" "cart_from_bastion" {

#   type = "ingress"

#   security_group_id = local.cart_sg_id

#   source_security_group_id = local.bastion_sg_id

#   from_port = 8080
#   to_port   = 8080

#   protocol = "tcp"
# }


# ############################################
# ################ SHIPPING ##################
# ############################################

# resource "aws_security_group_rule" "shipping_from_backend_alb" {

#   type = "ingress"

#   security_group_id = local.shipping_sg_id

#   source_security_group_id = local.backend_alb_sg_id

#   from_port = 8080
#   to_port   = 8080

#   protocol = "tcp"
# }

# resource "aws_security_group_rule" "shipping_from_bastion" {

#   type = "ingress"

#   security_group_id = local.shipping_sg_id

#   source_security_group_id = local.bastion_sg_id

#   from_port = 8080
#   to_port   = 8080

#   protocol = "tcp"
# }


# ############################################
# ################ PAYMENT ###################
# ############################################

# resource "aws_security_group_rule" "payment_from_backend_alb" {

#   type = "ingress"

#   security_group_id = local.payment_sg_id

#   source_security_group_id = local.backend_alb_sg_id

#   from_port = 8080
#   to_port   = 8080

#   protocol = "tcp"
# }

# resource "aws_security_group_rule" "payment_from_bastion" {

#   type = "ingress"

#   security_group_id = local.payment_sg_id

#   source_security_group_id = local.bastion_sg_id

#   from_port = 8080
#   to_port   = 8080

#   protocol = "tcp"
# }


# ############################################
# ################ MONGODB ###################
# ############################################

# resource "aws_security_group_rule" "mongodb_from_catalogue" {

#   type = "ingress"

#   security_group_id = local.mongodb_sg_id

#   source_security_group_id = local.catalogue_sg_id

#   from_port = 27017
#   to_port   = 27017

#   protocol = "tcp"
# }

# resource "aws_security_group_rule" "mongodb_from_user" {

#   type = "ingress"

#   security_group_id = local.mongodb_sg_id

#   source_security_group_id = local.user_sg_id

#   from_port = 27017
#   to_port   = 27017

#   protocol = "tcp"
# }

# resource "aws_security_group_rule" "mongodb_from_bastion" {

#   type = "ingress"

#   security_group_id = local.mongodb_sg_id

#   source_security_group_id = local.bastion_sg_id

#   from_port = 27017
#   to_port   = 27017

#   protocol = "tcp"
# }


# ############################################
# ################## REDIS ###################
# ############################################

# resource "aws_security_group_rule" "redis_from_user" {

#   type = "ingress"

#   security_group_id = local.redis_sg_id

#   source_security_group_id = local.user_sg_id

#   from_port = 6379
#   to_port   = 6379

#   protocol = "tcp"
# }

# resource "aws_security_group_rule" "redis_from_cart" {

#   type = "ingress"

#   security_group_id = local.redis_sg_id

#   source_security_group_id = local.cart_sg_id

#   from_port = 6379
#   to_port   = 6379

#   protocol = "tcp"
# }

# resource "aws_security_group_rule" "redis_from_bastion" {

#   type = "ingress"

#   security_group_id = local.redis_sg_id

#   source_security_group_id = local.bastion_sg_id

#   from_port = 6379
#   to_port   = 6379

#   protocol = "tcp"
# }


# ############################################
# ################## MYSQL ###################
# ############################################

# resource "aws_security_group_rule" "mysql_from_shipping" {

#   type = "ingress"

#   security_group_id = local.mysql_sg_id

#   source_security_group_id = local.shipping_sg_id

#   from_port = 3306
#   to_port   = 3306

#   protocol = "tcp"
# }

# resource "aws_security_group_rule" "mysql_from_bastion" {

#   type = "ingress"

#   security_group_id = local.mysql_sg_id

#   source_security_group_id = local.bastion_sg_id

#   from_port = 3306
#   to_port   = 3306

#   protocol = "tcp"
# }


# ############################################
# ################ RABBITMQ ##################
# ############################################

# resource "aws_security_group_rule" "rabbitmq_from_payment" {

#   type = "ingress"

#   security_group_id = local.rabbitmq_sg_id

#   source_security_group_id = local.payment_sg_id

#   from_port = 5672
#   to_port   = 5672

#   protocol = "tcp"
# }

# resource "aws_security_group_rule" "rabbitmq_from_bastion" {

#   type = "ingress"

#   security_group_id = local.rabbitmq_sg_id

#   source_security_group_id = local.bastion_sg_id

#   from_port = 5672
#   to_port   = 5672

#   protocol = "tcp"
# }

# resource "aws_security_group_rule" "rabbitmq_management_from_bastion" {

#   type = "ingress"

#   security_group_id = local.rabbitmq_sg_id

#   source_security_group_id = local.bastion_sg_id

#   from_port = 15672
#   to_port   = 15672

#   protocol = "tcp"
# }


# ############################################
# ################ BASTION ###################
# ############################################

# resource "aws_security_group_rule" "bastion_from_laptop" {

#   type = "ingress"

#   security_group_id = local.bastion_sg_id

#   cidr_blocks = ["YOUR_PUBLIC_IP/32"]

#   from_port = 22
#   to_port   = 22

#   protocol = "tcp"
# }



############################################
############ FRONTEND ALB ##################
############################################

resource "aws_security_group_rule" "frontend_alb_https" {

  type = "ingress"

  security_group_id = local.frontend_alb_sg_id

  cidr_blocks = ["0.0.0.0/0"]

  from_port = 443
  to_port   = 443

  protocol = "tcp"
}

resource "aws_security_group_rule" "frontend_alb_http" {

  type = "ingress"

  security_group_id = local.frontend_alb_sg_id

  cidr_blocks = ["0.0.0.0/0"]

  from_port = 80
  to_port   = 80

  protocol = "tcp"
}


############################################
################ FRONTEND ##################
############################################

resource "aws_security_group_rule" "frontend_from_alb" {

  type = "ingress"

  security_group_id = local.frontend_sg_id

  source_security_group_id = local.frontend_alb_sg_id

  from_port = 8080
  to_port   = 8080

  protocol = "tcp"
}

resource "aws_security_group_rule" "frontend_from_bastion" {

  type = "ingress"

  security_group_id = local.frontend_sg_id

  source_security_group_id = local.bastion_sg_id

  from_port = 8080
  to_port   = 8080

  protocol = "tcp"
}


############################################
############### CATALOGUE ##################
############################################

resource "aws_security_group_rule" "catalogue_from_frontend" {

  type = "ingress"

  security_group_id = local.catalogue_sg_id

  source_security_group_id = local.frontend_sg_id

  from_port = 8080
  to_port   = 8080

  protocol = "tcp"
}

resource "aws_security_group_rule" "catalogue_from_bastion" {

  type = "ingress"

  security_group_id = local.catalogue_sg_id

  source_security_group_id = local.bastion_sg_id

  from_port = 8080
  to_port   = 8080

  protocol = "tcp"
}


############################################
################## USER ####################
############################################

resource "aws_security_group_rule" "user_from_frontend" {

  type = "ingress"

  security_group_id = local.user_sg_id

  source_security_group_id = local.frontend_sg_id

  from_port = 8080
  to_port   = 8080

  protocol = "tcp"
}

resource "aws_security_group_rule" "user_from_bastion" {

  type = "ingress"

  security_group_id = local.user_sg_id

  source_security_group_id = local.bastion_sg_id

  from_port = 8080
  to_port   = 8080

  protocol = "tcp"
}


############################################
################## CART ####################
############################################

resource "aws_security_group_rule" "cart_from_frontend" {

  type = "ingress"

  security_group_id = local.cart_sg_id

  source_security_group_id = local.frontend_sg_id

  from_port = 8080
  to_port   = 8080

  protocol = "tcp"
}

resource "aws_security_group_rule" "cart_from_bastion" {

  type = "ingress"

  security_group_id = local.cart_sg_id

  source_security_group_id = local.bastion_sg_id

  from_port = 8080
  to_port   = 8080

  protocol = "tcp"
}


############################################
################ SHIPPING ##################
############################################

resource "aws_security_group_rule" "shipping_from_frontend" {

  type = "ingress"

  security_group_id = local.shipping_sg_id

  source_security_group_id = local.frontend_sg_id

  from_port = 8080
  to_port   = 8080

  protocol = "tcp"
}

resource "aws_security_group_rule" "shipping_from_bastion" {

  type = "ingress"

  security_group_id = local.shipping_sg_id

  source_security_group_id = local.bastion_sg_id

  from_port = 8080
  to_port   = 8080

  protocol = "tcp"
}


############################################
################ PAYMENT ###################
############################################

resource "aws_security_group_rule" "payment_from_frontend" {

  type = "ingress"

  security_group_id = local.payment_sg_id

  source_security_group_id = local.frontend_sg_id

  from_port = 8080
  to_port   = 8080

  protocol = "tcp"
}

resource "aws_security_group_rule" "payment_from_bastion" {

  type = "ingress"

  security_group_id = local.payment_sg_id

  source_security_group_id = local.bastion_sg_id

  from_port = 8080
  to_port   = 8080

  protocol = "tcp"
}


############################################
################ MONGODB ###################
############################################

resource "aws_security_group_rule" "mongodb_from_catalogue" {

  type = "ingress"

  security_group_id = local.mongodb_sg_id

  source_security_group_id = local.catalogue_sg_id

  from_port = 27017
  to_port   = 27017

  protocol = "tcp"
}

resource "aws_security_group_rule" "mongodb_from_user" {

  type = "ingress"

  security_group_id = local.mongodb_sg_id

  source_security_group_id = local.user_sg_id

  from_port = 27017
  to_port   = 27017

  protocol = "tcp"
}

resource "aws_security_group_rule" "mongodb_from_bastion" {

  type = "ingress"

  security_group_id = local.mongodb_sg_id

  source_security_group_id = local.bastion_sg_id

  from_port = 27017
  to_port   = 27017

  protocol = "tcp"
}


############################################
################## REDIS ###################
############################################

resource "aws_security_group_rule" "redis_from_user" {

  type = "ingress"

  security_group_id = local.redis_sg_id

  source_security_group_id = local.user_sg_id

  from_port = 6379
  to_port   = 6379

  protocol = "tcp"
}

resource "aws_security_group_rule" "redis_from_cart" {

  type = "ingress"

  security_group_id = local.redis_sg_id

  source_security_group_id = local.cart_sg_id

  from_port = 6379
  to_port   = 6379

  protocol = "tcp"
}

resource "aws_security_group_rule" "redis_from_bastion" {

  type = "ingress"

  security_group_id = local.redis_sg_id

  source_security_group_id = local.bastion_sg_id

  from_port = 6379
  to_port   = 6379

  protocol = "tcp"
}


############################################
################## MYSQL ###################
############################################

resource "aws_security_group_rule" "mysql_from_shipping" {

  type = "ingress"

  security_group_id = local.mysql_sg_id

  source_security_group_id = local.shipping_sg_id

  from_port = 3306
  to_port   = 3306

  protocol = "tcp"
}

resource "aws_security_group_rule" "mysql_from_bastion" {

  type = "ingress"

  security_group_id = local.mysql_sg_id

  source_security_group_id = local.bastion_sg_id

  from_port = 3306
  to_port   = 3306

  protocol = "tcp"
}


############################################
################ RABBITMQ ##################
############################################

resource "aws_security_group_rule" "rabbitmq_from_payment" {

  type = "ingress"

  security_group_id = local.rabbitmq_sg_id

  source_security_group_id = local.payment_sg_id

  from_port = 5672
  to_port   = 5672

  protocol = "tcp"
}

resource "aws_security_group_rule" "rabbitmq_from_bastion" {

  type = "ingress"

  security_group_id = local.rabbitmq_sg_id

  source_security_group_id = local.bastion_sg_id

  from_port = 5672
  to_port   = 5672

  protocol = "tcp"
}

resource "aws_security_group_rule" "rabbitmq_management_from_bastion" {

  type = "ingress"

  security_group_id = local.rabbitmq_sg_id

  source_security_group_id = local.bastion_sg_id

  from_port = 15672
  to_port   = 15672

  protocol = "tcp"
}


############################################
################ BASTION ###################
############################################

resource "aws_security_group_rule" "bastion_from_laptop" {

  type = "ingress"

  security_group_id = local.bastion_sg_id

  cidr_blocks = ["YOUR_PUBLIC_IP/32"]

  from_port = 22
  to_port   = 22

  protocol = "tcp"
}