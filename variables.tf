variable "bucket_name" {
  description = "The S3 bucket name to store the HUGO website."
}

variable "dns_name" {
  description = "The DNS name to use for your HUGO website."
}


variable "cloudfront_price_class" {
  description = "The price class to use for CloudFront distribution."
  default     = "PriceClass_100"
}

###### GITHUB ACTION VARIABLES ######
#      Optionnal configuration      #
# To use this configuration, set    #
# at least github_repositories and  #
# github_org variables              #
#####################################
variable "oidc_url" {
  description = "The URL of the identity provider. Corresponds to the iss claim."
  type        = string
  default     = "https://token.actions.githubusercontent.com"
}

variable "client_id_list" {
  description = "A list of client IDs (also known as audiences)."
  type        = list(string)
  default     = ["sts.amazonaws.com"]
}

variable "thumbprint_list" {
  description = "A list of server certificate thumbprints for the OpenID Connect (OIDC) identity provider's server certificate(s)."
  type        = list(string)
  default     = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

variable "github_org" {
  description = "GitHub organisation name."
  type        = string
  default     = ""
}

variable "github_repositories" {
  description = "List of GitHub repository names."
  type        = list(string)
  default     = []
}

variable "iam_role_name" {
  description = "Friendly name of the role. If omitted, Terraform will assign a random, unique name."
  type        = string
  default     = "GitHubOIDCRole"
}

variable "max_session_duration" {
  default     = 3600 #1hour (min accepted by AWS)
  description = "Maximum session duration in seconds."
  type        = number
}
