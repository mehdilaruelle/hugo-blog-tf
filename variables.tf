variable "bucket_name" {
  description = "The S3 bucket name to store the HUGO website."
}

variable "dns_name" {
  description = "The DNS name to use for your HUGO website."
}


variable "cloudfront_price_class" {
  description = "The price class to use for CloudFront distribution."
  value = "PriceClass_100"
}