locals {
  # Enable the AWS OIDC authentication with Github only if var.github_repositories & var.github_org is set
  enable_aws_github_oidc = anytrue([length(var.github_repositories) == 0, var.github_org == ""]) ? 0 : 1
}
data "aws_iam_policy_document" "assume_role" {
  count = local.enable_aws_github_oidc

  statement {
    sid = "1"

    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [one(aws_iam_openid_connect_provider.github).arn]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"

      values = [
        for repo in var.github_repositories : "repo:${var.github_org}/${repo}:*"
      ]
    }

  }
}

resource "aws_iam_openid_connect_provider" "github" {
  count = local.enable_aws_github_oidc

  url             = var.oidc_url
  client_id_list  = var.client_id_list
  thumbprint_list = var.thumbprint_list

}

resource "aws_iam_role" "github" {
  count = local.enable_aws_github_oidc

  name                 = var.iam_role_name
  assume_role_policy   = one(data.aws_iam_policy_document.assume_role).json
  max_session_duration = var.max_session_duration
}

resource "aws_iam_role_policy_attachment" "policy" {
  count = local.enable_aws_github_oidc

  role       = one(aws_iam_role.github).id
  policy_arn = one(aws_iam_policy.github_hugo).arn
}

resource "aws_iam_policy" "github_hugo" {
  count = local.enable_aws_github_oidc

  name = var.iam_role_name

  policy = one(data.aws_iam_policy_document.hugo).json
}

data "aws_iam_policy_document" "hugo" {
  count = local.enable_aws_github_oidc

  statement {
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.hugo.arn
    ]
  }
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]
    resources = [
      "${aws_s3_bucket.hugo.arn}/*"
    ]
  }
  statement {
    actions = [
      "cloudfront:CreateInvalidation"
    ]
    resources = [
      aws_cloudfront_distribution.s3_distribution.arn
    ]
  }
}
