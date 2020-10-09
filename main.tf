provider "aws" {
  version = "2.33.0"

  region = var.aws_region
}


data "template_file" "buildspec" {
  template = "${file("data/buildspec.yml")}"
}

data "template_file" "pipeline_policy" {
  template = "${file("data/pipeline_role_policy.json")}"
}

resource "aws_codebuild_project" "codebuild_project" {
  name = var.codebuild_project_name

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:1.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "SOME_KEY1"
      value = "SOME_VALUE1"
    }
  }

  service_role = aws_iam_role.codebuild_role.arn

  source {
    type            = "CODEPIPELINE"
    buildspec       = data.template_file.buildspec.rendered
  }


}

resource "aws_codepipeline" "codepipeline" {
  name     = var.pipeline_name
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"

  }

  stage {
    name = "CodeCommit"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"

      output_artifacts = ["source_output"]

      configuration  = {
        RepositoryName       = "test_code_commit"
        BranchName     = "master"
        PollForSourceChanges = false
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = var.codebuild_project_name
      }
    }
  }
}

resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = var.pipeline_s3_bucket
  acl    = "private"
}


resource "aws_iam_role" "codebuild_role" {
  name = "example"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}




resource "aws_iam_role" "codepipeline_role" {
  name = var.pipeline_role_name

  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "codepipeline.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
EOF
}

resource "aws_iam_role_policy" "pipeline_policy" {
  name = "pipeline_policy"
  role = aws_iam_role.codepipeline_role.id

  policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "Stmt1602222091816",
        "Action": "s3:*",
        "Effect": "Allow",
        "Resource": "${aws_s3_bucket.codepipeline_bucket.arn}/*"
      }
    ]
  }
EOF
}

resource "aws_iam_role_policy_attachment" "codepipeline_role-attach" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeCommitFullAccess"
}
