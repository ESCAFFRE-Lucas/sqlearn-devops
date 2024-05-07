provider "aws" {
  region = var.aws_region
}

resource "aws_iam_instance_profile" "tonycava_ec2" {
  name = "ng-beanstalk-ec2-user"
  role = aws_iam_role.tonycava_ec2.name
}

resource "aws_iam_role" "tonycava_ec2" {
  name = "ng-beanstalk-ec2-role"

  assume_role_policy = jsonencode({
    "Version"   = "2012-10-17",
    "Statement" = [
      {
        "Action"    = "sts:AssumeRole",
        "Sid"       = "",
        "Effect"    = "Allow",
        "Principal" = {
          "Service" = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Beanstalk EC2 Policy
# Overriding because by default Beanstalk does not have a permission to Read ECR
resource "aws_iam_role_policy" "tonycava_ec2_policy" {
  name = "tonycava_ec2_policy_with_ECR"
  role = aws_iam_role.tonycava_ec2.id

  policy = jsonencode({
    "Version"   = "2012-10-17",
    "Statement" = [
      {
        "Action" = [
          "cloudwatch:PutMetricData",
          "ds:CreateComputer",
          "ds:DescribeDirectories",
          "ec2:DescribeInstanceStatus",
          "logs:*",
          "ssm:*",
          "ec2messages:*",
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "s3:*"
        ],
        "Effect"   = "Allow",
        "Resource" = "*"
      }
    ]
  })

}

# Beanstalk Application
resource "aws_elastic_beanstalk_application" "tonycava_application" {
  name        = var.application_name
  description = var.application_description
}

resource "aws_db_instance" "default" {
  allocated_storage         = 10
  engine                    = "mysql"
  engine_version            = "5.7"
  instance_class            = "db.t3.micro"
  username                  = var.db_username
  password                  = var.db_password
  parameter_group_name      = "default.mysql5.7"
  skip_final_snapshot       = false
  identifier                = "sqlearn-db"
  final_snapshot_identifier = replace("sqlearn-snapshot-${timestamp()}", ":", "")
  publicly_accessible       = true

  vpc_security_group_ids = [
    aws_security_group.db_sc.id
  ]

}
resource "aws_security_group" "db_sc" {
  name        = "db_security_group"
  description = "Security group for the database"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Beanstalk Environment
resource "aws_elastic_beanstalk_environment" "tonycava_application_environment" {
  name                = "${var.application_name}-${var.application_environment}"
  application         = aws_elastic_beanstalk_application.tonycava_application.name
  tier                = "WebServer"
  solution_stack_name = "64bit Amazon Linux 2023 v4.3.0 running Docker"
  version_label       = aws_elastic_beanstalk_application_version.default.name

  depends_on = [
    aws_elastic_beanstalk_application_version.default,
    aws_db_instance.default
  ]

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "application"
  }

  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "SSLCertificateArns"
    value     = var.acm_certificate_arn
  }

  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "Protocol"
    value     = "HTTPS"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DATABASE_URL"
    value     = "mysql://${var.db_username}:${var.db_password}@${aws_db_instance.default.endpoint}/${aws_db_instance.default.identifier}"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t2.micro"
  }


  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = 1
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = 2
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.tonycava_ec2.name
  }

  setting {
    name      = "RollingUpdateEnabled"
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    value     = "false"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthCheckPath"
    value     = "/"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "MatcherHTTPCode"
    value     = "200"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthCheckInterval"
    value     = "30"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthyThresholdCount"
    value     = "3"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "UnhealthyThresholdCount"
    value     = "5"
  }

}

resource "aws_elastic_beanstalk_application_version" "default" {
  name        = "v1"
  application = aws_elastic_beanstalk_application.tonycava_application.name
  description = "Application version created by Terraform"

  depends_on = [
    aws_s3_bucket.tonycava_bucket,
    aws_s3_object.docker_object,
  ]

  bucket = aws_s3_bucket.tonycava_bucket.bucket
  key    = local.s3-file_path
}
