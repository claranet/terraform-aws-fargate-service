resource "aws_ecr_repository" "this" {
  count = var.create_ecr_repository ? 1 : 0
  name  = var.name
}
