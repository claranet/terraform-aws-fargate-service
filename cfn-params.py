"""
This Lambda function is used as a Custom Resource by CloudFormation.
It returns dynamic parameters for the CloudFormation Stack to use.

"""

import json

import boto3

import cfnresponse

ecs_client = boto3.client("ecs")
secrets_client = boto3.client("secretsmanager")


def handler(event, context):
    """
    Returns dynamic parameters for the CloudFormation Stack to use.

    """

    status = cfnresponse.FAILED
    physical_resource_id = None
    response_data = {}
    try:

        # Start with the default parameters.
        response_data.update(event["ResourceProperties"]["DefaultParams"])

        # Then override with any values from the secret.
        secret = secrets_client.get_secret_value(
            SecretId=event["ResourceProperties"]["SecretArn"],
            VersionId=event["ResourceProperties"]["SecretVersionId"],
        )
        secret_values = json.loads(secret["SecretString"])
        response_data.update(secret_values)

        # Set the log stream prefix based on the image version or tag.
        if ":" in response_data["IMAGE"]:
            response_data["LOG_STREAM_PREFIX"] = response_data["IMAGE"].split(":")[-1]
        else:
            response_data["LOG_STREAM_PREFIX"] = response_data["IMAGE"].split("/")[-1]

        # Use the existing desired count when updating an existing service,
        # because this value is managed by auto scaling. Otherwise,
        # start new services with the auto scaling minimum.
        if event["RequestType"] == "Update":
            response_data["AUTOSCALING_DESIRED"] = get_desired_count(
                cluster_name=event["ResourceProperties"]["ClusterName"],
                service_name=event["ResourceProperties"]["ServiceName"],
            )
        else:
            response_data["AUTOSCALING_DESIRED"] = response_data["AUTOSCALING_MIN"]

        status = cfnresponse.SUCCESS

    finally:
        cfnresponse.send(event, context, status, response_data, physical_resource_id)


def get_desired_count(cluster_name, service_name):
    """
    Gets the current desired count of the specified ECS Service.

    """

    response = ecs_client.describe_services(
        cluster=cluster_name, services=[service_name],
    )

    for service in response["services"]:
        return service["desiredCount"]

    raise Exception(
        f"desiredCount not found for cluster: {cluster_name} service: {service_name}"
    )
