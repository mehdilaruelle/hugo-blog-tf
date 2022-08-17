locals {
  bucket_name = var.bucket_name
  dns_name    = var.dns_name
}

data "aws_acm_certificate" "acm_cert" {
  domain   = local.dns_name
  provider = aws.aws_cloudfront
  //CloudFront uses certificates from US-EAST-1 region only
  statuses = [
    "ISSUED",
  ]
}

data "aws_route53_zone" "domain_name" {
  name         = local.dns_name
  private_zone = false
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "oai_hugo"
}

data "aws_iam_policy_document" "s3_bucket_policy" {
  statement {
    sid = "1"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::${local.bucket_name}/*",
    ]

    principals {
      type = "AWS"

      identifiers = [
        aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn,
      ]
    }
  }
}

resource "aws_s3_bucket" "hugo" {
  bucket        = local.bucket_name
  force_destroy = false
}

resource "aws_s3_bucket_policy" "hugo" {
  bucket = aws_s3_bucket.hugo.id
  policy = data.aws_iam_policy_document.s3_bucket_policy.json
}

resource "aws_s3_bucket_acl" "example_bucket_acl" {
  bucket = aws_s3_bucket.hugo.id
  acl    = "private"
}

resource "aws_s3_bucket_website_configuration" "hugo" {
  bucket = aws_s3_bucket.hugo.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }

  routing_rule {
    condition {
      key_prefix_equals = "/"
    }
    redirect {
      replace_key_with = "index.html"
      host_name        = local.dns_name
    }
  }
}

resource "aws_cloudfront_function" "redirect" {
  name    = "redirect"
  runtime = "cloudfront-js-1.0"
  comment = "Redirect users from cloudfront to s3 real object name."
  code    = file("${path.module}/redirect.js")
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.hugo.bucket_domain_name
    origin_id   = "s3-cloudfront"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  aliases = [local.dns_name]

  default_cache_behavior {
    allowed_methods = [
      "GET",
      "HEAD",
    ]

    cached_methods = [
      "GET",
      "HEAD",
    ]

    target_origin_id = "s3-cloudfront"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.redirect.arn
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
  }

  price_class = var.cloudfront_price_class

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = data.aws_acm_certificate.acm_cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  custom_error_response {
    error_code            = 403
    response_code         = 200
    error_caching_min_ttl = 0
    response_page_path    = "/"
  }

  wait_for_deployment = false
}

resource "aws_route53_record" "route53_record" {
  zone_id = data.aws_route53_zone.domain_name.zone_id
  name    = local.dns_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}
