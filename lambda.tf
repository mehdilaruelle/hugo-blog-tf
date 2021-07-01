locals {
  lambda_name = "redirect"
}
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/file/${local.lambda_name}.js"
  output_path = "${path.module}/file/${local.lambda_name}.zip"
}

resource "aws_iam_role" "redirect" {
  name = "lambda_redirect_cloudfront"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "lambda.amazonaws.com",
          "edgelambda.amazonaws.com"
        ]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.redirect.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "redirect" {
  provider = aws.aws_cloudfront

  filename      = "${path.module}/file/${local.lambda_name}.zip"
  function_name = local.lambda_name
  role          = aws_iam_role.redirect.arn
  handler       = "${local.lambda_name}.handler"
  description   = "Standard Redirects for CloudFront"
  publish       = true

  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "nodejs10.x"
}

resource "aws_cloudwatch_log_group" "redirect" {
  provider          = aws.aws_cloudfront
  name              = "/aws/lambda/${local.lambda_name}"
  retention_in_days = 7
}
