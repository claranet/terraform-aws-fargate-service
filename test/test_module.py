import json
from unittest.mock import ANY
from urllib.request import urlopen

from pretf import test
from pretf.aws import get_session

AWS_PROFILE = "claranetuk-thirdplaygroundRW"
AWS_REGION = "eu-west-1"

SECRET_ID = "terraform-aws-fargate-service-test"

DEFAULT_IMAGE_CONTENT = "Your web server is working"

CUSTOM_IMAGE = "docker.io/cbolt/thttpd:latest"
CUSTOM_IMAGE_CONTENT = "Index of /"


session = get_session(profile_name=AWS_PROFILE, region_name=AWS_REGION)
cfn_client = session.client("cloudformation")
lambda_client = session.client("lambda")
secrets_client = session.client("secretsmanager")


class state:
    """
    This empty class is used to share values between test functions.
    Attributes on the test class don't work because Pytest creates
    separate classes per test function.

    """


class TestModule(test.SimpleTest):
    def test_init(self):
        """
        Initialise the Terraform directory
        and destroy anything from previous tests.

        Create the secret here too. It would normally be created manually.

        """

        secret = json.dumps(
            {
                "APP_VALUE_1": "one",
                "APP_VALUE_2": "two",
                "APP_VALUE_3": "three",
                "AUTOSCALING_MIN": 1,
                "AUTOSCALING_MAX": 2,
            }
        )
        try:
            secrets_client.create_secret(
                Name=SECRET_ID, SecretString=secret,
            )
        except secrets_client.exceptions.ResourceExistsException:
            secrets_client.put_secret_value(
                SecretId=SECRET_ID, SecretString=secret,
            )

        self.pretf.init()
        self.pretf.destroy()

    def test_apply(self):
        """
        Create the Fargate service using the default image.

        """

        outputs = self.pretf.apply()
        assert outputs == {
            "cfn_stack_name": ANY,
            "lambda_function_name": ANY,
            "url": ANY,
        }
        state.cfn_stack_name = outputs["cfn_stack_name"]
        state.lambda_function_name = outputs["lambda_function_name"]
        state.url = outputs["url"]

    def test_request_default_image(self):
        """
        Test that the URL works.

        """

        with urlopen(state.url) as response:
            assert response.status == 200
            html = response.read().decode()
            assert DEFAULT_IMAGE_CONTENT in html
            assert CUSTOM_IMAGE_CONTENT not in html

    def test_deploy_custom_image(self):
        """
        Invoke the Lambda function to deploy a different image.

        """

        response = lambda_client.invoke(
            FunctionName=state.lambda_function_name,
            Payload=json.dumps({"IMAGE": CUSTOM_IMAGE}),
        )
        payload = json.load(response["Payload"])
        assert "StackId" in payload

        waiter = cfn_client.get_waiter("stack_update_complete")
        waiter.wait(StackName=state.cfn_stack_name)

    def test_request_custom_image(self):
        """
        Test that the URL works.

        """

        with urlopen(state.url) as response:
            assert response.status == 200
            html = response.read().decode()
            assert CUSTOM_IMAGE_CONTENT in html
            assert DEFAULT_IMAGE_CONTENT not in html

    @test.always
    def test_destroy(self):
        """
        Clean up afterwards.

        """

        self.pretf.destroy()

        secrets_client.delete_secret(
            SecretId=SECRET_ID, ForceDeleteWithoutRecovery=True,
        )
