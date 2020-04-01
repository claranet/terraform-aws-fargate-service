# terraform-aws-fargate-service

Terraform module for creating a Fargate service that can be updated with a Lambda function call.

This module is not ready yet.

## Todo

* Use GitHub Actions to run tests
* Consider option to create in the module:
   * ALB
   * IAM user for calling Lambda func
   * VPC
* Consider supporting SSM parameters so the use of secrets is optional
   * Save $1 per month per service

## Design

* Requires a [Secret](https://aws.amazon.com/secrets-manager/) to be created and managed separately.
   * This stores the container image to use, auto scaling settings, and other variables that will be passed into the container as single JSON string environment variable.
* Uses the default [Rolling Update](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-type-ecs.html) ECS deployment type to deploy new images.
* Terraform creates a CloudFormation stack to manage the ECS task definition, service, and some ancillary resources.
   * This includes a Lambda function for updating the stack. Invoke it, passing in a container image, and it will update the CloudFormation stack, which will deploy the new image. The deployment is complete when the CloudFormation stack update has finished.
* A separate CI/CD system is responsible for building and pushing a new image somewhere, calling the Lambda function to start deploying it, and waiting for the CloudFormation stack update to finish.
   * The CI/CD system requires only minimal IAM permissions to deploy new images: push to ECR if using it, invoke the Lambda function, and describe the CloudFormation stack.
   * These steps are relatively simple, using Docker and AWS CLI commands.
