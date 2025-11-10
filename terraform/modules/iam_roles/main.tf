data "aws_iam_policy_document" "externaldns_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:external-dns"]
    }
  }
}

data "aws_iam_policy_document" "externaldns_policy" {
  statement {
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets",
      "route53:ListHostedZonesByName",
      "route53:ListHostedZones"
    ]
    resources = ["*"] 
  }
}

resource "aws_iam_role" "externaldns" {
  name               = "jotinha-externaldns-role"
  assume_role_policy = data.aws_iam_policy_document.externaldns_assume_role_policy.json
}

resource "aws_iam_role_policy" "externaldns" {
  name   = "jotinha-externaldns-policy"
  role   = aws_iam_role.externaldns.id
  policy = data.aws_iam_policy_document.externaldns_policy.json
}

data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${var.account_id}:oidc-provider/token.actions.githubusercontent.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:jotaven/bry-devops:*"] 
    }
  }
}

resource "aws_iam_role" "github_actions_infra" {
  name = "GitHubActions-Infra-Admin"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json
  tags = {
    "Purpose" = "CICD-Infra-Admin"
  }
}

resource "aws_iam_role_policy_attachment" "github_actions_infra_admin" {
  role       = aws_iam_role.github_actions_infra.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess" 
}