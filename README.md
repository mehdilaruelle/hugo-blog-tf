# Deploy your Hugo website on AWS with Terraform 

This project is aim to deploy the infrastructure needed by [Hugo](https://gohugo.io/) on [AWS](https://aws.amazon.com/).
This infrastructure force the usage of HTTPS with a specific domain name.

You can read [the dedicated blog post on this on my blog](https://mehdilaruelle.com/posts/2022/08/deploy-your-hugo-site-on-aws-with-terraform/).

## Prerequisites

You need to a domain name (for HTTPS).

### Setting up the domain name

Our Terraform does not create the hosted zone (because it depends on where your domain name is located).
> The hosted zone is not required. It is possible to not use Amazon Route 53 for [configuring Amazon CloudFront](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/CNAMEs.html)
and [to create the certificate](https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-request-public.html). The action will require more effort and manual action.

**TO DO**: [Create the public hosted zone on Amazon Route 53](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/migrate-dns-domain-in-use.html)

## Solution architecture

![AWS Cloudfront website static](.docs/hugo_aws_website.png)

The Terraform deploys:
- A **S3 bucket**: this S3 bucket will contain our static website.
The content thereof is private and accessible only by CloudFront via an [Origin Access Identity (OAI)](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html).
In other words, our users will have to go through Amazon CloudFront and not directly on Amazon S3 to access to our website.
- A **CloudFront distribution**: will allow us to use HTTPS on our website, to use a custom domain name, to set up a
[Content Delivery Network (CDN)](https://aws.amazon.com/cloudfront/) and
enhance security through the [AWS Shield service](https://aws.amazon.com/shield).
- A **Route 53 record**: a new Alias will be created for our CloudFront distribution
- A **CloudFront function**: is used to rewrite URL to append `index.html` to the end if not exist.  
- A **AWS Certificate Manager**: Create the public certificate on ACM in N. Virginia (us-east-1) for CloudFront distribution.

## How is it working ?

Before starting, you need to check if:
- You have created `the public hosted zone on Amazon Route 53`

If so, you can now be able to deploy your infrastructure.

### Deployment

Add a `terraform.tfvars` file with the following variables and values:
- `bucket_name` : is the s3 bucket that will be created
- `dns_name` : will be the domain name used via Route 53

> Also, create `backend.tf` file with your own Terraform backend configuration if needed.

Once the GIT repository is ready, run your commands (check your AWS credentials beforehand):
```bash
$ terraform init
$ terraform plan
$ terraform apply
```

### **OPTIONAL** - Create a role for GitHub Action

This stack can create a role for GitHub Action with the Action [configure-aws-credentials
](https://github.com/aws-actions/configure-aws-credentials#configure-aws-credentials-for-github-actions).

To use this option, you should define in your `terraform.tfvars` the following values:
- `github_org` is the GitHub Organization name where your repository `hugo blog` is hosted in GitHub.
  In our case, should be your (in my case `mehdilaruelle`).
- `blog_hugo` is a list of GitHub repositories name to allow to assume the Web Identity role.
  In our case, the name of the current repository (in my case `blog-hugo-tf`).

You can also configure some optional variable based on your need like `iam_role_name`, `client_id_list`, etc (see below to have an exhaustive list).

Then, do a `$ terraform apply` to create your role and do a `$ terraform output aws_role_arn` to get the role ARN to use
for your GitHub Action.

To learn more about it, [take a look into the blog post](https://mehdilaruelle.com/posts/2023/10/deploy-your-hugo-site-on-aws-with-terraform-v2/#setting-up-temporary-aws-credentials)

### Cleanup

To destroy this project use the following command:
```bash
$ terraform destroy
```

After that, don't forget to remove:
- the `public hosted zone` on Amazon Route 53

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~>5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.7.0 |
| <a name="provider_aws.aws_cloudfront"></a> [aws.aws\_cloudfront](#provider\_aws.aws\_cloudfront) | 5.7.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_acm_certificate.hugo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_acm_certificate_validation.hugo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation) | resource |
| [aws_cloudfront_distribution.s3_distribution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |
| [aws_cloudfront_function.redirect](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_function) | resource |
| [aws_cloudfront_origin_access_control.hugo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_control) | resource |
| [aws_iam_openid_connect_provider.github](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_policy.github_hugo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.github](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_route53_record.hugo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.route53_record](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_s3_bucket.hugo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_acl.hugo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_policy.hugo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_iam_policy_document.assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.hugo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.s3_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_route53_zone.hugo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | The S3 bucket name to store the HUGO website. | `any` | n/a | yes |
| <a name="input_client_id_list"></a> [client\_id\_list](#input\_client\_id\_list) | A list of client IDs (also known as audiences). | `list(string)` | <pre>[<br>  "sts.amazonaws.com"<br>]</pre> | no |
| <a name="input_cloudfront_price_class"></a> [cloudfront\_price\_class](#input\_cloudfront\_price\_class) | The price class to use for CloudFront distribution. | `string` | `"PriceClass_100"` | no |
| <a name="input_dns_name"></a> [dns\_name](#input\_dns\_name) | The DNS name to use for your HUGO website. | `any` | n/a | yes |
| <a name="input_github_org"></a> [github\_org](#input\_github\_org) | GitHub organisation name. | `string` | `""` | no |
| <a name="input_github_repositories"></a> [github\_repositories](#input\_github\_repositories) | List of GitHub repository names. | `list(string)` | `[]` | no |
| <a name="input_iam_role_name"></a> [iam\_role\_name](#input\_iam\_role\_name) | Friendly name of the role. If omitted, Terraform will assign a random, unique name. | `string` | `"GitHubOIDCRole"` | no |
| <a name="input_max_session_duration"></a> [max\_session\_duration](#input\_max\_session\_duration) | Maximum session duration in seconds. | `number` | `3600` | no |
| <a name="input_oidc_url"></a> [oidc\_url](#input\_oidc\_url) | The URL of the identity provider. Corresponds to the iss claim. | `string` | `"https://token.actions.githubusercontent.com"` | no |
| <a name="input_region"></a> [region](#input\_region) | The main region used by the AWS provider to deploy the solution. | `string` | `"eu-west-3"` | no |
| <a name="input_thumbprint_list"></a> [thumbprint\_list](#input\_thumbprint\_list) | A list of server certificate thumbprints for the OpenID Connect (OIDC) identity provider's server certificate(s). | `list(string)` | <pre>[<br>  "6938fd4d98bab03faadb97b34396831e3780aea1"<br>]</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_role_arn"></a> [aws\_role\_arn](#output\_aws\_role\_arn) | The AWS role ARN to use in your GitHub Actions to fetch dynamic creds from AWS. |
| <a name="output_route53_ns_records"></a> [route53\_ns\_records](#output\_route53\_ns\_records) | List of Name Server (NS) records to add to your main DNS zone (delegation). |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Contact

You see something wrong ? You want extra information or more ?

Contact me: 3exr269ch@mozmail.com
