locals {
  bucket_name = var.bucket_name
  dns_name    = var.dns_name
  origin_name = "s3-cloudfront-hugo"
}

resource "aws_acm_certificate" "hugo" {
  provider          = aws.aws_cloudfront # CloudFront uses certificates from US-EAST-1 region only
  domain_name       = local.dns_name
  validation_method = "DNS"
}

data "aws_route53_zone" "hugo" {
  name         = local.dns_name
  private_zone = false
}

resource "aws_route53_record" "hugo" {
  for_each = {
    for dvo in aws_acm_certificate.hugo.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.hugo.zone_id
}

resource "aws_acm_certificate_validation" "hugo" {
  provider                = aws.aws_cloudfront # CloudFront uses certificates from US-EAST-1 region only
  certificate_arn         = aws_acm_certificate.hugo.arn
  validation_record_fqdns = [for record in aws_route53_record.hugo : record.fqdn]
}

resource "aws_cloudfront_origin_access_control" "hugo" {
  name                              = local.origin_name
  description                       = "Origin Access Control for S3 bucket Hugo."
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

data "aws_iam_policy_document" "s3_bucket_policy" {
  statement {
    sid = "1"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::${local.bucket_name}/*",
    ]
    condition {
      test     = "StringLike"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.s3_distribution.arn]
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

resource "aws_s3_bucket_acl" "hugo" {
  bucket = aws_s3_bucket.hugo.id
  acl    = "private"
}

resource "aws_cloudfront_function" "redirect" {
  name    = "redirect"
  runtime = "cloudfront-js-1.0"
  comment = "Redirect users from cloudfront to s3 real object name."
  code    = file("${path.module}/redirect.js")
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.hugo.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.hugo.id
    origin_id                = local.origin_name
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

    target_origin_id = local.origin_name

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
    acm_certificate_arn      = aws_acm_certificate.hugo.arn
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
  zone_id = data.aws_route53_zone.hugo.zone_id
  name    = local.dns_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}
