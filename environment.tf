terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# EC2 instance
resource "aws_instance" "DB" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.allow_all.id]

  tags = {
    Name = "example-instance"
  }
}

resource "aws_security_group" "DSG" {
  name        = "deployment-instance"
  description = "security group for AWS EC2 instances"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "deployment-instance"
  }
}

#6.Creating mysql database:
resource "aws_db_instance" "mysqlDB" {
  identifier             = "nodejs-db"
  allocated_storage      = 20
  storage_type           = "gp2"
  db_name                = "mysqldb"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.micro"
  username               = "admin"
  password               = "mysql123"
  parameter_group_name   = "default.mysql5.7"
  availability_zone      = "us-east-2c"
  skip_final_snapshot    = true
  vpc_security_group_ids      = [aws_security_group.allow_all.id]
  tags = {
    Name = "nodejs-db"
  }
}

output "rds_endpoint" {
  value = aws_db_instance.mydb.endpoint
}

# S3 bucket
resource "aws_s3_bucket" "parkerbucket123" {
  bucket = "parkerbucket123"

  tags = {
    Name        = "parkerbucket123"
    Environment = "Dev"
  }
}

#IAM
resource "aws_iam_role" "cd" {
  name = "codedeploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "codedeploy.amazonaws.com",
        },
      },
    ],
  })
}

resource "aws_iam_role" "codepipeline" {
  name = "codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "codepipeline.amazonaws.com",
        },
      },
    ],
  })
}

resource "aws_iam_role" "ec2_role" {
  name = "ec2"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# CodeDeploy Application
resource "aws_codedeploy_app" "example" {
  name = "example-app"
}

resource "aws_codedeploy_deployment_group" "example" {
  app_name              = aws_codedeploy_app.example.name
  deployment_group_name = "example-group"
  service_role_arn      = aws_iam_role.codedeploy.arn

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout    = "STOP_DEPLOYMENT"
      wait_time_in_minutes = 60
    }

    green_fleet_provisioning_option {
      action = "DISCOVER_EXISTING"
    }

    terminate_blue_instances_on_deployment_success {
      action = "KEEP_ALIVE"
    }
  }
}
# CodePipeline
resource "aws_codepipeline" "example_pipeline" {
  name     = "example-pipeline"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.parkerbucket123.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "SourceAction"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner  = "your-github-username"
        Repo   = "your-repo-name"
        Branch = "your-branch"
        OAuthToken = "your-github-personal-access-token"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "DeployAction"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToEC2"
      version         = "1"
      input_artifacts = ["source_output"]

      configuration = {
        ApplicationName          = aws_codedeploy_app.example.name
        DeploymentGroupName      = aws_codedeploy_app.example.name
      }
    }
  }
}

v
