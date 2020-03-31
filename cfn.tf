locals {
  default_params = {
    AUTOSCALING_MAX        = var.default_autoscaling_max
    AUTOSCALING_MIN        = var.default_autoscaling_min
    AUTOSCALING_TARGET_CPU = var.default_autoscaling_target_cpu
    CPU                    = var.default_cpu
    IMAGE                  = var.default_image
    MEMORY                 = var.default_memory
  }
}

resource "aws_cloudformation_stack" "this" {
  name         = var.name
  capabilities = ["CAPABILITY_IAM"]

  template_body = templatefile("${path.module}/cfn.yml.tpl", {
    assign_public_ip     = var.assign_public_ip
    cluster_arn          = local.ecs_cluster_arn
    cluster_name         = local.ecs_cluster_name
    container_port       = var.container_port
    default_params       = local.default_params
    execution_role_arn   = aws_iam_role.ecs_execution.arn
    log_group_name       = aws_cloudwatch_log_group.this.name
    name                 = var.name
    params_function_code = file("${path.module}/cfn-params.py")
    secret_arn           = data.aws_secretsmanager_secret_version.this.arn
    security_group_ids   = local.ecs_security_group_ids
    subnet_ids           = var.subnet_ids
    target_group_arn     = var.target_group_arn
    task_role_arn        = local.ecs_task_role_arn
    update_function_code = file("${path.module}/cfn-update.py")
  })

  parameters = {
    SecretVersionId = data.aws_secretsmanager_secret_version.this.version_id
  }
}
