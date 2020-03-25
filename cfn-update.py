"""
This Lambda function is used to update a CloudFormation Stack.
This is used by CI/CD Pipelines to deploy new images.

"""

import json
from os import environ
from uuid import uuid1

import boto3

SECRET_ARN = environ["SECRET_ARN"]
STACK_NAME = environ["STACK_NAME"]


cfn_client = boto3.client("cloudformation")
secrets_client = boto3.client("secretsmanager")


def handler(event, context):
    """
    Updates the secret with the specified image,
    then updates the ECS Service using the latest secret values.

    """

    # This function must be called with an image tag to deploy.
    image = event["IMAGE"]

    # Update the secret with the image tag to deploy,
    # and then get the new secret version for the parameters.
    secret_values = get_secret_values()
    secret_values["IMAGE"] = image
    secret_version_id = update_secret_values(secret_values)

    # Update the stack to deploy the changes.
    response = update_stack(SecretVersionId=secret_version_id,)
    print(response)
    return response


def get_secret_values():
    """
    Returns the current secret values.

    """

    secret = secrets_client.get_secret_value(SecretId=SECRET_ARN)
    return json.loads(secret["SecretString"])


def update_secret_values(values):
    """
    Updates the secret values and returns the new version id.

    """

    response = secrets_client.update_secret(
        SecretId=SECRET_ARN,
        ClientRequestToken=str(uuid1()),
        SecretString=json.dumps(values),
    )
    return response["VersionId"]


def update_stack(**kwargs):
    """
    Updates a stack with the specified parameters.

    """

    parameters = []
    for key, value in kwargs.items():
        parameters.append({"ParameterKey": key, "ParameterValue": value})

    response = cfn_client.update_stack(
        StackName=STACK_NAME,
        Capabilities=["CAPABILITY_IAM"],
        UsePreviousTemplate=True,
        Parameters=parameters,
    )

    return response
