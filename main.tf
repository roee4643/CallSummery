provider "aws" {
  region = "eu-west-1"
}

########################
# S3 Bucket
########################

resource "aws_s3_bucket" "Summery-call" {
  bucket = "roeibucket4643-test"
}

resource "aws_s3_bucket_object" "calls_folder" {
  bucket  = aws_s3_bucket.Summery-call.id
  key     = "calls/"
  content = ""
}

########################
# IAM Role for Lambda
########################

resource "aws_iam_role" "LambdaTranscribeRole" {
  name = "LambdaTranscribeRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Attach permissions
resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.LambdaTranscribeRole.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "transcribe_access" {
  role       = aws_iam_role.LambdaTranscribeRole.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonTranscribeFullAccess"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_access" {
  role       = aws_iam_role.LambdaTranscribeRole.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}

########################
# Lambda Function
########################

resource "aws_lambda_function" "TranscribeLambda" {
  function_name = "TranscribeLambda"
  role          = aws_iam_role.LambdaTranscribeRole.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"

  filename         = "/home/roei/CallSummery/lambda/lambda_function.zip"
  source_code_hash = filebase64sha256("/home/roei/CallSummery/lambda/lambda_function.zip")

  depends_on = [
    aws_iam_role_policy_attachment.s3_access,
    aws_iam_role_policy_attachment.transcribe_access,
    aws_iam_role_policy_attachment.cloudwatch_access
  ]
}

########################
# Lambda Permission
########################

resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.TranscribeLambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.Summery-call.arn
}

########################
# S3 Event Notification Trigger
########################

resource "aws_s3_bucket_notification" "trigger_lambda" {
  bucket = aws_s3_bucket.Summery-call.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.TranscribeLambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "calls/"
  }

  depends_on = [aws_lambda_permission.allow_s3_invoke]
}

