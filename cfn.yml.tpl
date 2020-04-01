# Note that this file is a Terraform template which generates
# a CloudFormation YAML template. A dollar-brace will be rendered
# by Terraform. A dollar-dollar-brace is escaped by Terraform and
# ends up as a dollar-brace to be parsed by CloudFormation.

Parameters:
  SecretVersionId:
    Description: "The version of ${secret_arn} to use"
    Type: String

Resources:

  # Create a custom resource Lambda function which returns
  # dynamic variables mostly from Secrets Manager.

  ParamsFunctionRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: "2012-10-17"
        Statement:
        - Effect: Allow
          Principal:
            Service:
            - lambda.amazonaws.com
          Action:
          - sts:AssumeRole
      Policies:
      - PolicyName: Logs
        PolicyDocument:
          Version: "2012-10-17"
          Statement:
          - Effect: Allow
            Action:
            - logs:CreateLogStream
            - logs:PutLogEvents
            Resource: !Sub "arn:aws:logs:$${AWS::Region}:$${AWS::AccountId}:log-group:/aws/lambda/*:*"
          - Effect: Allow
            Action:
            - logs:CreateLogGroup
            Resource: !Sub "arn:aws:logs:$${AWS::Region}:$${AWS::AccountId}:*"
      - PolicyName: Secrets
        PolicyDocument:
          Version: "2012-10-17"
          Statement:
          - Effect: Allow
            Action:
            - secretsmanager:GetSecretValue
            Resource: "${secret_arn}"
      - PolicyName: ECS
        PolicyDocument:
          Version: "2012-10-17"
          Statement:
          - Effect: Allow
            Action:
            - ecs:DescribeServices
            Resource: "*"

  ParamsFunction:
    Type: AWS::Lambda::Function
    Properties:
      Code:
        ZipFile: ${jsonencode(params_function_code)}
      Description: !Sub "Deployment helper for $${AWS::StackId}"
      FunctionName: !Sub "$${AWS::StackName}-params"
      Handler: index.handler
      MemorySize: 128
      Role: !GetAtt ParamsFunctionRole.Arn
      Runtime: python3.7
      Timeout: 30

  Params:
    Type: Custom::Params
    Properties:
      ClusterName: "${cluster_name}"
      DefaultParams: ${jsonencode(default_params)}
      SecretArn: "${secret_arn}"
      SecretVersionId: !Ref SecretVersionId
      ServiceName: "${name}"
      ServiceToken: !GetAtt ParamsFunction.Arn

  # Create an ECS Task Definition, Service and Auto Scaling resources
  # to run the application container.

  TaskDefinition:
    Type: AWS::ECS::TaskDefinition
    Properties:
      Cpu: !GetAtt Params.CPU
      ExecutionRoleArn: "${execution_role_arn}"
      Family: "${name}"
      Memory: !GetAtt Params.MEMORY
      NetworkMode: awsvpc
      RequiresCompatibilities:
      - FARGATE
      TaskRoleArn: "${task_role_arn}"
      ContainerDefinitions:
      - Environment:
        - Name: AWS_REGION
          Value: !Ref AWS::Region
        - Name: SECRET_VERSION_ID
          Value: !Ref SecretVersionId
        Essential: true
        Image: !GetAtt Params.IMAGE
        LogConfiguration:
          LogDriver: awslogs
          Options:
            awslogs-group: "${log_group_name}"
            awslogs-region: !Ref AWS::Region
            awslogs-stream-prefix: !GetAtt Params.LOG_STREAM_PREFIX
        Name: "${name}"
        PortMappings:
          - ContainerPort: !GetAtt Params.CONTAINER_PORT
            HostPort: !GetAtt Params.CONTAINER_PORT
            Protocol: tcp
        Secrets:
        - Name: SECRETS_JSON
          ValueFrom: "${secret_arn}"

  Service:
    Type: AWS::ECS::Service
    Properties:
      Cluster: "${cluster_arn}"
      DesiredCount: !GetAtt Params.AUTOSCALING_DESIRED
      LaunchType: FARGATE
%{ if target_group_arn != null ~}
      LoadBalancers:
        - ContainerName: "${name}"
          ContainerPort: !GetAtt Params.CONTAINER_PORT
          TargetGroupArn: "${target_group_arn}"
%{ endif ~}
      NetworkConfiguration:
        AwsvpcConfiguration:
          AssignPublicIp: "%{ if assign_public_ip }ENABLED%{ else }DISABLED%{ endif }"
          SecurityGroups: ${jsonencode(security_group_ids)}
          Subnets: ${jsonencode(subnet_ids)}
      TaskDefinition: !Ref TaskDefinition
      ServiceName: "${name}"

  ScalableTarget:
    Type: AWS::ApplicationAutoScaling::ScalableTarget
    Properties: 
      MinCapacity: !GetAtt Params.AUTOSCALING_MIN
      MaxCapacity: !GetAtt Params.AUTOSCALING_MAX
      ResourceId: !Sub "service/${cluster_name}/$${Service.Name}"
      RoleARN: !Sub "arn:aws:iam::$${AWS::AccountId}:role/aws-service-role/ecs.application-autoscaling.amazonaws.com/AWSServiceRoleForApplicationAutoScaling_ECSService"
      ScalableDimension: ecs:service:DesiredCount
      ServiceNamespace: ecs

  ScalingPolicy:
    Type: AWS::ApplicationAutoScaling::ScalingPolicy
    Properties: 
      PolicyName: "${name}"
      PolicyType: TargetTrackingScaling
      ScalingTargetId: !Ref ScalableTarget
      TargetTrackingScalingPolicyConfiguration:
        PredefinedMetricSpecification: 
          PredefinedMetricType: ECSServiceAverageCPUUtilization
        ScaleInCooldown: 0 # no need because there is draining on the load balancer
        ScaleOutCooldown: 60
        TargetValue: !GetAtt Params.AUTOSCALING_TARGET_CPU

  # Create a Lambda Function which can be used to update this stack.

  UpdateFunctionRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: "2012-10-17"
        Statement:
        - Effect: Allow
          Principal:
            Service:
            - lambda.amazonaws.com
          Action:
          - sts:AssumeRole
      Policies:
      - PolicyName: Logs
        PolicyDocument:
          Version: "2012-10-17"
          Statement:
          - Effect: Allow
            Action:
            - logs:CreateLogStream
            - logs:PutLogEvents
            Resource: !Sub "arn:aws:logs:$${AWS::Region}:$${AWS::AccountId}:log-group:/aws/lambda/*:*"
          - Effect: Allow
            Action:
            - logs:CreateLogGroup
            Resource: !Sub "arn:aws:logs:$${AWS::Region}:$${AWS::AccountId}:*"
      - PolicyName: UpdateSecret
        PolicyDocument:
          Version: "2012-10-17"
          Statement:
          - Effect: Allow
            Action:
            - secretsmanager:GetSecretValue
            - secretsmanager:UpdateSecret
            Resource: "${secret_arn}"
      - PolicyName: UpdateCloudFormationStack
        PolicyDocument:
          Version: "2012-10-17"
          Statement:
          - Effect: Allow
            Action:
            - cloudformation:UpdateStack
            - ecs:*
            - lambda:*
            - iam:PassRole
            Resource:
            - !Ref AWS::StackId
            - !Sub "arn:aws:ecs:$${AWS::Region}:$${AWS::AccountId}:service/${cluster_name}/$${Service.Name}"
            - !Sub "arn:aws:lambda:$${AWS::Region}:$${AWS::AccountId}:function:$${AWS::StackName}-*"
            - !Sub "arn:aws:iam::$${AWS::AccountId}:role/aws-service-role/ecs.application-autoscaling.amazonaws.com/AWSServiceRoleForApplicationAutoScaling_ECSService"
            - "${execution_role_arn}"
            - "${task_role_arn}"
          - Effect: Allow
            Action:
              - application-autoscaling:Describe*
              - application-autoscaling:PutScalingPolicy
              - application-autoscaling:RegisterScalableTarget
              - ecs:DeregisterTaskDefinition
              - ecs:RegisterTaskDefinition
            Resource: "*"

  UpdateFunction:
    Type: AWS::Lambda::Function
    Properties:
      Code:
        ZipFile: ${jsonencode(update_function_code)}
      Description: !Sub "Updates $${AWS::StackId}"
      Environment:
        Variables:
          SECRET_ARN: "${secret_arn}"
          STACK_NAME: !Ref AWS::StackName
      FunctionName: !Sub "$${AWS::StackName}-update"
      Handler: index.handler
      MemorySize: 128
      Role: !GetAtt UpdateFunctionRole.Arn
      Runtime: python3.7
      Timeout: 30
