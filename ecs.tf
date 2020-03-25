resource "aws_ecs_cluster" "this" {
  count = var.create_ecs_cluster ? 1 : 0
  name  = var.name
}

data "aws_arn" "ecs" {
  count = var.create_ecs_cluster ? 0 : 1
  arn   = var.ecs_cluster_arn
}

locals {
  ecs_cluster_arn  = element(flatten(coalescelist(aws_ecs_cluster.this.*.arn, data.aws_arn.ecs.*.arn)), 0)
  ecs_cluster_name = element(flatten(coalescelist(aws_ecs_cluster.this.*.name, data.aws_arn.ecs.*.resource)), 0)
}
