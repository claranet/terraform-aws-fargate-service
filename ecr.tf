resource "aws_ecr_repository" "this" {
  count = var.create_ecr_repository ? 1 : 0
  name  = var.name
}

data "aws_arn" "ecr" {
  count = var.create_ecr_repository ? 0 : 1
  arn   = var.ecr_repository_arn
}

data "aws_ecr_repository" "this" {
  count = var.create_ecr_repository ? 0 : 1
  name  = local.ecr_repository_name
}

locals {
  ecr_repository_name = element(flatten(coalescelist(aws_ecr_repository.this.*.name, data.aws_arn.ecr.*.resource)), 0)
  ecr_repository_url  = element(flatten(coalescelist(aws_ecr_repository.this.*.repository_url, data.aws_ecr_repository.this.*.repository_url)), 0)
}
