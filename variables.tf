variable "assign_public_ip" {
  type    = bool
  default = false
}

variable "container_port" {
  type = number
}

variable "name" {
  type = string
}

variable "log_retention_in_days" {
  type    = number
  default = 365
}

variable "secret_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

# ALB.

variable "create_alb_security_group_rules" {
  type = bool
}

variable "alb_security_group_id" {
  type    = string
  default = null
}

variable "target_group_arn" {
  type    = string
  default = null
}

# Default parameters.

variable "default_autoscaling_min" {
  type    = number
  default = 1
}

variable "default_autoscaling_max" {
  type    = number
  default = 1
}

variable "default_autoscaling_target_cpu" {
  type    = number
  default = 50
}

variable "default_cpu" {
  type    = number
  default = 256
}

variable "default_memory" {
  type    = number
  default = 512
}

variable "default_image" {
  type    = string
  default = "docker.io/larsks/thttpd:latest"
}

# ECR repository.

variable "create_ecr_repository" {
  type    = bool
  default = false
}

# ECS cluster.

variable "create_ecs_cluster" {
  type = bool
}

variable "ecs_cluster_arn" {
  type    = bool
  default = null
}

# ECS security group.

variable "create_ecs_security_group" {
  type = bool
}

variable "ecs_security_group_ids" {
  type    = list(string)
  default = null
}

variable "ecs_security_group_egress" {
  type    = bool
  default = true
}

# ECS task role.

variable "create_ecs_task_role" {
  type = bool
}

variable "ecs_task_role_arn" {
  type    = string
  default = null
}
