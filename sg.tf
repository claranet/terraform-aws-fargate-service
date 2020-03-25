resource "aws_security_group" "ecs" {
  count  = var.create_ecs_security_group ? 1 : 0
  name   = var.name
  vpc_id = var.vpc_id
}

locals {
  ecs_security_group_ids = var.create_ecs_security_group ? aws_security_group.ecs.*.id : var.ecs_security_group_ids
}

# Allow egress from ECS.

resource "aws_security_group_rule" "ecs_egress" {
  count             = var.create_ecs_security_group && var.ecs_security_group_egress ? 1 : 0
  security_group_id = aws_security_group.ecs[0].id
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

# Allow network traffic from the ALB to ECS.

resource "aws_security_group_rule" "alb_to_ecs" {
  count                    = var.create_ecs_security_group && var.create_alb_security_group_rules ? 1 : 0
  security_group_id        = var.alb_security_group_id
  type                     = "egress"
  from_port                = var.container_port
  to_port                  = var.container_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs[0].id
}

resource "aws_security_group_rule" "ecs_from_alb" {
  count                    = var.create_ecs_security_group && var.create_alb_security_group_rules ? 1 : 0
  security_group_id        = aws_security_group.ecs[0].id
  type                     = "ingress"
  from_port                = var.container_port
  to_port                  = var.container_port
  protocol                 = "tcp"
  source_security_group_id = var.alb_security_group_id
}
