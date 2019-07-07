data "aws_caller_identity" "current" {}

locals {
  role_policies = {
    developer = [
      "arn:aws:iam::aws:policy/IAMReadOnlyAccess", // TODO
      "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    ]
    billing = [
      aws_iam_policy.billing_read_access.arn,
    ]
    admin = [
      "arn:aws:iam::aws:policy/AdministratorAccess",
    ]
    laravel = [
      aws_iam_policy.laravel.arn,
    ]
  }

  role_policies_flatten = flatten([
    for role in keys(local.role_policies) : [
      for policy in local.role_policies[role] : {
        role   = role
        policy = policy
      }
    ]
  ])
}

resource "aws_iam_policy" "billing_read_access" {
  name   = "BillingReadAccess"
  path   = "/"
  policy = data.aws_iam_policy_document.policy_billing_read_access.json
}

resource "aws_iam_policy" "laravel" {
  name   = "Laravel"
  path   = "/applications/"
  policy = data.aws_iam_policy_document.laravel.json
}

resource "aws_iam_role" "roles" {
  count                 = length(keys(local.role_policies))
  name                  = element(keys(local.role_policies), count.index)
  assume_role_policy    = data.aws_iam_policy_document.policy.json
  force_detach_policies = true
}

resource "aws_iam_role_policy_attachment" "attachments" {
  depends_on = [aws_iam_role.roles]

  count      = length(local.role_policies_flatten)
  role       = lookup(local.role_policies_flatten[count.index], "role")
  policy_arn = lookup(local.role_policies_flatten[count.index], "policy")
}

resource "aws_iam_user" "ci_pipeline" {
  name = "ci_pipeline"
  path = "/"
}

resource "aws_iam_access_key" "ci_pipeline" {
  user = aws_iam_user.ci_pipeline.name
}

resource "aws_iam_policy" "ci_pipeline" {
  name   = "DeployToECS"
  path   = "/"
  policy = data.aws_iam_policy_document.ci_pipeline.json
}

resource "aws_iam_user_policy_attachment" "test-attach" {
  user       = "ci_pipeline"
  policy_arn = aws_iam_policy.ci_pipeline.arn
}


# resource "aws_iam_account_password_policy" "strict" {
#   minimum_password_length        = 12
#   require_lowercase_characters   = true
#   require_numbers                = true
#   require_uppercase_characters   = true
#   require_symbols                = true
#   allow_users_to_change_password = true
# }

# data "aws_iam_policy_document" "policy_billing_full_access" {
#   statement {
#     sid       = "AllowBillingAccess"
#     actions   = ["aws-portal:*"]
#     resources = ["*"]
#   }

#   statement {
#     sid       = "DenyBillingAccountManagement"
#     actions   = ["aws-portal:*Account"]
#     effect    = "Deny"
#     resources = ["*"]
#   }
# }

data "aws_iam_policy_document" "policy_billing_read_access" {
  statement {
    sid       = "AllowBillingReadAccess"
    actions   = ["aws-portal:View*"]
    resources = ["*"]
  }

  statement {
    sid       = "DenyBillingAccountManagement"
    actions   = ["aws-portal:*Account"]
    effect    = "Deny"
    resources = ["*"]
  }
}

data "aws_region" "current" {}

data "aws_iam_policy_document" "laravel" {
  statement {
    sid       = "AllowFargateExecution"
    resources = ["*"]
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]
  }

  statement {
    sid       = "AllowCreateLogGroup"
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
  }
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
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/laravel"]
    actions = [
      "iam:PassRole"
    ]
  }
}


# resource "aws_iam_saml_provider" "gsuite" {
#   name                   = "GSuite"
#   saml_metadata_document = file("${path.module}/GoogleIDPMetadata.xml")
# }

# data "aws_iam_policy_document" "policy" {
#   statement {
#     actions = [
#       "sts:AssumeRoleWithSAML",
#     ]

#     principals {
#       type        = "Federated"
#       identifiers = [aws_iam_saml_provider.gsuite.arn]
#     }

#     condition {
#       test     = "StringEquals"
#       variable = "SAML:aud"

#       values = [
#         "https://signin.aws.amazon.com/saml",
#       ]
#     }
#   }
# }