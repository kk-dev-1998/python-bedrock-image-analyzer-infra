########################################
# modules/github-oidc
#
# Identity provider and IAM role for GitHub Actions to access AWS
# via OIDC (OpenID Connect)
########################################

data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = [
    data.tls_certificate.github.certificates[0].sha1_fingerprint,
  ]
}

# IAM role that GitHub Actions can assume.
data "aws_iam_policy_document" "github_actions_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # AWS requires GitHub Actions OIDC trust policies to be scoped via either the
    # sub or job_workflow_ref claim, so we keep sub as a wildcard here and do the
    # actual scoping with the more robust repository claim below.
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:*"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:repository"
      values   = ["${var.github_org}/${var.github_repo}"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "${var.project_name}-github-actions-terraform"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume.json
}

# Permissions for the resources Terraform operates on during plan/apply.
data "aws_iam_policy_document" "github_actions_permissions" {
  statement {
    sid    = "TerraformStateAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::${var.tfstate_bucket_name}",
      "arn:aws:s3:::${var.tfstate_bucket_name}/*",
    ]
  }

  statement {
    sid    = "ECR"
    effect = "Allow"
    actions = [
      "ecr:*",
    ]
    resources = ["arn:aws:ecr:${var.aws_region}:${var.account_id}:repository/${var.project_name}"]
  }

  statement {
    sid    = "ECRAuth"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
    ]
    resources = ["*"] # "*" is required because GetAuthorizationToken doesn't support resource-level permissions
  }

  statement {
    sid    = "Lambda"
    effect = "Allow"
    actions = [
      "lambda:*",
    ]
    resources = ["arn:aws:lambda:${var.aws_region}:${var.account_id}:function:${var.project_name}-*"]
  }

  statement {
    sid    = "IAMForLambdaRole"
    effect = "Allow"
    actions = [
      "iam:GetRole",
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:PutRolePolicy",
      "iam:GetRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:PassRole",
      "iam:TagRole",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
    ]
    resources = ["arn:aws:iam::${var.account_id}:role/${var.project_name}-*"]
  }

  statement {
    sid    = "ApiGateway"
    effect = "Allow"
    actions = [
      "apigateway:*",
    ]
    resources = ["arn:aws:apigateway:${var.aws_region}::/apis*"]
  }

  statement {
    sid    = "S3ImageBucket"
    effect = "Allow"
    actions = [
      "s3:*",
    ]
    resources = [
      "arn:aws:s3:::${var.project_name}-images-*",
      "arn:aws:s3:::${var.project_name}-images-*/*",
    ]
  }

  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:*",
    ]
    resources = [
      "arn:aws:logs:${var.aws_region}:${var.account_id}:log-group:/aws/lambda/${var.project_name}-*",
      "arn:aws:logs:${var.aws_region}:${var.account_id}:log-group:/aws/apigateway/${var.project_name}-*",
    ]
  }

  statement {
    sid    = "STSIdentity"
    effect = "Allow"
    actions = [
      "sts:GetCallerIdentity",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "github_actions_permissions" {
  name   = "${var.project_name}-github-actions-terraform-policy"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.github_actions_permissions.json
}
