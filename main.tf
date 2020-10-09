provider "aws" {
  version = "2.33.0"

  region = var.aws_region
}


data "template_file" "buildspec" {
  template = "${file("data/buildspec.yml")}"
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
    },
    {
      "Effect": "Allow",
      "Action": [
          "codecommit:AssociateApprovalRuleTemplateWithRepository",
          "codecommit:BatchAssociateApprovalRuleTemplateWithRepositories",
          "codecommit:BatchDisassociateApprovalRuleTemplateFromRepositories",
          "codecommit:BatchGet*",
          "codecommit:BatchDescribe*",
          "codecommit:Create*",
          "codecommit:DeleteBranch",
          "codecommit:DeleteFile",
          "codecommit:Describe*",
          "codecommit:DisassociateApprovalRuleTemplateFromRepository",
          "codecommit:EvaluatePullRequestApprovalRules",
          "codecommit:Get*",
          "codecommit:List*",
          "codecommit:Merge*",
          "codecommit:OverridePullRequestApprovalRules",
          "codecommit:Put*",
          "codecommit:Post*",
          "codecommit:TagResource",
          "codecommit:Test*",
          "codecommit:UntagResource",
          "codecommit:Update*",
          "codecommit:GitPull",
          "codecommit:GitPush"
      ],
      "Resource": "*"
  },
  {
      "Sid": "CloudWatchEventsCodeCommitRulesAccess",
      "Effect": "Allow",
      "Action": [
          "events:DeleteRule",
          "events:DescribeRule",
          "events:DisableRule",
          "events:EnableRule",
          "events:PutRule",
          "events:PutTargets",
          "events:RemoveTargets",
          "events:ListTargetsByRule"
      ],
      "Resource": "arn:aws:events:*:*:rule/codecommit*"
  },
  {
      "Sid": "SNSTopicAndSubscriptionAccess",
      "Effect": "Allow",
      "Action": [
          "sns:Subscribe",
          "sns:Unsubscribe"
      ],
      "Resource": "arn:aws:sns:*:*:codecommit*"
  },
  {
      "Sid": "SNSTopicAndSubscriptionReadAccess",
      "Effect": "Allow",
      "Action": [
          "sns:ListTopics",
          "sns:ListSubscriptionsByTopic",
          "sns:GetTopicAttributes"
      ],
      "Resource": "*"
  },
  {
      "Sid": "LambdaReadOnlyListAccess",
      "Effect": "Allow",
      "Action": [
          "lambda:ListFunctions"
      ],
      "Resource": "*"
  },
  {
      "Sid": "IAMReadOnlyListAccess",
      "Effect": "Allow",
      "Action": [
          "iam:ListUsers"
      ],
      "Resource": "*"
  },
  {
      "Sid": "IAMReadOnlyConsoleAccess",
      "Effect": "Allow",
      "Action": [
          "iam:ListAccessKeys",
          "iam:ListSSHPublicKeys",
          "iam:ListServiceSpecificCredentials"
      ],
      "Resource": "arn:aws:iam::*:user/${aws:username}"
  },
  {
      "Sid": "IAMUserSSHKeys",
      "Effect": "Allow",
      "Action": [
          "iam:DeleteSSHPublicKey",
          "iam:GetSSHPublicKey",
          "iam:ListSSHPublicKeys",
          "iam:UpdateSSHPublicKey",
          "iam:UploadSSHPublicKey"
      ],
      "Resource": "arn:aws:iam::*:user/${aws:username}"
  },
  {
      "Sid": "IAMSelfManageServiceSpecificCredentials",
      "Effect": "Allow",
      "Action": [
          "iam:CreateServiceSpecificCredential",
          "iam:UpdateServiceSpecificCredential",
          "iam:DeleteServiceSpecificCredential",
          "iam:ResetServiceSpecificCredential"
      ],
      "Resource": "arn:aws:iam::*:user/${aws:username}"
  },
  {
      "Sid": "CodeStarNotificationsReadWriteAccess",
      "Effect": "Allow",
      "Action": [
          "codestar-notifications:CreateNotificationRule",
          "codestar-notifications:DescribeNotificationRule",
          "codestar-notifications:UpdateNotificationRule",
          "codestar-notifications:Subscribe",
          "codestar-notifications:Unsubscribe"
      ],
      "Resource": "*",
      "Condition": {
          "StringLike": {
              "codestar-notifications:NotificationsForResource": "arn:aws:codecommit:*"
          }
      }
  },
  {
      "Sid": "CodeStarNotificationsListAccess",
      "Effect": "Allow",
      "Action": [
          "codestar-notifications:ListNotificationRules",
          "codestar-notifications:ListTargets",
          "codestar-notifications:ListTagsforResource",
          "codestar-notifications:ListEventTypes"
      ],
      "Resource": "*"
  },
  {
      "Sid": "AmazonCodeGuruReviewerFullAccess",
      "Effect": "Allow",
      "Action": [
          "codeguru-reviewer:AssociateRepository",
          "codeguru-reviewer:DescribeRepositoryAssociation",
          "codeguru-reviewer:ListRepositoryAssociations",
          "codeguru-reviewer:DisassociateRepository",
          "codeguru-reviewer:DescribeCodeReview",
          "codeguru-reviewer:ListCodeReviews"
      ],
      "Resource": "*"
  },
  {
      "Sid": "AmazonCodeGuruReviewerSLRCreation",
      "Action": "iam:CreateServiceLinkedRole",
      "Effect": "Allow",
      "Resource": "arn:aws:iam::*:role/aws-service-role/codeguru-reviewer.amazonaws.com/AWSServiceRoleForAmazonCodeGuruReviewer",
      "Condition": {
          "StringLike": {
              "iam:AWSServiceName": "codeguru-reviewer.amazonaws.com"
          }
      }
  },
  {
      "Sid": "CloudWatchEventsManagedRules",
      "Effect": "Allow",
      "Action": [
          "events:PutRule",
          "events:PutTargets",
          "events:DeleteRule",
          "events:RemoveTargets"
      ],
      "Resource": "*",
      "Condition": {
          "StringEquals": {
              "events:ManagedBy": "codeguru-reviewer.amazonaws.com"
          }
      }
  },
  {
      "Sid": "CodeStarNotificationsChatbotAccess",
      "Effect": "Allow",
      "Action": [
          "chatbot:DescribeSlackChannelConfigurations"
      ],
      "Resource": "*"
  },
  {
      "Sid": "CodeStarConnectionsReadOnlyAccess",
      "Effect": "Allow",
      "Action": [
          "codestar-connections:ListConnections",
          "codestar-connections:GetConnection"
      ],
      "Resource": "arn:aws:codestar-connections:*:*:connection/*"
  }
]
}
EOF
}
