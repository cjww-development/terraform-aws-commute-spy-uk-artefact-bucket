provider "aws" {
  region = var.region
}

provider "aws" {
  alias  = "bucket_access"
  region = var.region

  assume_role {
    role_arn = var.trust_bucket_access_arn
  }
}

data "aws_iam_policy_document" "cross_account_access" {
  statement {
    sid    = "AllowCrossAccountAccessToArtefacts"
    effect = "Allow"

    actions = [
      "s3:GetBucketLocation",
      "s3:GetObjects*",
      "s3:ListBucket"
    ]

    resources = [
      "arn:aws:s3:::${var.bucket_name}",
      "arn:aws:s3:::${var.bucket_name}/*"
    ]
  }
}

data "aws_iam_policy_document" "trust" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type        = "AWS"
      identifiers = var.read_only_account_arns
    }
  }
}

resource "aws_iam_role" "cross_account_role" {
  name               = "AccessS3Artefacts"
  assume_role_policy = data.aws_iam_policy_document.trust.json
}

resource "aws_iam_role_policy" "allow_artefacts" {
  name   = "AllowCrossAccountAccessToArtefacts"
  role   = aws_iam_role.cross_account_role.id
  policy = data.aws_iam_policy_document.cross_account_access.json
}

data "aws_iam_policy_document" "artefact_bucket_policy" {
  statement {
    sid    = "AllowCrossAccountAccess"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = var.read_only_account_arns
    }

    actions = [
      "s3:GetBucketLocation",
      "s3:GetObjects*",
      "s3:ListBucket"
    ]

    resources = [
      "arn:aws:s3:::${var.bucket_name}",
      "arn:aws:s3:::${var.bucket_name}/*"
    ]
  }

  statement {
    sid = "DenyNonSecureTransport"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:*"
    ]

    resources = [
      "arn:aws:s3:::${var.bucket_name}",
      "arn:aws:s3:::${var.bucket_name}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = [false]
    }
  }
}

resource "aws_s3_bucket" "artefact_bucket" {
  bucket = var.bucket_name
  acl    = "private"
  policy = data.aws_iam_policy_document.artefact_bucket_policy.json

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  force_destroy = var.force_destroy
}

resource "aws_s3_bucket_public_access_block" "artefact_bucket" {
  bucket = aws_s3_bucket.artefact_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
