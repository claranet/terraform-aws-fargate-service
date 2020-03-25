from pretf.aws import terraform_backend_s3


def pretf_blocks():
    yield terraform_backend_s3(
        bucket="terraform-aws-fargate-service",
        dynamodb_table="terraform-aws-fargate-service",
        key="terraform.tfstate",
        profile="claranetuk-thirdplaygroundRW",
        region="eu-west-1",
    )
