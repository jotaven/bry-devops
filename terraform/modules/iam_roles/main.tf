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
      "route53:ListHostedZonesByName"
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