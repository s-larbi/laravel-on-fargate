data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_iam_role" "role" {
  assume_role_policy    = data.aws_iam_policy_document.policy.json
  force_detach_policies = true
}

resource "aws_iam_role_policy_attachment" "attachment_one" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_role_policy_attachment" "attachment_two" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_user" "ci_pipeline" {
  name = terraform.workspace == "default" ? "ci_pipeline" : join("-", ["ci_pipeline", terraform.workspace])
  path = "/"
}

resource "aws_iam_access_key" "ci_pipeline" {
  user = aws_iam_user.ci_pipeline.name
}

resource "aws_iam_policy" "ci_pipeline" {
  path   = "/"
  policy = data.aws_iam_policy_document.ci_pipeline.json
}

resource "aws_iam_user_policy_attachment" "test-attach" {
  user       = aws_iam_user.ci_pipeline.name
  policy_arn = aws_iam_policy.ci_pipeline.arn
}

data "aws_iam_policy_document" "policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"
      identifiers = [
        "ec2.amazonaws.com",
        "ecs-tasks.amazonaws.com"
      ]
    }
  }
}

data "aws_iam_policy_document" "ci_pipeline" {
  statement {
    sid       = "AllowECRPush"
    resources = ["*"]
    actions = [
      "ecr:*"
    ]
  }

  statement {
    sid       = "AllowECSDeploy"
    resources = ["*"]
    actions = [
      "ecs:DescribeTaskDefinition",
      "ecs:RegisterTaskDefinition",
      "ecs:UpdateService"
    ]
  }

  statement {
    sid       = "IAMPassRole"
    resources = [aws_iam_role.role.arn]
    actions = [
      "iam:PassRole"
    ]
  }
}