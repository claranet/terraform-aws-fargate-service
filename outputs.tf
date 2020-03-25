output "ecr_repository_url" {
  value = local.ecr_repository_url
}

output "ecs_cluster_arn" {
  value = local.ecs_cluster_arn
}

output "ecs_cluster_name" {
  value = local.ecs_cluster_name
}

output "ecs_security_group_ids" {
  value = local.ecs_security_group_ids
}

output "ecs_task_role_arn" {
  value = local.ecs_task_role_arn
}
